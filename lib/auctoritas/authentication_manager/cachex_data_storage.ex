defmodule Auctoritas.AuthenticationManager.CachexDataStorage do
  @behaviour Auctoritas.DataStorage

  require Logger

  @moduledoc """
  Default DataStorage implementation (based on Cachex)
  """

  alias Auctoritas.Config
  alias Auctoritas.DataStorage.Data

  @typedoc "Authentication token"
  @type token() :: String.t()

  @typedoc "Name from config (Auctoritas supervisor name)"
  @type name() :: String.t()

  @typedoc "Token expiration in seconds"
  @type expiration() :: non_neg_integer()

  @spec start_link(data :: %Config{}) :: {:ok, map()}
  def start_link(%Config{} = config) do
    Logger.info("Created new DataStorage worker", additional: config)

    worker = %{
      id: Cachex,
      start:
        {Cachex, :start_link,
         [
           cachex_name(config.name),
           []
         ]}
    }

    {:ok, worker}
  end

  @spec cachex_name(name :: name()) :: atom()
  defp cachex_name(name) when is_bitstring(name) do
    (name <> "_cachex_storage")
    |> String.to_atom()
  end

  @doc """
  Insert data into storage

  Arguments:
  * Name: Name from config
  * Token: Generated token
  * Data: Any kind of data you would like to associate with token
  """
  @spec insert_token(name(), expiration(), token(), map()) ::
          {:ok, token(), %Data{}} | {:error, error :: any()}
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
        {:ok, token_data} ->
          token_data = Data.new(token_data)
          data = Data.update_metadata(token_data, new_metadata)
          Cachex.put(cache, token, data)

        {:error, error} ->
          {:error, error}
      end
    end)
  end

  @spec reset_expiration(name(), token(), expiration()) :: {atom(), any()}
  def reset_expiration(name, token, expiration) when is_bitstring(name) and is_bitstring(token) do
    Logger.info("Reseted expiration in [#{name}] cache, token:#{token}}")

    transaction = Cachex.transaction(cachex_name(name), [token], fn cache ->
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
  @spec delete_token(name(), token()) ::
          {atom(), any()} :: {:ok, boolean()} | {:error, error :: any()}
  def delete_token(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Deleted token from [#{name}] cache, token:#{token}}")

    Cachex.execute(cachex_name(name), fn cache ->
      Cachex.del(cache, token)
    end)
  end

  @doc """
  Get tokens with associated data (value and expiration)

  Arguments:
  * Name: Name from config
  * Start: Starting point in the list
  * Amount: Amount of tokens to take from list
  """
  @spec get_tokens_with_data(name(), non_neg_integer(), non_neg_integer()) :: {atom(), any()}
  def get_tokens_with_data(name, start, amount)
      when is_number(start) and is_number(amount) and is_bitstring(name) do
    Logger.info(
      "Getting tokens with data from [#{name}] cache, start:#{start}, amount:#{amount}}"
    )

    query = Cachex.Query.create(true, {:key, :value})

    case Cachex.stream(cachex_name(name), query) do
      {:ok, data} ->
        data
        |> Enum.to_list()
        |> Enum.slice(start, amount)
        |> Enum.map(fn token ->
          {:ok, expiration} = token_expires?(name, elem(token, 0))

          %{
            token: elem(token, 0),
            data: elem(token, 1) |> Data.add_expiration(div(expiration, 1000))
          }
        end)

        {:ok, data}
    end
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
  Get tokens data

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