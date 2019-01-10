defmodule Auctoritas.AuthenticationManager.DataStorage do
  @behaviour Auctoritas.DataStorage

  require Logger

  @moduledoc """
  Default DataStorage implementation (based on Cachex)
  """

  alias Auctoritas.Config

  @cachex_default_name :auctoritas_default_cachex_storage

  @type token() :: String.t()
  @type name() :: String.t()

  @doc """
  Start cachex with custom name
  """
  def worker(%Config{} = config) do
    Logger.info("Created new DataStorage worker", [additional: config])
    %{
      id: Cachex,
      start:
        {Cachex, :start_link,
         [
           cachex_name(config.name),
           []
         ]}
    }
  end

  @doc """
  Generate Cachex atom
  """
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
  @spec insert_token(name(), token(), map()) :: {atom(), any()}
  def insert_token(name, token, data) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Inserted data into [#{name}] cache, token:#{token}}", [additional: data])
    Cachex.execute(cachex_name(name), fn cache ->
      Cachex.put(cache, token, data)
      Cachex.expire(cache, token, :timer.seconds(60))
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
  def update_token(name, token, data) when is_bitstring(name) and is_bitstring(token) do
    Logger.info("Updated data in [#{name}] cache, token:#{token}}", [additional: data])
    Cachex.execute(cachex_name(name), fn(cache) ->
      case get_token_data(name, token) do
        {:ok, token_data} ->
        data = Map.merge(token_data, data)
        Cachex.put(cache, token, data)
        {:error, error} -> {:error, error}
      end
    end)
  end

  @doc """
  Delete token and its data

  Arguments:
  * Name: Name from config
  * Token: Token to delete
  """
  @spec delete_token(name(), token()) :: {atom(), any()}
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
    Logger.info("Getting tokens with data from [#{name}] cache, start:#{start}, amount:#{amount}}")
    query = Cachex.Query.create(true, {:key, :value})

    case Cachex.stream(cachex_name(name), query) do
      {:ok, data} ->
        data
        |> Enum.to_list()
        |> Enum.slice(start, amount)
        |> Enum.map(fn token ->
          {:ok, expires} = token_expires?(name, elem(token, 0))

          %{
            token: elem(token, 0),
            value: elem(token, 1),
            expiration: expires
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
  @spec get_tokens(name(), non_neg_integer(), non_neg_integer()) :: {atom(), any()}
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
  @spec get_token_data(name(), token()) :: {atom(), any()}
  def get_token_data(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Getting token data from [#{name}] cache, token:#{token}")
    Cachex.get(cachex_name(name), token)
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
      {:ok, nil} -> false
      {:ok, _token} -> true
    end
  end

  @doc """
  Get token expiration (countdown)

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec token_expires?(name(), token()) :: {atom(), any()}
  def token_expires?(name, token) when is_bitstring(token) and is_bitstring(name) do
    Logger.info("Checking when token expires from [#{name}] cache, token:#{token}")
    Cachex.ttl(cachex_name(name), token)
  end

  @doc """
  Check for collisions

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec check_collision(name(), token()) :: boolean()
  def check_collision(name, token) when is_bitstring(name) and is_bitstring(token) do
    Logger.info("Checking if token collides with existing token from [#{name}] cache, token:#{token}")
    case get_token_data(name, token) do
      {:ok, nil} -> false
      {:ok, data} -> true
      {:error, error} -> false
    end
  end

end
