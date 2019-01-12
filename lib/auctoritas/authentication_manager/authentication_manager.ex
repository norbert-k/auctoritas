defmodule Auctoritas.AuthenticationManager do
  @moduledoc """
  AuthenticationManager

  Manages Auctoritas Authentication GenServer
  """
  use GenServer

  alias Auctoritas.Config
  alias Auctoritas.DataStorage.Data

  @default_name "auctoritas_default"

  @typedoc "Authentication token"
  @type token() :: String.t()

  @typedoc "Name from config (Auctoritas supervisor name)"
  @type name() :: String.t()

  @typedoc "Token expiration in seconds"
  @type expiration() :: non_neg_integer()

  @doc """
  Start Auctoritas GenServer with specified config (from `Auctoritas.Config`)
  """
  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config, name: auctoritas_name(config))
  end

  defp auctoritas_name(name) when is_bitstring(name) do
    ("auctoritas_authentication_manager_" <> name)
    |> String.to_atom()
  end

  defp auctoritas_name(%Config{} = config) do
    ("auctoritas_authentication_manager_" <> config.name)
    |> String.to_atom()
  end

  def init(%Config{} = config) do
    {:ok, config}
  end

  @doc "Alternative to `authenticate(authentication_data, data)`"
  def login(authentication_data, data), do: authenticate(authentication_data, data)

  @doc """
  Authenticate with supplied arguments to default authentication_manager;
  * authentication_data is checked and then used to generate token
  * data is stored inside data_storage with token as the key

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate(%{username: "username"}, %{user_id: 1})
      {:ok, "ec4eecaff1cc7e9daa511620e47203424e70b9c9785d51d11f246f27fab33a0b"}
  """
  def authenticate(authentication_data, data) do
    authenticate(auctoritas_name(@default_name), authentication_data, data)
  end

  @doc "Alternative to `authenticate(name, authentication_data, data)`"
  def login(name, authentication_data, data), do: authenticate(name, authentication_data, data)

  @doc """
  Authenticate with supplied arguments to custom authentication_manager;
  * authentication_data is checked and then used to generate token
  * data is stored inside data_storage with token as the key

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate("custom_name", %{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}
  """
  def authenticate(name, authentication_data, data) when is_bitstring(name) do
    authenticate(auctoritas_name(name), authentication_data, data)
  end

  def authenticate(pid, authentication_data, data) do
    case GenServer.call(pid, {:authenticate, authentication_data, data}) do
      {:ok, token, data} -> {:ok, token, data}
      {:error, error} -> {:error, error}
    end
  end

  @spec authenticate_check(%Config{}, map(), map()) :: {:ok, token(), %Data{}} | {:error, any()}
  defp authenticate_check(config, authentication_data, data) do
    with {:ok, authentication_data} <-
           config.token_manager.authentication_data_check(config.name, authentication_data),
         {:ok, data} <- config.token_manager.data_check(config.name, data),
         {:ok, token} <- config.token_manager.generate_token(config.name, authentication_data) do
      config.data_storage.insert_token(config.name, config.expiration, token, data)
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Get associated token data;

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate(%{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}

      iex> Auctoritas.AuthenticationManager.get_token_data("0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633")
      {:ok,
      %Auctoritas.AuthenticationManager.DataStorage.Data{
       data: %{user_id: 1},
       metadata: %{
         expires_in: 86310242,
         inserted_at: 1547201115,
         updated_at: 1547201115
       }
      }}

  """
  def get_token_data(token) do
    get_token_data(@default_name, token)
  end

  @doc """
  Get associated token data;

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate("custom_name", %{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}

      iex> Auctoritas.AuthenticationManager.get_token_data("custom_name", "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633")
      {:ok,
      %Auctoritas.AuthenticationManager.DataStorage.Data{
       data: %{user_id: 1},
       metadata: %{
         expires_in: 86310242,
         inserted_at: 1547201115,
         updated_at: 1547201115
       }
      }}

  """
  def get_token_data(name, token) when is_bitstring(name) do
    get_token_data(auctoritas_name(name), token)
  end

  def get_token_data(pid, token) do
    case GenServer.call(pid, {:get_token_data, :normal, token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  def get_token_data_silent(token) do
    get_token_data_silent(@default_name, token)
  end

  def get_token_data_silent(name, token) when is_bitstring(name) do
    get_token_data_silent(auctoritas_name(name), token)
  end

  def get_token_data_silent(pid, token) do
    case GenServer.call(pid, {:get_token_data, :silent, token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  def get_tokens(start, amount) do
    get_tokens(@default_name, start, amount)
  end

  def get_tokens(name, start, amount) when is_bitstring(name) do
    get_tokens(auctoritas_name(name), start, amount)
  end

  def get_tokens(pid, start, amount) do
    case GenServer.call(pid, {:get_tokens, start, amount}) do
      {:ok, tokens} -> {:ok, tokens}
      {:error, error} -> {:error, error}
    end
  end

  def get_tokens_with_data(start, amount) do
    get_tokens_with_data(@default_name, start, amount)
  end

  def get_tokens_with_data(name, start, amount) when is_bitstring(name) do
    get_tokens_with_data(auctoritas_name(name), start, amount)
  end

  def get_tokens_with_data(pid, start, amount) do
    case get_tokens(pid, start, amount) do
      {:ok, tokens} ->
        tokens
        |> Enum.map(fn token ->
          case get_token_data_silent(pid, token) do
            {:ok, token_data} -> token_data
            {:error, error} -> {:error, error}
          end
        end)

      {:error, error} ->
        {:error, error}
    end
  end

  @doc "Alternative to `logout(token)`"
  def logout(token), do: deauthenticate(token)

  @doc """
  Deauthenticate supplied token from default authentication_manager

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate(%{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}

      iex> Auctoritas.AuthenticationManager.deauthenticate("0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633")
      {:ok, true}
  """
  def deauthenticate(token) do
    deauthenticate(auctoritas_name(@default_name), token)
  end

  @doc "Alternative to `logout(name, token)`"
  def logout(name, token), do: deauthenticate(name, token)

  @doc """
  Deauthenticate supplied token from custom authentication_manager

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate("custom_name", %{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}

      iex> Auctoritas.AuthenticationManager.deauthenticate("custom_name", "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633")
      {:ok, true}
  """
  def deauthenticate(name, token) when is_bitstring(name) do
    deauthenticate(auctoritas_name(name), token)
  end

  def deauthenticate(pid, token) do
    case GenServer.call(pid, {:deauthenticate, token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp get_token_data_from_data_store(config, token) do
    case config.data_storage.get_token_data(config.name, token) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp reset_token_expiration(config, token) do
    case config.data_storage.reset_expiration(config.name, token, config.expiration) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp delete_token_from_data_store(config, token) do
    case config.data_storage.delete_token(config.name, token) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp get_tokens_from_data_store(config, start, amount) do
    case config.data_storage.get_tokens(config.name, start, amount) do
      {:ok, tokens} -> {:ok, tokens}
      {:error, error} -> {:error, error}
    end
  end

  def handle_call({:authenticate, authentication_data, data}, _from, %Config{} = config) do
    case authenticate_check(config, authentication_data, data) do
      {:ok, token, data} ->
        {:reply, {:ok, token, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_token_data, :normal, token}, _from, %Config{session_type: :sliding} = config) do
    with {:ok, true} <- reset_token_expiration(config, token),
         {:ok, data} <- get_token_data_from_data_store(config, token) do
      {:reply, {:ok, data}, config}
    else
      {:ok, false} -> {:reply, {:error, "Token expired or doesn't exist"}, config}
      {:error, error} -> {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_token_data, :normal, token}, _from, %Config{} = config) do
    case get_token_data_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_token_data, :silent, token}, _from, %Config{} = config) do
    case get_token_data_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:deauthenticate, token}, _from, %Config{} = config) do
    case delete_token_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_tokens, start, amount}, _from, %Config{} = config) do
    case get_tokens_from_data_store(config, start, amount) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end
end
