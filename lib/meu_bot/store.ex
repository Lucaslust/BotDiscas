defmodule MeuBot.Store do
  @moduledoc """
  GenServer responsável pela persistência de lembretes em JSON.
  Lê o arquivo ao iniciar e mantém o estado em memória.
  """
  use GenServer

  @file_path "lembretes.json"

  # ─── API pública ──────────────────────────────────────────────────────────

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get(user_id) do
    GenServer.call(__MODULE__, {:get, user_id})
  end

  def add(user_id, texto) do
    GenServer.call(__MODULE__, {:add, user_id, texto})
  end

  def clear(user_id) do
    GenServer.call(__MODULE__, {:clear, user_id})
  end

  # ─── Callbacks do GenServer ───────────────────────────────────────────────

  @impl true
  def init(:ok) do
    state = load_from_disk()
    {:ok, state}
  end

  @impl true
  def handle_call({:get, user_id}, _from, state) do
    lembretes = Map.get(state, user_id, [])
    {:reply, lembretes, state}
  end

  @impl true
  def handle_call({:add, user_id, texto}, _from, state) do
    lembretes = Map.get(state, user_id, [])
    new_state = Map.put(state, user_id, lembretes ++ [texto])
    save_to_disk(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:clear, user_id}, _from, state) do
    new_state = Map.delete(state, user_id)
    save_to_disk(new_state)
    {:reply, :ok, new_state}
  end

  # ─── Funções privadas ─────────────────────────────────────────────────────

  defp load_from_disk do
    case File.read(@file_path) do
      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Map.new(fn {k, v} -> {k, v} end)

      {:error, :enoent} ->
        %{}

      {:error, _} ->
        %{}
    end
  end

  defp save_to_disk(state) do
    content = Jason.encode!(state, pretty: true)
    File.write(@file_path, content)
  end
end
