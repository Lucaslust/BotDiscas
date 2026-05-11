import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: :all

config :tesla, adapter: Tesla.Adapter.Hackney
