defmodule Auctoritas.DataStorage.Data do
  alias Auctoritas.DataStorage.Data

  @typedoc "Token expiration in seconds"
  @type expiration() :: non_neg_integer()

  @typedoc "When was token inserted (UNIX Epoch time)"
  @type inserted_at() :: non_neg_integer()

  @typedoc "When was token updated (UNIX Epoch time)"
  @type updated_at() :: non_neg_integer()

  @type metadata() :: %{
          inserted_at: inserted_at(),
          updated_at: updated_at(),
          expires_in: expiration(),
          refresh_token: String.t() | nil,
        }

  @derive Jason.Encoder
  @enforce_keys [:data, :metadata]
  defstruct [:data, :metadata]

  @typedoc """
  Data struct with data and metadata maps
  * data is data associated when inserting token into data_storage
  * metadata contains inserted_at, updated_at, expires_in time
  inserted when using `get_token_data` function from data_storage
  """
  @type t :: %__MODULE__{
          data: map(),
          metadata: metadata()
        }

  @spec new(data_map :: map()) :: %__MODULE__{}
  def new(data_map) when is_map(data_map) do
    struct(__MODULE__, data_map)
  end

  @spec new(data :: map(), expiration :: expiration()) :: %__MODULE__{}
  def new(data, expiration) when is_map(data) and is_number(expiration) do
    new(%{data: data, metadata: initial_metadata(expiration)})
  end

  @spec update_data(data :: %__MODULE__{}, data :: map()) :: %__MODULE__{}
  def update_data(%__MODULE__{} = data, new_data) when is_map(new_data) do
    data
    |> update_metadata(%{
      updated_at: System.system_time(:second)
    })
    |> Map.put(:data, Map.merge(data.data, new_data))
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

  @spec add_refresh_token(data :: %__MODULE__{}, refresh_token :: String.t()) :: %__MODULE__{}
  def add_refresh_token(%__MODULE__{} = data, refresh_token) when is_bitstring(refresh_token) do
    data
    |> update_metadata(%{refresh_token: refresh_token})
  end

  @spec initial_metadata(expiration :: expiration()) :: metadata()
  def initial_metadata(expiration) do
    %{
      inserted_at: System.system_time(:second),
      updated_at: System.system_time(:second),
      expires_in: expiration,
      refresh_token: nil
    }
  end

  def encode(%__MODULE__{} = data) do
    Jason.encode(data)
  end

  def decode(data_json) when is_bitstring(data_json) do
    case Jason.decode(data_json, keys: :atoms) do
      {:ok, data_map} ->
        {:ok, Data.new(data_map)}

      {:error, error} ->
        {:error, error}
    end
  end
end
