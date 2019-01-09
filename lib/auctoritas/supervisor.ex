defmodule Auctoritas.AuthenticationSupervisor do
  use Supervisor

  alias Auctoritas.AuthenticationManager.DataStorage

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      DataStorage.worker()
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
