defmodule Auctoritas.DataStorage.RefreshTokenData do
  alias Auctoritas.DataStorage.RefreshTokenData

  @typedoc "Token expiration in seconds"
  @type expiration() :: non_neg_integer()

  @typedoc "When was token inserted (UNIX Epoch time)"
  @type inserted_at() :: non_neg_integer()

  @typedoc "When was token updated (UNIX Epoch time)"
  @type updated_at() :: non_neg_integer()

  @typedoc "Authentication token"
  @type token() :: String.t()

  @type metadata() :: %{
                        inserted_at: inserted_at(),
                        updated_at: updated_at(),
                        expires_in: expiration(),
                      }

  @derive Jason.Encoder
  @enforce_keys [:auth_data, :token, :metadata]
  defstruct [:auth_data, :token, :metadata]

  @typedoc """
  Data struct with data and metadata maps
  * data is data associated when inserting token into data_storage
  * metadata contains inserted_at, updated_at, expires_in time
  inserted when using `get_token_data` function from data_storage
  """
  @type t :: %__MODULE__{
               auth_data: map(),
               token: token(),
               metadata: metadata()
             }

  @spec new(refresh_token_data_map :: map()) :: %__MODULE__{}
  def new(refresh_token_data_map) when is_map(refresh_token_data_map) do
    struct(__MODULE__, refresh_token_data_map)
  end

  @spec new(auth_data :: map(), token :: token(), expiration :: expiration()) :: %__MODULE__{}
  def new(auth_data, token, expiration) when is_map(auth_data) and is_number(expiration) and is_bitstring(token) do
    new(%{auth_data: auth_data, token: token, metadata: initial_metadata(expiration)})
  end

  @spec update_auth_data(data :: %__MODULE__{}, new_auth_data :: map()) :: %__MODULE__{}
  def update_auth_data(%__MODULE__{} = data, new_auth_data) when is_map(new_auth_data) do
    data
    |> update_metadata(%{
      updated_at: System.system_time(:second)
    })
    |> Map.put(:auth_data, Map.merge(data.auth_data, new_auth_data))
  end

  @spec update_metadata(data :: %__MODULE__{}, new_metadata :: map()) :: %__MODULE__{}
  def update_metadata(%__MODULE__{} = data, new_metadata) when is_map(new_metadata) do
    Map.put(data, :metadata, Map.merge(data.metadata, new_metadata))
  end

  @spec add_expiration(data :: %__MODULE__{}, expiration :: expiration()) :: %__MODULE__{}
  def add_expiration(%__MODULE__{} = data, expiration) when is_number(expiration) do
    data
    |> update_metadata(%{expires_in: expiration})
  end

  @spec initial_metadata(expiration :: expiration()) :: metadata()
  def initial_metadata(expiration) do
    %{
      inserted_at: System.system_time(:second),
      updated_at: System.system_time(:second),
      expires_in: expiration,
    }
  end

  def encode(%__MODULE__{} = data) do
    Jason.encode(data)
  end

  def decode(data_json) when is_bitstring(data_json) do
    case Jason.decode(data_json, keys: :atoms) do
      {:ok, data_map} ->
        {:ok, RefreshTokenData.new(data_map)}

      {:error, error} ->
        {:error, error}
    end
  end
end
