defmodule Auctoritas.AuthenticationSupervisor do
  use Supervisor

  alias Auctoritas.AuthenticationManager.DataStorage
  alias Auctoritas.Config

  def start_link(%Config{} = config) do
    Supervisor.start_link(__MODULE__, config, name: supervisor_name(config))
  end

  defp supervisor_name(%Config{} = config) do
    config.name <> "_auctoritas_supervisor"
    |> String.to_atom()
  end

  def init(%Config{} = config) do
    children = [
      DataStorage.worker(config)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
