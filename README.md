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
