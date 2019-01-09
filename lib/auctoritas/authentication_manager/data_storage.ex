defmodule Auctoritas.AuthenticationManager.DataStorage do

  @cachex_default_name :auctoritas_default_cache

  @type token() :: String.t()

  def worker() do
    %{
      id: Cachex,
      start:
        {Cachex, :start_link,
         [
           @cachex_default_name,
           []
         ]}
    }
  end

  @callback insert_data(token(), any()) :: {atom(), any()}
  @spec insert_data(token(), any()) :: {atom(), any()}
  def insert_data(token, data) when is_bitstring(token) do
    Cachex.execute(@cachex_default_name, fn cache ->

      Cachex.put(cache, token, data)
      Cachex.expire(cache, token, :timer.seconds(60))
    end)
  end

  @callback delete_token(token()) :: {atom(), any()}
  @spec delete_token(token()) :: {atom(), any()}
  def delete_token(token) when is_bitstring(token) do
    Cachex.execute(@cachex_default_name, fn cache ->
      Cachex.del(cache, token)
    end)
  end

  @callback get_tokens_with_data(non_neg_integer(), non_neg_integer()) :: {atom(), any()}
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

  @callback get_tokens(non_neg_integer(), non_neg_integer()) :: {atom(), any()}
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

  @callback get_token_data(token()) :: {atom(), any()}
  @spec get_token_data(token()) :: {atom(), any()}
  def get_token_data(token) when is_bitstring(token) do
    Cachex.get(@cachex_default_name, token)
  end

  @callback token_exists?(token()) :: boolean()
  @spec token_exists?(token()) :: boolean()
  def token_exists?(token) when is_bitstring(token) do
    case get_token_data(token) do
      {:ok, nil} -> false
      {:ok, _token} -> true
    end
  end

  @callback token_expires?(token()) :: {atom(), any()}
  @spec token_expires?(token()) :: {atom(), any()}
  def token_expires?(token) when is_bitstring(token) do
    Cachex.ttl(@cachex_default_name, token)
  end
end
