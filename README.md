![Alt text](./github/Auctoritas_logo.svg)

Session like authentication library for Elixir applications
* Documentation: [HexDocs](https://hexdocs.pm/auctoritas/api-reference.html)

# WORK IN PROGRESS
### Todo

- [x] Sliding session type
- [x] Static session type
- [x] Refresh token session type
- [x] Unit tests
- [x] Refresh token <-> Token link
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
    {:auctoritas, "~> 0.4.0"}
  ]
end
```

## Basic Usage
```elixir
iex> alias Auctoritas.AuthenticationManager, as: Auth
Auctoritas.AuthenticationManager

iex> auth_data = %{user_id: 123}
%{user_id: 123}


iex> {:ok, token} = Auth.authenticate(auth_data)
{:ok, "35cdc028d1623b58f616d21386d1c7982b25183776b7af69f9bb7dc0852a5095"}

iex> {:ok, data} = Auth.get_token_data(token)
{:ok,
 %Auctoritas.AuthenticationManager.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 86385250,
     inserted_at: 1547158890,
     updated_at: 1547158890
   }
 }}
 
 iex> {:ok, data} = Auth.deauthenticate(token)
 {:ok, true}
```