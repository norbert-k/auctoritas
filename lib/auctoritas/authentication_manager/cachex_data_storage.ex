defmodule Auctoritas.AuthenticationManager.CachexDataStorage do
  @behaviour Auctoritas.DataStorage

  require Logger

  @moduledoc """
  Default DataStorage implementation (based on Cachex)
  """

  alias Auctoritas.Config
  alias Auctoritas.DataStorage.Data
  alias Auctoritas.DataStorage.RefreshTokenData

  @typedoc "Authentication token"
  @type token() :: String.t()

  @typedoc "Name from config (Auctoritas supervisor name)"
  @type name() :: String.t()

  @typedoc "Token expiration in seconds"
  @type expiration() :: non_neg_integer()

  @spec start_link(data :: %Config{}) :: {:ok, list()}
  def start_link(%Config{} = config) do
    Logger.info("Created new DataStorage worker", additional: config)

    case config.token_type == :refresh_token do
      true ->
        workers = [
          %{
            id: TokenStore,
            start:
              {Cachex, :start_link,
               [
                 cachex_name(config.name),
                 []
               ]}
          },
          %{
            id: RefreshTokenStore,
            start:
              {Cachex, :start_link,
               [
                 cachex_refresh_name(config.name),
                 []
               ]}
          }
        ]

        {:ok, workers}

      false ->
        workers = [
          %{
            id: TokenStore,
            start:
              {Cachex, :start_link,
               [
                 cachex_name(config.name),
                 []
               ]}
          }
        ]

        {:ok, workers}
    end
  end

  @spec cachex_name(name :: name()) :: atom()
  defp cachex_name(name) when is_bitstring(name) do
    (name <> "_cachex_storage")
    |> String.to_atom()
  end

  @spec cachex_refresh_name(name :: name()) :: atom()
  defp cachex_refresh_name(name) when is_bitstring(name) do
    (name <> "_cachex__refresh_token_storage")
    |> String.to_atom()
  end

  @doc """
  Insert data into storage

  Arguments:
  * Name: Name from config
  * Token: Generated token
  * Data: Any kind of data you would like to associate with token
  """
  @spec insert_token(name(), expiration(), token(), map(), :regular) ::
          {:ok, token :: token(), data :: %Data{}} | {:error, error :: any()}
  def insert_token(name, expiration, token, data)
      when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Inserted data into [#{name}] cache, token:#{token}}", additional: data)

    Cachex.execute(cachex_name(name), fn cache ->
      data = Data.new(data, expiration)

      with {:ok, true} <- Cachex.put(cache, token, data),
           {:ok, true} <- Cachex.expire(cache, token, :timer.seconds(expiration)) do
        {:ok, token, data}
      else
        {:error, error} -> {:error, error}
      end
    end)
  end

  @spec insert_token(name(), expiration(), token(), token(), map()) ::
          {:ok, token :: token(), data :: %Data{}} | {:error, error :: any()}
  def insert_token(name, expiration, token, refresh_token, data)
      when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Inserted data with refresh token into [#{name}] cache, token:#{token}}", additional: data)

    Cachex.execute(cachex_name(name), fn cache ->
      data = Data.new(data, refresh_token, expiration)

      with {:ok, true} <- Cachex.put(cache, token, data),
           {:ok, true} <- Cachex.expire(cache, token, :timer.seconds(expiration)) do
        {:ok, token, data}
      else
        {:error, error} -> {:error, error}
      end
    end)
  end


  @spec insert_refresh_token(
          name(),
          expiration(),
          refresh_token :: token(),
          token :: token(),
          auth_data :: map()
        ) ::
          {:ok, refresh_token :: token(), auth_data :: %RefreshTokenData{}}
          | {:error, error :: any()}
  def insert_refresh_token(name, expiration, refresh_token, token, auth_data)
      when is_bitstring(refresh_token) and is_bitstring(name) and is_bitstring(token) do
    Logger.info("Inserted refresh token into [#{name}] cache, refresh_token:#{refresh_token}}")

    Cachex.execute(cachex_refresh_name(name), fn cache ->
      data = RefreshTokenData.new(auth_data, token, expiration)

      with {:ok, true} <- Cachex.put(cache, refresh_token, data),
           {:ok, true} <- Cachex.expire(cache, refresh_token, :timer.seconds(expiration)) do
        {:ok, refresh_token, data}
      else
        {:error, error} -> {:error, error}
      end
    end)
  end

  @doc """
  Update token data

  Arguments:
  * Name: Name from config
  * Token: Generated token
  * Data: Data to update (Map.Merge)
  """
  @spec update_token(name(), token(), map()) :: {atom(), any()}
  def update_token(name, token, new_data) when is_bitstring(name) and is_bitstring(token) do
    Logger.info("Updated data in [#{name}] cache, token:#{token}}", additional: new_data)

    Cachex.execute(cachex_name(name), fn cache ->
      case get_token_data(name, token) do
        {:ok, token_data} ->
          token_data = Data.new(token_data)
          data = Data.update_data(token_data, new_data)
          Cachex.put(cache, token, data)

        {:error, error} ->
          {:error, error}
      end
    end)
  end

  @spec update_metadata(name(), token(), map()) :: {atom(), any()}
  def update_metadata(name, token, new_metadata)
      when is_bitstring(name) and is_bitstring(token) do
    Logger.info("Updated metadata in [#{name}] cache, token:#{token}}", additional: new_metadata)

    Cachex.execute(cachex_name(name), fn cache ->
      case get_token_data(name, token) do
        {:ok, data} ->
          data = Data.update_metadata(data, new_metadata)
          Cachex.put(cache, token, data)

        {:error, error} ->
          {:error, error}
      end
    end)
  end

  @spec reset_expiration(name(), token(), expiration()) :: {atom(), any()}
  def reset_expiration(name, token, expiration) when is_bitstring(name) and is_bitstring(token) do
    Logger.info("Reseted expiration in [#{name}] cache, token:#{token}}")

    transaction =
      Cachex.transaction(cachex_name(name), [token], fn cache ->
        Cachex.expire(cache, token, :timer.seconds(expiration))
      end)

    case transaction do
      {:ok, result} -> result
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Delete token and its data

  Arguments:
  * Name: Name from config
  * Token: Token to delete
  """
  @spec delete_token(name(), token :: token()) ::
          {atom(), any()} :: {:ok, boolean()} | {:error, error :: any()}
  def delete_token(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Deleted token from [#{name}] cache, token:#{token}}")

    Cachex.execute(cachex_name(name), fn cache ->
      Cachex.del(cache, token)
    end)
  end

  @doc """
  Delete refresh token and its data

  Arguments:
  * Name: Name from config
  * Token: Refesh token to delete
  """
  @spec delete_refresh_token(name(), refresh_token :: token()) ::
          {atom(), any()} :: {:ok, boolean()} | {:error, error :: any()}
  def delete_refresh_token(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Deleted refresh token from [#{name}] cache, token:#{token}}")

    Cachex.execute(cachex_refresh_name(name), fn cache ->
      Cachex.del(cache, token)
    end)
  end

  @doc """
  Get a list of tokens

  Arguments:
  * Name: Name from config
  * Start: Starting point in the list
  * Amount: Amount of tokens to take from list
  """
  @spec get_tokens(name(), start :: non_neg_integer(), amount :: non_neg_integer()) ::
          {:ok, list(token())} | {:error, error :: any()}
  def get_tokens(name, start, amount) when is_bitstring(name) do
    Logger.info("Getting tokens from [#{name}] cache, start:#{start}, amount:#{amount}}")
    query = Cachex.Query.create(true, :key)

    case Cachex.stream(cachex_name(name), query) do
      {:ok, data} ->
        data =
          data
          |> Enum.to_list()
          |> Enum.slice(start, amount)

        {:ok, data}
    end
  end

  @doc """
  Get a list of refresh tokens

  Arguments:
  * Name: Name from config
  * Start: Starting point in the list
  * Amount: Amount of tokens to take from list
  """
  @spec get_refresh_tokens(name(), start :: non_neg_integer(), amount :: non_neg_integer()) ::
          {:ok, list(token())} | {:error, error :: any()}
  def get_refresh_tokens(name, start, amount) when is_bitstring(name) do
    Logger.info("Getting tokens from [#{name}] cache, start:#{start}, amount:#{amount}}")
    query = Cachex.Query.create(true, :key)

    case Cachex.stream(cachex_refresh_name(name), query) do
      {:ok, data} ->
        data =
          data
          |> Enum.to_list()
          |> Enum.slice(start, amount)

        {:ok, data}
    end
  end

  @doc """
  Get token data

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec get_token_data(name(), token()) :: {:ok, %Data{}} | {:error, error :: any()}
  def get_token_data(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Getting token data from [#{name}] cache, token:#{token}")

    with {:ok, token_data} <- Cachex.get(cachex_name(name), token),
         {:ok, expiration} when is_number(expiration) <- token_expires?(name, token) do
      {:ok, %Data{} = token_data |> Data.add_expiration(div(expiration, 1000))}
    else
      {:ok, nil} -> {:error, "Data not found"}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Get refresh token data

  Arguments:
  * Name: Name from config
  * Token: Generated refresh token
  """
  @spec get_refresh_token_data(name(), refresh_token :: token()) ::
          {:ok, %RefreshTokenData{}} | {:error, error :: any()}
  def get_refresh_token_data(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Getting refresh token data from [#{name}] cache, token:#{token}")

    with {:ok, refresh_token_data} <- Cachex.get(cachex_refresh_name(name), token),
         {:ok, expiration} when is_number(expiration) <- refresh_token_expires?(name, token) do
      {:ok,
       %RefreshTokenData{} =
         refresh_token_data |> RefreshTokenData.add_expiration(div(expiration, 1000))}
    else
      {:ok, nil} -> {:error, "Data not found"}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Check if token exists

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec token_exists?(name(), token()) :: boolean()
  def token_exists?(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Checking if token exists from [#{name}] cache, token:#{token}")

    case get_token_data(name, token) do
      {:ok, _data} -> true
      {:error, _error} -> false
    end
  end

  @doc """
  Get token expiration (countdown)

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec token_expires?(name(), token()) :: {:ok, expiration()} | {:error, error :: any()}
  def token_expires?(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Checking when token expires from [#{name}] cache, token:#{token}")

    case Cachex.ttl(cachex_name(name), token) do
      {:ok, expiration} -> {:ok, expiration}
      {:error, error} -> {:error, error}
    end
  end

  @spec refresh_token_expires?(name(), token()) :: {:ok, expiration()} | {:error, error :: any()}
  def refresh_token_expires?(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Checking when refresh token expires from [#{name}] cache, token:#{token}")

    case Cachex.ttl(cachex_refresh_name(name), token) do
      {:ok, expiration} -> {:ok, expiration}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Check for collisions

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec check_collision(name(), token()) :: boolean()
  def check_collision(name, token) when is_bitstring(name) and is_bitstring(token) do
    Logger.info(
      "Checking if token collides with existing token from [#{name}] cache, token:#{token}"
    )

    case get_token_data(name, token) do
      {:ok, _data} -> true
      {:error, _error} -> false
    end
  end
end
