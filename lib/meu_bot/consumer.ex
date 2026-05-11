defmodule MeuBot.Consumer do
  @moduledoc """
  Handler de eventos do Discord.
  Recebe mensagens e despacha para MeuBot.Commands via pattern matching.
  """
  use Nostrum.Consumer

  alias Nostrum.Api
  alias MeuBot.Commands

  # ─── Handler principal ────────────────────────────────────────────────────

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    # Ignora mensagens de outros bots
    unless msg.author.bot do
      content = String.trim(msg.content)
      resposta = dispatch(content, msg)

      if resposta do
        Api.create_message(msg.channel_id, resposta)
      end
    end
  end

  # Ignora todos os outros eventos do Discord
  def handle_event(_event), do: :noop

  # ─── Despacho de comandos via pattern matching ────────────────────────────

  defp dispatch("!ping", _msg) do
    Commands.ping()
  end

  defp dispatch("!clima " <> cidade, _msg) do
    Commands.clima(String.trim(cidade))
  end

  defp dispatch("!jogo " <> nome, _msg) do
    Commands.jogo(String.trim(nome))
  end

  defp dispatch("!conv " <> args, _msg) do
    case String.split(String.trim(args), " ", parts: 3) do
      [valor, origem, destino] -> Commands.conv(valor, origem, destino)
      _ -> "❌ Uso correto: `!conv <valor> <moeda_origem> <moeda_destino>`\nEx: `!conv 100 USD BRL`"
    end
  end

  defp dispatch("!prevchuva " <> args, _msg) do
    case String.split(String.trim(args), " ", parts: 2) do
      [cidade, dias] -> Commands.prevchuva(cidade, dias)
      _ -> "❌ Uso correto: `!prevchuva <cidade> <dias>`\nEx: `!prevchuva Fortaleza 5`"
    end
  end

  defp dispatch("!lembrar " <> texto, msg) do
    Commands.lembrar(msg.author.id, String.trim(texto))
  end

  defp dispatch("!lembretes", msg) do
    Commands.lembretes(msg.author.id)
  end

  defp dispatch("!esquece", msg) do
    Commands.esquece(msg.author.id)
  end

  defp dispatch("!curiosidade " <> cidade, _msg) do
    Commands.curiosidade(String.trim(cidade))
  end

  defp dispatch("!ajuda", _msg) do
    """
    📖 **Comandos disponíveis:**

    `!ping` — Verifica se o bot está online
    `!clima <cidade>` — Clima atual de uma cidade
    `!jogo <nome>` — Informações sobre um jogo
    `!conv <valor> <origem> <destino>` — Converte moedas (ex: `!conv 100 USD BRL`)
    `!prevchuva <cidade> <dias>` — Previsão de chuva (max 7 dias)
    `!lembrar <texto>` — Salva um lembrete
    `!lembretes` — Lista seus lembretes salvos
    `!esquece` — Apaga todos os seus lembretes
    `!curiosidade <cidade>` — Clima + curiosidade sobre uma cidade
    """
  end

  # Ignora mensagens que não são comandos
  defp dispatch(_content, _msg), do: nil
end
