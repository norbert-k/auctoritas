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
      {Auctoritas, config}
    ]

    workers =
      case config.data_storage.start_link(config) do
        {:ok, workers} -> workers
        {:no_worker} -> []
      end

    children = children ++ workers

    Supervisor.init(children, strategy: :one_for_one)
  end
end
