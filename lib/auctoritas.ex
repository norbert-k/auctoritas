defmodule Auctoritas do
  @moduledoc """
  # Auctoritas

  Session like authentication library for Elixir applications
  * Documentation: [HexDocs](https://hexdocs.pm/auctoritas/api-reference.html)

  ## Installation

  If [available in Hex](https://hex.pm/docs/publish), the package can be installed
  by adding `auctoritas` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
  [
    {:auctoritas, "~> 0.2.0"}
  ]
  end
  ```

  ## Basic Usage
  ```elixir
  iex> alias Auctoritas.AuthenticationManager, as: Auth
  Auctoritas.AuthenticationManager

  iex> user_data = %{username: "USERNAME", password: "PASSWORD"}
  %{username: "USERNAME", password: "PASSWORD"}

  iex> token_data = %{user_id: 1, username: "USERNAME", email: "USERNAME@EMAIL.COM"}
  %{user_id: 1, username: "USERNAME", email: "USERNAME@EMAIL.COM"}

  iex> {:ok, token} = Auth.authenticate(user_data, token_data)
  {:ok, "35cdc028d1623b58f616d21386d1c7982b25183776b7af69f9bb7dc0852a5095"}

  iex> {:ok, data} = Auth.get_token_data(token)
  {:ok,
  %Auctoritas.AuthenticationManager.DataStorage.Data{
   data: %{email: "USERNAME@EMAIL.COM", user_id: 1, username: "USERNAME"},
   metadata: %{
     expires_in: 86385250,
     inserted_at: 1547158890,
     updated_at: 1547158890
   }
  }}

   iex> {:ok, data} = Auth.deauthenticate(token)
   {:ok, true}
  ```

  ## Configuration
  ```elixir
  config :auctoritas, :config,
    name: "auctoritas_default", # Custom name if you need multiple auctoritas authentication managers
    data_storage: Auctoritas.AuthenticationManager.DataStorage, # Custom data_storage implementation (default is Cachex)
    token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager, # Custom token_manager implementation
    expiration: 86400 # Token expiration timer in second

  ```

  ## Spawning Auctoritas authentication managers
  ```elixir
  iex> alias Auctoritas.AuthenticationManager, as: Auth
  Auctoritas.AuthenticationManager

  iex> alias Auctoritas.Config
  Auctoritas.Config

  iex> config = Config.new(name: "custom_name", token_manager: CustomTokenManager, expiration: 120)
  %Auctoritas.Config{
  data_storage: Auctoritas.AuthenticationManager.DataStorage,
  expiration: 120,
  name: "custom_name",
  token_manager: CustomTokenManager
  }

  iex> alias Auctoritas.AuthenticationSupervisor
  Auctoritas.AuthenticationSupervisor

  iex> AuthenticationSupervisor.start_link(config)
  {:ok, #PID<0.278.0>}

  iex> {:ok, token} = Auth.authenticate("custom_name", %{username: "username"}, %{})
  {:ok, "3acbc9f1362ba9fb09fc3db6e4e1f6cfa5fcd2738156d11461cab3bd0ed92940"}
  ```

  ## Implementing token_manager
  For custom token_manager you need to implement `Auctoritas.TokenManager` behaviour
  ```elixir
  defmodule Auctoritas.TokenManager do
  @type token() :: String.t()
  @type name() :: String.t()

  @callback generate_token(name(), any()) :: {atom(), token()}
  @callback authentification_data_check(name(), any()) :: {atom(), any()}
  @callback data_check(name(), any()) :: {atom(), any()}
  end
  ```
  Simplest way to implement `Auctoritas.TokenManager` behaviour is to inject default TokenManager into your own module with `__using__` macro
  ```elixir
  defmodule CustomTokenManager do
  use Auctoritas.AuthenticationManager.TokenManager
  end
  ```
  Now you can override default functions to suit your own needs
  ```elixir
  defmodule CustomTokenManager do
  use Auctoritas.AuthenticationManager.TokenManager

    @spec authentification_data_check(name(), map()) :: {atom(), any()}
    def authentification_data_check(name, data) when is_bitstring(name) and is_map(data) do
        case data do
          %{password: "secret_password"} -> {:ok, data}
          _ -> {:error, "Invalid user credentials"}
        end
    end
  end

  """
  use GenServer

  alias Auctoritas.Config
  alias Auctoritas.DataStorage.Data
  alias Auctoritas.DataStorage.RefreshTokenData

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

  @doc """
  Authenticate with supplied arguments to default authentication_manager;
  * authentication_data is checked and then used to generate token
  * data is stored inside data_storage with token as the key

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate(%{username: "username"}, %{user_id: 1})
      {:ok, "ec4eecaff1cc7e9daa511620e47203424e70b9c9785d51d11f246f27fab33a0b"}
  """
  def authenticate(authentication_data) do
    authenticate(auctoritas_name(@default_name), authentication_data)
  end

  @doc """
  Authenticate with supplied arguments to custom authentication_manager;
  * authentication_data is checked and then used to generate token
  * data is stored inside data_storage with token as the key

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate("custom_name", %{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}
  """
  def authenticate(name, authentication_data) when is_bitstring(name) do
    authenticate(auctoritas_name(name), authentication_data)
  end

  def authenticate(pid, authentication_data) do
    case GenServer.call(pid, {:authenticate, authentication_data}) do
      {:ok, token, data} -> {:ok, token, data}
      {:ok, token, refresh_token, data, refresh_token_data} -> {:ok, token, refresh_token, data, refresh_token_data}
      {:error, error} -> {:error, error}
    end
  end

  def refresh_token(token) do
    refresh_token(auctoritas_name(@default_name), token)
  end

  def refresh_token(name, token) when is_bitstring(name) do
    refresh_token(auctoritas_name(name), token)
  end

  def refresh_token(pid, token) do
    case GenServer.call(pid, {:refresh_token, token}) do
      {:ok, token, refresh_token, data, refresh_token_data} -> {:ok, token, refresh_token, data, refresh_token_data}
      {:error, error} -> {:error, error}
    end
  end

  @spec authenticate_check(%Config{}, map()) :: {:ok, token :: token(), %Data{}} | {:ok, token :: token(), refresh_token :: token(), %Data{}, %RefreshTokenData{}} | {:error, any()}
  defp authenticate_check(config, authentication_data) do
    case config.token_manager.generate_token_and_data(config.name, authentication_data) do
      {:ok, token, data_map} ->
        case config.token_type do
          :refresh_token ->

            with {:ok, _token, %Data{} = data} <- config.data_storage.insert_token(config.name, config.expiration, token, data_map),
                 {:ok, refresh_token} <- config.token_manager.generate_refresh_token(config.name, authentication_data),
                 {:ok, _refresh_token, %RefreshTokenData{} = refresh_token_data} <- config.data_storage.insert_refresh_token(config.name, config.refresh_token_expiration, refresh_token, token, authentication_data) do
              {:ok, token, refresh_token, data, refresh_token_data}
            else
              {:error, error} -> {:error, error}
            end
          _ ->
            with {:ok, token, %Data{} = data} <- config.data_storage.insert_token(config.name, config.expiration, token, data_map) do
              {:ok, token, data}
            else
              {:error, error} -> {:error, error}
            end
        end
      {:error, error} -> {:error, error}
    end
  end

  @spec refresh_token_check(%Config{token_type: :refresh_token}, refresh_token :: token()) :: {:ok, token :: token(), refresh_token :: token(), %Data{}} | {:error, any()}
  defp refresh_token_check(%Config{token_type: :refresh_token} = config, refresh_token) do
    with {:ok, %RefreshTokenData{:auth_data => auth_data, :token => token}} <- config.data_storage.get_refresh_token_data(config.name, refresh_token),
         {:ok, new_token, new_refresh_token, data, refresh_token_data} <- authenticate_check(config, auth_data),
         {:ok, true} <- config.data_storage.delete_token(config.name, token),
         {:ok, true} <- config.data_storage.delete_refresh_token(config.name, refresh_token) do
      {:ok, new_token, new_refresh_token, data, refresh_token_data}
    else
      {:error, error} -> {:error, error}
    end
  end

  def get_token_data(token, :silent) do
    get_token_data(@default_name, token, :silent)
  end

  def get_token_data(name, token, :silent) when is_bitstring(name) do
    get_token_data(auctoritas_name(name), token, :silent)
  end

  def get_token_data(pid, token, :silent) do
    case GenServer.call(pid, {:get_token_data, :silent, token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Get associated token data;
    Token : f3ae51e91f9a882422b52da3fc759a271ca61fde152f64caf9f6ce86161f5c20
    refresh token: 48cc25bd6bb4f1f850df4191365227ba88aad241574f3ed448774a5658f5dac8
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

  def get_refresh_tokens(start, amount) do
    get_refresh_tokens(@default_name, start, amount)
  end

  def get_refresh_tokens(name, start, amount) when is_bitstring(name) do
    get_refresh_tokens(auctoritas_name(name), start, amount)
  end

  def get_refresh_tokens(pid, start, amount) do
    case GenServer.call(pid, {:get_refresh_tokens, start, amount}) do
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
        tokens = tokens
        |> Enum.map(fn token ->
          case get_token_data(pid, token, :silent) do
            {:ok, token_data} -> token_data
            {:error, error} -> {:error, error}
          end
        end)
        {:ok, tokens}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Deauthenticate supplied token from default authentication_manager

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate(%{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}

      iex> Auctoritas.AuthenticationManager.deauthenticate("0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633")
      {:ok, true}
  """
  def deauthenticate(token, :token) when is_bitstring(token) do
    deauthenticate(auctoritas_name(@default_name), token, :token)
  end

  @doc """
  Deauthenticate supplied token from custom authentication_manager

  ## Examples
      iex> Auctoritas.AuthenticationManager.authenticate("custom_name", %{username: "username"}, %{user_id: 1})
      {:ok, "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633"}

      iex> Auctoritas.AuthenticationManager.deauthenticate("custom_name", "0a0c820b3640bca38ec482da31510803e369e7b90dfc01cb1e571b7970b02633")
      {:ok, true}
  """
  def deauthenticate(name, token, :token) when is_bitstring(name) and is_bitstring(token) do
    deauthenticate(auctoritas_name(name), token, :token)
  end

  def deauthenticate(pid, token, :token) do
    case GenServer.call(pid, {:deauthenticate, token, :token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  def deauthenticate(token, :refresh_token) when is_bitstring(token) do
    deauthenticate(auctoritas_name(@default_name), token, :refresh_token)
  end

  def deauthenticate(name, token, :refresh_token) when is_bitstring(name) and is_bitstring(token) do
    deauthenticate(auctoritas_name(name), token, :refresh_token)
  end

  def deauthenticate(pid, token, :refresh_token) do
    case GenServer.call(pid, {:deauthenticate, token, :refresh_token}) do
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

  defp delete_refresh_token_from_data_store(config, token) do
    case config.data_storage.delete_refresh_token(config.name, token) do
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

  defp get_refresh_tokens_from_data_store(config, start, amount) do
    case config.data_storage.get_refresh_tokens(config.name, start, amount) do
      {:ok, tokens} -> {:ok, tokens}
      {:error, error} -> {:error, error}
    end
  end

  def handle_call({:refresh_token, refresh_token}, _from, %Config{token_type: :refresh_token} = config) do
    case refresh_token_check(config, refresh_token) do
      {:ok, token, refresh_token, data, refresh_token_data} ->
        {:reply, {:ok, token, refresh_token, data, refresh_token_data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:authenticate, authentication_data}, _from, %Config{token_type: :refresh_token} = config) do
    case authenticate_check(config, authentication_data) do
      {:ok, token, refresh_token, data, refresh_token_data} ->
        {:reply, {:ok, token, refresh_token, data, refresh_token_data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:authenticate, authentication_data}, _from, %Config{} = config) do
    case authenticate_check(config, authentication_data) do
      {:ok, token, data} ->
        {:reply, {:ok, token, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_token_data, :normal, token}, _from, %Config{token_type: :sliding} = config) do
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

  def handle_call({:deauthenticate, token, :refresh_token}, _from, %Config{} = config) do
    case delete_refresh_token_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:deauthenticate, token, :token}, _from, %Config{} = config) do
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

  def handle_call({:get_refresh_tokens, start, amount}, _from, %Config{} = config) do
    case get_refresh_tokens_from_data_store(config, start, amount) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end
end
