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