defmodule EdgeDB.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      EdgeDB.Borrower,
      {Registry, keys: :unique, name: EdgeDB.ClientsRegistry}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EdgeDB.Supervisor)
  end
end
