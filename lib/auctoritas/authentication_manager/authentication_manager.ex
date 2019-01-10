defmodule Auctoritas.AuthenticationManager do
  use GenServer

  alias Auctoritas.Config

  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config, name: auctoritas_name(config))
  end

  defp auctoritas_name(%Config{} = config) do
    "auctoritas_authentication_manager_" <> config.name
    |> String.to_atom()
  end

  def init(%Config{} = config) do
    {:ok, config}
  end

  def authenticate(pid, authentification_data, data) do
    GenServer.cast(pid, {:authenticate, authentification_data, data})
  end

  def handle_cast({:authenticate, authentification_data, data}, %Config{} = config) do
    with {:ok, authentification_data} <- config.token_manager.authentification_data_check(config.name, authentification_data),
         {:ok, data} <- config.token_manager.data_check(config.name, data),
         {:ok, token} <- config.token_manager.generate_token(data) do
      case config.data_storage.insert_token(config.name, token, data) do
        {:ok, data} -> {:ok, data}
        {:error, error} -> {:error, error}
      end
    else
      {:error,error} -> {:error, error}
    end
    {:noreply, config}
  end
end
