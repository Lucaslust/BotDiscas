import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: [
    :guilds,
    :guild_messages,
    :message_content,
    :direct_messages
  ]

config :tesla, adapter: Tesla.Adapter.Hackney
