defmodule Auctoritas.Config do
  @enforce_keys [:name, :data_storage, :token_manager, :session_type, :expiration]
  defstruct [:name, :data_storage, :token_manager, :session_type, :expiration]

  @type expiration() :: non_neg_integer()

  @type t :: %__MODULE__{
               name: String.t(),
               data_storage: module(),
               token_manager: module(),
               session_type: :static | :sliding | :refresh_token,
               expiration: expiration()
             }

  alias Auctoritas.AuthenticationManager.CachexDataStorage
  alias Auctoritas.AuthenticationManager.DefaultTokenManager

  @config_defaults [
    name: "auctoritas_default",
    data_storage: CachexDataStorage,
    token_manager: DefaultTokenManager,
    session_type: :sliding,
    expiration: 60 * 60 * 24
  ]

  @config_key :auctoritas

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
        data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
        token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
        expiration: 86400
      }

      iex> Auctoritas.Config.new(name: "custom_name")
      %Auctoritas.Config{
        name: "custom_name",
        data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
        token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
        expiration: 86400
      }
  """
  @spec new([]) :: %Auctoritas.Config{}
  def new(options \\ []) when is_list(options) do
    options =
      Keyword.merge(@config_defaults, options)
      |> Enum.into(%{})

    struct(__MODULE__, options)
  end

  @doc """
  Read Auctoritas config from config files
  """
  @spec read() :: %Auctoritas.Config{}
  def read() do
    config_settings = Application.get_env(@config_key, :config)

    case config_settings do
      nil -> new()
      config_settings -> new(config_settings)
    end
  end
end
