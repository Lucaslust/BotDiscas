# MeuBot — Discord Bot em Elixir

Bot para Discord desenvolvido com Elixir + Nostrum, implementando 7 comandos funcionais.

## Pré-requisitos

- Elixir >= 1.14
- Token do bot Discord
- (Opcional) Chave da API RAWG para o comando `!jogo`

## Configuração

```bash
# Clone o repositório
git clone <url-do-repo>
cd meu_bot

# Configure as variáveis de ambiente
export DISCORD_TOKEN="seu_token_aqui"
export RAWG_API_KEY="sua_chave_rawg_aqui"  # opcional mas recomendado

# Instale dependências
mix deps.get

# Rode o bot
mix run --no-halt
```

## Comandos

| Comando | Tipo | Descrição |
|---|---|---|
| `!ping` | Sem parâmetro | Verifica se o bot está online |
| `!clima <cidade>` | 1 parâmetro | Clima atual via Open-Meteo |
| `!jogo <nome>` | 1 parâmetro | Info de jogo via RAWG API |
| `!conv <valor> <origem> <destino>` | 2+ parâmetros | Conversão de moedas |
| `!prevchuva <cidade> <dias>` | 2+ parâmetros | Previsão de chuva (max 7 dias) |
| `!lembrar <texto>` | Persistência JSON | Salva lembrete por usuário |
| `!lembretes` | Persistência JSON | Lista lembretes salvos |
| `!esquece` | Persistência JSON | Apaga lembretes |
| `!curiosidade <cidade>` | Combinando 2 APIs | Clima + curiosidade via Wikipedia |
| `!ajuda` | - | Lista todos os comandos |

## APIs utilizadas

- **Open-Meteo** — clima e previsão (gratuita, sem chave)
- **Open-Meteo Geocoding** — conversão cidade → coordenadas (gratuita)
- **RAWG** — banco de dados de jogos (gratuita com chave)
- **ExchangeRate-API** — câmbio de moedas (gratuita, sem chave)
- **Wikipedia REST API** — resumos de cidades (gratuita, sem chave)

## Arquitetura

```
lib/
├── meu_bot.ex                  # Application + Supervisor principal
└── meu_bot/
    ├── consumer.ex             # Handler de eventos, despacho via pattern matching
    ├── commands.ex             # Implementação de cada comando
    └── store.ex                # GenServer de persistência JSON
```

### Decisões de implementação

- **GenServer no Store**: mantém os lembretes em memória entre chamadas, sem estado mutável global. O estado é passado explicitamente entre callbacks.
- **Pattern matching no Consumer**: cada cláusula de `dispatch/2` corresponde a um prefixo de comando — sem if/else, idiomático em Elixir.
- **Funções puras em Commands**: cada comando recebe parâmetros e retorna uma string — sem efeitos colaterais além do `Store`.
- **httpc nativo**: usa o cliente HTTP do próprio Erlang/OTP para não depender de libs extras além do Nostrum e Jason.

## Persistência

Os lembretes são salvos em `lembretes.json` no diretório de execução, indexados pelo ID do usuário Discord. O arquivo é lido ao iniciar o bot via `Store.init/1`.
