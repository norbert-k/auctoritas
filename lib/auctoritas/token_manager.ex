defmodule Auctoritas.TokenManager do
  @type token() :: String.t()
  @type name() :: String.t()

  @callback generate_token(name(), any()) :: {atom(), token()}
  @callback datamanager(name()) :: {atom(), module()}

  @callback authentification_data_check(name(), any()) :: {atom(), any()}
  @callback data_check(name(), any()) :: {atom(), any()}
end