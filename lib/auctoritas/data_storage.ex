defmodule Auctoritas.DataStorage do
  @type token() :: String.t()
  @type name() :: String.t()

  @callback insert_token(name(), number(), token(), any(), map()) :: {atom(), any()}
  @callback update_metadata(name(), token(), map()) :: {atom(), any()}
  @callback update_token(name(), token(), any()) :: {atom(), any()}
  @callback delete_token(name(), token()) :: {atom(), any()}

  @callback get_token_data(name(), token()) :: {atom(), any()}
  @callback get_tokens(name(), non_neg_integer(), non_neg_integer()) :: {atom(), any()}

  @callback token_expires?(name(), token()) :: {atom(), any()}
end
