import Config

config :quantomelarischio, QuantomelarischioWeb.Endpoint,
  # Loopback only; `ip: {0, 0, 0, 0}` would expose the dev server to the network.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Ffk55onvNVxo5gkbLdasWD70xVYqZ/BJrYs5eVmOjVBwXCEr1l7vLFK14wBYshef",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:quantomelarischio, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:quantomelarischio, ~w(--watch)]}
  ]

config :quantomelarischio, QuantomelarischioWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/quantomelarischio_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :quantomelarischio, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

# Keep dev-only: building large stacktraces is expensive in production.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster compilation.
config :phoenix, :plug_init_mode, :runtime
