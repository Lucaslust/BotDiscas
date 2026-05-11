defmodule MeuBot do
  @moduledoc """
  Ponto de entrada da aplicação (Application + Supervisor principal).
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
