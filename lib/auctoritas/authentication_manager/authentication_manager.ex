defmodule Auctoritas.AuthenticationManager do
  @moduledoc """
  AuthenticationManager

  Manages Auctoritas Authentication GenServer
  """
  use GenServer

  alias Auctoritas.Config

  @default_name "auctoritas_default"

  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config, name: auctoritas_name(config))
  end

  defp auctoritas_name(name) when is_bitstring(name) do
    ("auctoritas_authentication_manager_" <> name)
    |> String.to_atom()
  end

  defp auctoritas_name(%Config{} = config) do
    ("auctoritas_authentication_manager_" <> config.name)
    |> String.to_atom()
  end

  defp default_metadata() do
    %{
      inserted_at: System.system_time(:second),
      updated_at: System.system_time(:second)
    }
  end

  def init(%Config{} = config) do
    {:ok, config}
  end

  def login(authentication_data, data), do: authenticate(authentication_data, data)

  def authenticate(authentication_data, data) do
    authenticate(auctoritas_name(@default_name), authentication_data, data)
  end

  def login(name, authentication_data, data), do: authenticate(name, authentication_data, data)

  def authenticate(name, authentication_data, data) when is_bitstring(name) do
    authenticate(auctoritas_name(name), authentication_data, data)
  end

  def authenticate(pid, authentication_data, data) do
    case GenServer.call(pid, {:authenticate, authentication_data, data}) do
      {:ok, token, data} -> {:ok, token}
      {:error, error} -> {:error, error}
    end
  end

  defp authenticate_check(config, authentication_data, data) do
    with {:ok, authentication_data} <-
           config.token_manager.authentication_data_check(config.name, authentication_data),
         {:ok, data} <- config.token_manager.data_check(config.name, data),
         {:ok, token} <- config.token_manager.generate_token(config.name, data) do
      case config.data_storage.insert_token(
             config.name,
             config.expiration,
             token,
             data,
             default_metadata()
           ) do
        {:ok, data} -> {:ok, token, data}
        {:error, error} -> {:error, error}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  def get_token_data(token) do
    get_token_data(@default_name, token)
  end

  def get_token_data(name, token) when is_bitstring(name) do
    get_token_data(auctoritas_name(name), token)
  end

  def get_token_data(pid, token) do
    case GenServer.call(pid, {:get_token_data, token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  def get_tokens(start, amount) do
    get_tokens(@default_name, start, amount)
  end

  def get_tokens(name, start, amount) when is_bitstring(name) do
    get_tokens(auctoritas_name(name), start, amount)
  end

  def get_tokens(pid, start, amount) do
    case GenServer.call(pid, {:get_tokens, start, amount}) do
      {:ok, tokens} -> {:ok, tokens}
      {:error, error} -> {:error, error}
    end
  end

  def get_tokens_with_data(start, amount) do
    get_tokens_with_data(@default_name, start, amount)
  end

  def get_tokens_with_data(name, start, amount) when is_bitstring(name) do
    get_tokens_with_data(auctoritas_name(name), start, amount)
  end

  def get_tokens_with_data(pid, start, amount) do
    case get_tokens(pid, start, amount) do
      {:ok, tokens} ->
        tokens
        |> Enum.map(fn(token) ->
          case get_token_data(pid, token) do
            {:ok, token_data} -> token_data
            {:error, error} -> {:error, error}
          end
        end)
      {:error, error} -> {:error, error}
    end
  end

  def logout(token), do: deauthenticate(token)

  def deauthenticate(token) do
    deauthenticate(auctoritas_name(@default_name), token)
  end

  def logout(name, token), do: deauthenticate(name, token)

  def deauthenticate(name, token) when is_bitstring(name) do
    deauthenticate(auctoritas_name(name), token)
  end

  def deauthenticate(pid, token) do
    case GenServer.call(pid, {:deauthenticate, token}) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp get_token_data_from_data_store(config, token) do
    case config.data_storage.get_token_data(config.name, token) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp delete_token_from_data_store(config, token) do
    case config.data_storage.delete_token(config.name, token) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  defp get_tokens_from_data_store(config, start, amount) do
    case config.data_storage.get_tokens(config.name, start, amount) do
      {:ok, tokens} -> {:ok, tokens}
      {:error, error} -> {:error, error}
    end
  end


  def handle_call({:authenticate, authentication_data, data}, _from, %Config{} = config) do
    case authenticate_check(config, authentication_data, data) do
      {:ok, token, data} ->
        {:reply, {:ok, token, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_token_data, token}, _from, %Config{} = config) do
    case get_token_data_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:deauthenticate, token}, _from, %Config{} = config) do
    case delete_token_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}


      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_tokens, start, amount}, _from, %Config{} = config) do
    case get_tokens_from_data_store(config, start, amount) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}

      {:error, error} ->
        {:reply, {:error, error}, config}
    end
  end
end
