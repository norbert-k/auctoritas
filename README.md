![Alt text](./github/Auctoritas_logo.svg)

Session like authentication library for Elixir applications
* Documentation: [HexDocs](https://hexdocs.pm/auctoritas/api-reference.html)

# WORK IN PROGRESS
### Todo

- [x] Sliding session type
- [x] Static session type
- [x] Refresh token session type
- [ ] Full unit testing
- [ ] Refresh token <-> Token link
- [ ] Plug integration
- [ ] Improve documentation
- [x] Default data_store (Cachex; Erlang ETS)
- [ ] Redis data_store

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `auctoritas` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auctoritas, "~> 0.3.0"}
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
```