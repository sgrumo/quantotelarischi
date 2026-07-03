import Config

config :quantomelarischio, QuantomelarischioWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ieucY/60vTdEeppfnii+2TVMQXYyuLHCChV17YdsPpLOOCXryf+zEvrx/YH684Oi",
  server: false

config :logger, level: :warning

# Initialize plugs at runtime for faster compilation.
config :phoenix, :plug_init_mode, :runtime
