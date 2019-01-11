defmodule Auctoritas.AuthenticationSupervisor do
  use Supervisor

  alias Auctoritas.Config

  def start_link(%Config{} = config) do
    Supervisor.start_link(__MODULE__, config, name: supervisor_name(config))
  end

  defp supervisor_name(%Config{} = config) do
    (config.name <> "_auctoritas_supervisor")
    |> String.to_atom()
  end

  def init(%Config{} = config) do
    children = [
      {Auctoritas.AuthenticationManager, config}
    ]

    worker =
      case config.data_storage.start_link(config) do
        {:ok, worker} -> [worker]
        {:no_worker} -> []
      end

    children = children ++ worker

    Supervisor.init(children, strategy: :one_for_one)
  end
end
