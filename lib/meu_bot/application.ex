defmodule MeuBot.Application do
  @moduledoc """
  Supervisor principal da aplicação.
  Sobe o Store (GenServer de persistência) e o Consumer (handler do Discord).
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MeuBot.Store,
      MeuBot.Consumer
    ]

    opts = [strategy: :one_for_one, name: MeuBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
