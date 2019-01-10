defmodule Auctoritas.AuthenticationManager.TokenManager do
  alias Auctoritas.TokenGenerator
  alias Auctoritas.AuthenticationManager.DataStorage

  @type token() :: String.t()

  @callback generate_token(any()) :: {atom(), token()}
  @spec generate_token(map()) :: {atom(), token()}
  def generate_token(_data) do
    {:ok, TokenGenerator.generate_token()}
  end

  @callback authentification_data_check(any()) :: {atom(), any()}
  @spec authentification_data_check(map()) :: {atom(), map()}
  def authentification_data_check(data) do
    case data do
      nil -> {:error, "Data is nil"}
      data -> {:ok, data}
    end
  end

  @callback data_check(any()) :: {atom(), any()}
  @spec data_check(map()) :: {atom(), map()}
  def data_check(data) do
    case data do
      nil -> {:error, "Data is nil"}
      data -> {:ok, data}
    end
  end

  @callback authenticate(any(), any()) :: {atom(), token(), any()}
  @spec authenticate(map(), map()) :: {atom(), token(), map()}
  def authenticate(authentification_data, saved_data) do
    with {:ok, authentification_data} <- authentification_data_check(authentification_data),
         {:ok, data} <- data_check(saved_data) do
      {:ok, token} = generate_token(data)
      DataStorage.insert_token(token, data)
      {:ok, token, data}
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec login(map(), map()) :: {atom(), token(), map()}
  def login(authentification_data, saved_data) do
    authenticate(authentification_data, saved_data)
  end

  @callback deauthenticate(token()) :: {atom(), any()}
  @spec deauthenticate(token()) :: {atom(), any()}
  def deauthenticate(token) when is_bitstring(token) do
    case DataStorage.delete_token(token) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  @spec logout(token()) :: {atom(), any()}
  def logout(token) when is_bitstring(token) do
    deauthenticate(token)
  end

  @callback get_token_data(token()) :: {atom(), map(), number()}
  @spec get_token_data(token()) :: {atom(), any()}
  def get_token_data(token) when is_bitstring(token) do
    with {:ok, token_data} <- DataStorage.get_token_data(token),
         {:ok, expiration} <- DataStorage.token_expires?(token) do
      {:ok, token_data, expiration}
    else
      {:error, error} -> {:error, error}
    end
  end
end
