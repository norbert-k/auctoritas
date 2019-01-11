defmodule Auctoritas.DataStorage do
  @moduledoc """
  DataStorage module
  * Specifies `DataStorage` behaviour
  """

  @typedoc "Authentication token"
  @type token() :: String.t()

  @typedoc "Name from config (Auctoritas supervisor name)"
  @type name() :: String.t()

  @typedoc "Token expiration in seconds"
  @type expiration() :: non_neg_integer()

  @doc """
  Starts data_storage when returned `{:ok, worker_map_or_equals}`
  Return `{:no_worker}` if data_storage startup isn't required
  """
  @callback start_link(map()) :: {:ok, any()} | {:no_worker}

  @doc """
  Insert token with expiration and supplied data map.
  """
  @callback insert_token(name(), expiration(), token(), map(), map()) :: {:ok, token()} | {:error, error :: any()}

  @callback update_metadata(name(), token(), map()) :: {atom(), any()}
  @callback update_token(name(), token(), any()) :: {atom(), any()}

  @doc """
  Delete token from data_storage, used when deauthenticating (logging out)
  """
  @callback delete_token(name(), token()) :: {atom(), any()} :: {:ok, boolean()} | {:error, error :: any()}

  @callback get_token_data(name(), token()) :: {:ok, map()} | {:error, error :: any()}

  @doc """
  Return tokens with specified start and amount value
  """
  @callback get_tokens(name(), start :: non_neg_integer(), amount :: non_neg_integer()) :: {:ok, list()} | {:error, error :: any()}

  @doc """
  Return token expiration time in seconds
  """
  @callback token_expires?(name(), token()) :: {:ok, expiration()} | {:error, error :: any()}
end
