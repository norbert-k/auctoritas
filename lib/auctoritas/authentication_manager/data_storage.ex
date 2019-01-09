defmodule Auctoritas.AuthenticationManager.DataStorage do
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
    name <> "_cachex_storage"
    |> String.to_atom()
  end

  @callback insert_data(name(), token(), any()) :: {atom(), any()}
  @spec insert_data(token(), any()) :: {atom(), any()}
  def insert_data(token, data) when is_bitstring(token) do
    Cachex.execute(@cachex_default_name, fn cache ->

      Cachex.put(cache, token, data)
      Cachex.expire(cache, token, :timer.seconds(60))
    end)
  end

  @doc """
  Insert data into storage

  Arguments:
  * Name: Name from config
  * Token: Generated token
  * Data: Any kind of data you would like to associate with token
  """
  @spec insert_data(name(), token(), any()) :: {atom(), any()}
  def insert_data(name, token, data) when is_bitstring(token) and is_bitstring(name) do
    Cachex.execute(cachex_name(name), fn cache ->

      Cachex.put(cache, token, data)
      Cachex.expire(cache, token, :timer.seconds(60))
    end)
  end

  @callback delete_token(name(), token()) :: {atom(), any()}
  @spec delete_token(token()) :: {atom(), any()}
  def delete_token(token) when is_bitstring(token) do
    Cachex.execute(@cachex_default_name, fn cache ->
      Cachex.del(cache, token)
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
    Cachex.execute(cachex_name(name), fn cache ->
      Cachex.del(cache, token)
    end)
  end

  @callback get_tokens_with_data(name(), non_neg_integer(), non_neg_integer()) :: {atom(), any()}
  @spec get_tokens_with_data(non_neg_integer(), non_neg_integer()) :: {atom(), any()}
  def get_tokens_with_data(start, amount) when is_number(start) and is_number(amount) do
    query = Cachex.Query.create(true, { :key, :value })

    case Cachex.stream(@cachex_default_name, query) do
      {:ok, data} ->
        data
        |> Enum.to_list()
        |> Enum.slice(start, amount)
        |> Enum.map(fn(token) ->
          {:ok, expires} = token_expires?(elem(token, 0))

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
  Get tokens with associated data (value and expiration)

  Arguments:
  * Name: Name from config
  * Start: Starting point in the list
  * Amount: Amount of tokens to take from list
  """
  @spec get_tokens_with_data(name(), non_neg_integer(), non_neg_integer()) :: {atom(), any()}
  def get_tokens_with_data(name, start, amount) when is_number(start) and is_number(amount) and is_bitstring(name) do
    query = Cachex.Query.create(true, { :key, :value })

    case Cachex.stream(cachex_name(name), query) do
      {:ok, data} ->
        data
        |> Enum.to_list()
        |> Enum.slice(start, amount)
        |> Enum.map(fn(token) ->
          {:ok, expires} = token_expires?(elem(token, 0))

          %{
            token: elem(token, 0),
            value: elem(token, 1),
            expiration: expires
          }
        end)
        {:ok, data}
    end
  end

  @callback get_tokens(name(), non_neg_integer(), non_neg_integer()) :: {atom(), any()}
  @spec get_tokens(non_neg_integer(), non_neg_integer()) :: {atom(), any()}
  def get_tokens(start, amount) do
    query = Cachex.Query.create(true, :key)

    case Cachex.stream(@cachex_default_name, query) do
      {:ok, data} ->
        data = data
        |> Enum.to_list()
        |> Enum.slice(start, amount)
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
    query = Cachex.Query.create(true, :key)

    case Cachex.stream(cachex_name(name), query) do
      {:ok, data} ->
        data = data
               |> Enum.to_list()
               |> Enum.slice(start, amount)
        {:ok, data}
    end
  end

  @callback get_token_data(name(), token()) :: {atom(), any()}
  @spec get_token_data(token()) :: {atom(), any()}
  def get_token_data(token) when is_bitstring(token) do
    Cachex.get(@cachex_default_name, token)
  end

  @doc """
  Get tokens data

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec get_token_data(name(), token()) :: {atom(), any()}
  def get_token_data(name, token) when is_bitstring(token) and is_bitstring(name) do
    Cachex.get(cachex_name(name), token)
  end

  @callback token_exists?(name(), token()) :: boolean()
  @spec token_exists?(token()) :: boolean()
  def token_exists?(token) when is_bitstring(token) do
    case get_token_data(token) do
      {:ok, nil} -> false
      {:ok, _token} -> true
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
    case get_token_data(token) do
      {:ok, nil} -> false
      {:ok, _token} -> true
    end
  end

  @callback token_expires?(name(), token()) :: {atom(), any()}
  @spec token_expires?(token()) :: {atom(), any()}
  def token_expires?(token) when is_bitstring(token) do
    Cachex.ttl(@cachex_default_name, token)
  end

  @doc """
  Get token expiration (countdown)

  Arguments:
  * Name: Name from config
  * Token: Generated token
  """
  @spec token_expires?(name(), token()) :: {atom(), any()}
  def token_expires?(name, token) when is_bitstring(token) and is_bitstring(name) do
    Cachex.ttl(cachex_name(name), token)
  end
end
