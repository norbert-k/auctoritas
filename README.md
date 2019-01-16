![Alt text](./github/Auctoritas_logo.svg)

Session like authentication library for Elixir applications
* Documentation: [HexDocs](https://hexdocs.pm/auctoritas/api-reference.html)

#### V1.0 release goals

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

```elixir
def deps do
  [
    {:auctoritas, "~> 0.9.0"}
  ]
end
```

## Basic Usage
```elixir

iex> auth_data = %{user_id: 123}
%{user_id: 123}


iex> {:ok, token} = Auctoritas.authenticate(auth_data)
{:ok, "35cdc028d1623b58f616d21386d1c7982b25183776b7af69f9bb7dc0852a5095"}

iex> {:ok, data} = Auctoritas.get_token_data(token)
{:ok,
 %Auctoritas.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 86385250,
     inserted_at: 1547158890,
     updated_at: 1547158890
   }
 }}
 
 iex> {:ok, data} = Auctoritas.deauthenticate(token)
 {:ok, true}
```

## Token types
Auctoritas supports three types of token management
* Sliding tokens (DEFAULT): Refreshes token expiration when accessing token
* Static tokens: Static expiration time
* [Refresh token] tokens: Returns token and refresh_token which you can use to "refresh/regenerate" token

## Sliding tokens (default)
##### Config:
```elixir
config :auctoritas, :config,
       name: "auctoritas_default",
       data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
       token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
       token_type: :sliding,
       expiration: 60 * 60 * 24
```
##### Example:
```elixir
iex> auth_data = %{user_id: 123}
%{user_id: 123}

iex> {:ok, token, data} = Auctoritas.authenticate(auth_data)
{:ok,
 "HmVRfaeUzl/6kKK/Kw191960Kw5OAXUB23/4s0/DBlvNUHehQrLL8ufM4tSzO5FY5tME85VuZAHz4Bh4sn6wcQ==",
 %Auctoritas.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 86400,
     inserted_at: 1547665009,
     updated_at: 1547665009
   },
   refresh_token: nil
 }}


iex> {:ok, data} = Auctoritas.get_token_data(token) # Refreshes token expiration
{:ok,
 %Auctoritas.DataStorage.Data{
    data: %{user_id: 123},
    metadata: %{
      expires_in: 86400,
      inserted_at: 1547665009,
      updated_at: 1547665009
    },
    refresh_token: nil
  }}
 
 iex> {:ok, true} = Auctoritas.deauthenticate(token) # Deletes token and its data
 {:ok, true}
```

## Static tokens
```elixir
config :auctoritas, :config,
       name: "auctoritas_default",
       data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
       token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
       token_type: :static,
       expiration: 60 * 60 * 24
```

##### Example:
```elixir
iex> auth_data = %{user_id: 123}
%{user_id: 123}

iex> {:ok, token, data} = Auctoritas.authenticate(auth_data)
{:ok,
 "HmVRfaeUzl/6kKK/Kw191960Kw5OAXUB23/4s0/DBlvNUHehQrLL8ufM4tSzO5FY5tME85VuZAHz4Bh4sn6wcQ==",
 %Auctoritas.DataStorage.Data{
    data: %{user_id: 123},
    metadata: %{
      expires_in: 86400,
      inserted_at: 1547665009,
      updated_at: 1547665009
    },
    refresh_token: nil
  }}

iex> {:ok, data} = Auctoritas.get_token_data(token) # Wont refresh token expiration
{:ok,
 %Auctoritas.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 86385250,
     inserted_at: 1547158890,
     updated_at: 1547158890
   }
 }}
 
 iex> {:ok, true} = Auctoritas.deauthenticate(token) # Deletes token and its data
 {:ok, true}
```

## [Refresh token] tokens
```elixir
config :auctoritas, :config,
       name: "auctoritas_default",
       data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
       token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
       token_type: :refresh_token,
       expiration: 60 * 60 * 24,
       refresh_token_expiration: 60 * 60 * 24 * 3
```

##### Example:
```elixir
iex> auth_data = %{user_id: 123}
%{user_id: 123}

iex> {:ok, token, refresh_token, data, auth_data} = Auctoritas.authenticate(auth_data)
{:ok,
 "Ny3yd4NTO2Q5q9ZZa3g2PibUQGkw6xxq9/NnBo7LvvkQzqBYXP683spTSUUipr6ATrxdjW0lumjNmTPxhuFtHw==", # Token
 "vKf1sWIw2Ap4tB3YjNKNvNyA9LZavsUYSBGW4x1/xgfdv024ja+brhyO1rqLiFRqS4PcGgb3U9+cctBe0n1yUQ==", # Refresh token
 %Auctoritas.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 86400,
     inserted_at: 1547667186,
     updated_at: 1547667186
   },
   refresh_token: "vKf1sWIw2Ap4tB3YjNKNvNyA9LZavsUYSBGW4x1/xgfdv024ja+brhyO1rqLiFRqS4PcGgb3U9+cctBe0n1yUQ=="
 },
 %Auctoritas.DataStorage.RefreshTokenData{
   auth_data: %{user_id: 123},
   metadata: %{
     expires_in: 259200,
     inserted_at: 1547667186,
     updated_at: 1547667186
   },
   token: "Ny3yd4NTO2Q5q9ZZa3g2PibUQGkw6xxq9/NnBo7LvvkQzqBYXP683spTSUUipr6ATrxdjW0lumjNmTPxhuFtHw=="
 }}


iex> {:ok, data} = Auctoritas.get_token_data(token)
{:ok,
 %Auctoritas.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 84656,
     inserted_at: 1547667186,
     updated_at: 1547667186
   },
   refresh_token: "vKf1sWIw2Ap4tB3YjNKNvNyA9LZavsUYSBGW4x1/xgfdv024ja+brhyO1rqLiFRqS4PcGgb3U9+cctBe0n1yUQ==" # Refresh token is linked to regular token
 }}
 
iex> {:ok, data} = Auctoritas.get_refresh_token_data(token)
{:ok,
 %Auctoritas.DataStorage.RefreshTokenData{
   auth_data: %{user_id: 123},
   metadata: %{
     expires_in: 257245,
     inserted_at: 1547669051,
     updated_at: 1547669051
   },
   token: "Ny3yd4NTO2Q5q9ZZa3g2PibUQGkw6xxq9/NnBo7LvvkQzqBYXP683spTSUUipr6ATrxdjW0lumjNmTPxhuFtHw=="
 }}

 
 iex> {:ok, true} = Auctoritas.deauthenticate(token) # Deletes only token
 {:ok, true}
 
 iex> {:ok, token, refresh_token, data, auth_data} = Auctoritas.refresh_token(refresh_token) # Refreshes token with refresh_token (generates new token and refresh_token)
{:ok,
 "nQYX+ezqnKibvnku8YebdiA0fAZ5l1cfVUYrTkYvT+l3CxB215fmhJx0/YevbnockZl/XZVbp0LzBQWvAcafdw==", # Token
 "wqHGH3mrzfABcRQusqO/HvRP+VgqyEEGEOZjQJNbh+B58/gcx5iBqsypDu6djAUlme2rB07X2q/oU/LKVLK3UQ==", # Refresh token
 %Auctoritas.DataStorage.Data{
   data: %{user_id: 123},
   metadata: %{
     expires_in: 86400,
     inserted_at: 1547669051,
     updated_at: 1547669051
   },
   refresh_token: "wqHGH3mrzfABcRQusqO/HvRP+VgqyEEGEOZjQJNbh+B58/gcx5iBqsypDu6djAUlme2rB07X2q/oU/LKVLK3UQ=="
 },
 %Auctoritas.DataStorage.RefreshTokenData{
   auth_data: %{user_id: 123},
   metadata: %{
     expires_in: 259200,
     inserted_at: 1547669051,
     updated_at: 1547669051
   },
   token: "nQYX+ezqnKibvnku8YebdiA0fAZ5l1cfVUYrTkYvT+l3CxB215fmhJx0/YevbnockZl/XZVbp0LzBQWvAcafdw=="
 }}

 
 iex> {:ok, true} = Auctoritas.deauthenticate(refresh_token, :refresh_token) # Deletes refresh token + token
 {:ok, true}
```