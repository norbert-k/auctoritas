defmodule Auctoritas.Config do
  @enforce_keys [:name, :data_storage, :token_manager]
  defstruct [:name, :data_storage, :token_manager]

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.AuthenticationManager.TokenManager

  @config_defaults [name: "auctoritas_default", data_storage: DataStorage, token_manager: TokenManager]

  @doc """
  Create new config for Auctoritas

  Arguments:
  * secret_key:  Secret key to use when generating authentication tokens.
  * data_storage: Data storage module to save data and manage authentication tokens. (DEFAULT value exists)
  * token_manager: Token manager module to generate and read tokens. (DEFAULT value exists)

  ## Examples
      iex> Auctoritas.Config.new()
      %Auctoritas.Config{
        name: "auctoritas_default",
        data_storage: Auctoritas.AuthenticationManager.DataStorage,
        token_manager: Auctoritas.AuthenticationManager.TokenManager
      }
  """
  @spec new([]) :: %Auctoritas.Config{}
  def new(options \\ []) when is_list(options) do
    options = Keyword.merge(@config_defaults, options)
    |> Enum.into(%{})

    struct(__MODULE__, options)
  end

end