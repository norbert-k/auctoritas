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
    "auctoritas_authentication_manager_" <> name
    |> String.to_atom()
  end

  defp auctoritas_name(%Config{} = config) do
    "auctoritas_authentication_manager_" <> config.name
    |> String.to_atom()
  end

  def init(%Config{} = config) do
    {:ok, config}
  end

  def authenticate(authentification_data, data) do
    authenticate(auctoritas_name(@default_name), authentification_data, data)
  end

  def authenticate(name, authentification_data, data) when is_bitstring(name) do
    authenticate(auctoritas_name(name), authentification_data, data)
  end

  def authenticate(pid, authentification_data, data) do
    case GenServer.call(pid, {:authenticate, authentification_data, data}) do
      {:ok, token, data} -> {:ok, token}
      {:error, error} -> {:error, error}
    end
  end

  defp authenticate_check(config, authentification_data, data) do
    with {:ok, authentification_data} <- config.token_manager.authentification_data_check(config.name, authentification_data),
         {:ok, data} <- config.token_manager.data_check(config.name, data),
         {:ok, token} <- config.token_manager.generate_token(config.name, data) do
      case config.data_storage.insert_token(config.name, token, data) do
        {:ok, data} -> {:ok, token, data}
        {:error, error} -> {:error, error}
      end
    else
      {:error,error} -> {:error, error}
    end
  end

  def get_token_data(token) do
    get_token_data(auctoritas_name(@default_name), token)
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

  def deauthenticate(token) do
    deauthenticate(auctoritas_name(@default_name), token)
  end

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

  def handle_call({:authenticate, authentification_data, data}, _from, %Config{} = config) do
    case authenticate_check(config, authentification_data, data) do
      {:ok, token, data} ->
        {:reply, {:ok, token, data}, config}
      {:error, error} -> {:reply, {:error, error}, config}
    end
  end

  def handle_call({:get_token_data, token}, _from, %Config{} = config) do
    case get_token_data_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}
      {:error, error} -> {:reply, {:error, error}, config}
    end
  end

  def handle_call({:deauthenticate, token}, _from, %Config{} = config) do
    case delete_token_from_data_store(config, token) do
      {:ok, data} ->
        {:reply, {:ok, data}, config}
      {:error, error} -> {:reply, {:error, error}, config}
    end

  end


end
