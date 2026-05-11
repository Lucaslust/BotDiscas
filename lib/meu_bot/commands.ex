defmodule MeuBot.Commands do
  @moduledoc """
  Implementação de cada comando do bot.
  Uma função pública por comando, funções privadas de suporte abaixo.
  """

  alias MeuBot.Store

  # ──────────────────────────────────────────────────────────────────────────
  # 1. !ping — sem parâmetro
  # API: nenhuma (resposta local)
  # ──────────────────────────────────────────────────────────────────────────

  def ping do
    "Pong! Bot online e funcionando."
  end

  # ──────────────────────────────────────────────────────────────────────────
  # 2. !clima <cidade> — um parâmetro
  # API: Open-Meteo + Geocoding API (gratuitas, sem chave)
  # ──────────────────────────────────────────────────────────────────────────

  def clima(cidade) do
    with {:ok, {lat, lon, nome}} <- geocode(cidade),
         {:ok, body} <- get("https://api.open-meteo.com/v1/forecast", query: [
           latitude: lat,
           longitude: lon,
           current: "temperature_2m,weathercode,windspeed_10m,relativehumidity_2m",
           timezone: "auto"
         ]),
         {:ok, data} <- Jason.decode(body) do
      current = data["current"]
      temp    = current["temperature_2m"]
      vento   = current["windspeed_10m"]
      umidade = current["relativehumidity_2m"]

      """
      **Clima em #{nome}**
      Temperatura: #{temp}°C
      Vento: #{vento} km/h
      Umidade: #{umidade}%
      """
    else
      {:error, msg} -> "Erro ao buscar clima: #{msg}"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # 3. !jogo <nome> — um parâmetro
  # API: RAWG Video Games Database (gratuita, chave via variável de ambiente)
  # ──────────────────────────────────────────────────────────────────────────

  def jogo(nome) do
    key = System.get_env("RAWG_API_KEY", "")

    with {:ok, body} <- get("https://api.rawg.io/api/games", query: [
           key: key,
           search: nome,
           page_size: 1
         ]),
         {:ok, data} <- Jason.decode(body),
         [game | _] <- Map.get(data, "results", []) do
      rating   = game["rating"]
      released = game["released"] || "N/A"
      genres   = game["genres"] |> Enum.map(& &1["name"]) |> Enum.join(", ")
      platforms = game["platforms"]
                  |> Enum.map(& get_in(&1, ["platform", "name"]))
                  |> Enum.take(3)
                  |> Enum.join(", ")

      """
      **#{game["name"]}**
      Rating: #{rating}/5
      Lançamento: #{released}
      Gêneros: #{genres}
      Plataformas: #{platforms}
      """
    else
      [] -> "Jogo \"#{nome}\" não encontrado."
      {:error, msg} -> "Erro ao buscar jogo: #{msg}"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # 4. !conv <valor> <origem> <destino> — dois ou mais parâmetros
  # API: ExchangeRate-API (gratuita, sem chave para endpoint open)
  # ──────────────────────────────────────────────────────────────────────────

  def conv(valor_str, origem, destino) do
    origem  = String.upcase(origem)
    destino = String.upcase(destino)

    with {valor, ""} <- Float.parse(valor_str),
         {:ok, body} <- get("https://open.er-api.com/v6/latest/#{origem}"),
         {:ok, data} <- Jason.decode(body),
         rate when not is_nil(rate) <- get_in(data, ["rates", destino]) do
      resultado = valor * rate
      resultado_fmt = :erlang.float_to_binary(resultado, decimals: 2)
      valor_fmt     = :erlang.float_to_binary(valor, decimals: 2)

      "#{valor_fmt} #{origem} = **#{resultado_fmt} #{destino}**"
    else
      :error         -> "Valor inválido. Use números, ex: `!conv 100 USD BRL`"
      nil            -> "Moeda \"#{destino}\" não encontrada."
      {:error, msg}  -> "Erro ao buscar câmbio: #{msg}"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # 5. !prevchuva <cidade> <dias> — dois ou mais parâmetros
  # API: Open-Meteo (gratuita, sem chave)
  # ──────────────────────────────────────────────────────────────────────────

  def prevchuva(cidade, dias_str) do
    with {dias, ""} <- Integer.parse(dias_str),
         dias <- min(dias, 7),
         {:ok, {lat, lon, nome}} <- geocode(cidade),
         {:ok, body} <- get("https://api.open-meteo.com/v1/forecast", query: [
           latitude: lat,
           longitude: lon,
           daily: "precipitation_sum,weathercode",
           forecast_days: dias,
           timezone: "auto"
         ]),
         {:ok, data} <- Jason.decode(body) do
      daily  = data["daily"]
      datas  = daily["time"]
      chuvas = daily["precipitation_sum"]

      previsoes =
        Enum.zip(datas, chuvas)
        |> Enum.map(fn {data, chuva} -> "#{data}: #{chuva} mm" end)
        |> Enum.join("\n")

      "**Previsão de chuva para #{nome} (#{dias} dias)**\n#{previsoes}"
    else
      :error        -> "Número de dias inválido. Ex: `!prevchuva Fortaleza 5`"
      {:error, msg} -> "Erro: #{msg}"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # 6. !lembrar <texto> — persistência JSON
  # !lembretes — lista os lembretes salvos
  # !esquece — limpa os lembretes
  # ──────────────────────────────────────────────────────────────────────────

  def lembrar(user_id, texto) do
    user_key = Integer.to_string(user_id)
    Store.add(user_key, texto)
    "Anotado! Use `!lembretes` para ver suas anotações."
  end

  def lembretes(user_id) do
    user_key = Integer.to_string(user_id)

    case Store.get(user_key) do
      [] ->
        "Você não tem lembretes salvos. Use `!lembrar <texto>` para adicionar."

      lista ->
        itens =
          lista
          |> Enum.with_index(1)
          |> Enum.map(fn {item, i} -> "#{i}. #{item}" end)
          |> Enum.join("\n")

        "**Seus lembretes:**\n#{itens}"
    end
  end

  def esquece(user_id) do
    user_key = Integer.to_string(user_id)
    Store.clear(user_key)
    "Lembretes apagados!"
  end

  # ──────────────────────────────────────────────────────────────────────────
  # 7. !curiosidade <cidade> — combinando duas APIs
  # API 1: Open-Meteo (busca clima da cidade)
  # API 2: Open-Meteo geocoding (pega país) + Wikipedia REST API (curiosidade)
  # ──────────────────────────────────────────────────────────────────────────

  def curiosidade(cidade) do
    with {:ok, {lat, lon, nome}} <- geocode(cidade),
         {:ok, body_clima} <- get("https://api.open-meteo.com/v1/forecast", query: [
           latitude: lat,
           longitude: lon,
           current: "temperature_2m,weathercode",
           timezone: "auto"
         ]),
         {:ok, clima_data} <- Jason.decode(body_clima),
         temp = get_in(clima_data, ["current", "temperature_2m"]),
         # 2ª API: Wikipedia summary da cidade
         cidade_enc = URI.encode(nome),
         {:ok, wiki_body} <- get("https://en.wikipedia.org/api/rest_v1/page/summary/#{cidade_enc}"),
         {:ok, wiki_data} <- Jason.decode(wiki_body),
         resumo = Map.get(wiki_data, "extract", "Sem informações disponíveis."),
         resumo_curto = resumo |> String.split(". ") |> Enum.take(2) |> Enum.join(". ") do
      """
      **#{nome}**
      Agora: #{temp}°C

      **Curiosidade:**
      #{resumo_curto}.
      """
    else
      {:error, msg} -> "Erro ao buscar curiosidade: #{msg}"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Funções privadas de suporte
  # ──────────────────────────────────────────────────────────────────────────

  defp geocode(cidade) do
    case get("https://geocoding-api.open-meteo.com/v1/search", query: [name: cidade, count: 1, language: "pt"]) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, %{"results" => [result | _]}} ->
            lat  = result["latitude"]
            lon  = result["longitude"]
            nome = result["name"]
            {:ok, {lat, lon, nome}}

          {:ok, _} ->
            {:error, "cidade \"#{cidade}\" não encontrada"}

          {:error, _} ->
            {:error, "erro ao decodificar resposta"}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp get(url, opts \\ []) do
    query = Keyword.get(opts, :query, [])

    full_url =
      if query == [] do
        url
      else
        params = URI.encode_query(query)
        "#{url}?#{params}"
      end

    case :httpc.request(:get, {String.to_charlist(full_url), []}, [], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        {:ok, List.to_string(body)}

      {:ok, {{_, status, _}, _, _}} ->
        {:error, "status HTTP #{status}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

end
