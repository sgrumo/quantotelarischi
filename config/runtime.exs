import Config

# Executed at boot in every environment, releases included — compile-time
# configuration set here won't be applied.

# Releases must opt into serving requests via PHX_SERVER=true.
if System.get_env("PHX_SERVER") do
  config :quantomelarischio, QuantomelarischioWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  dns_cluster_query = System.get_env("DNS_CLUSTER_QUERY")

  config :quantomelarischio,
         :dns_cluster_query,
         if(dns_cluster_query != "", do: dns_cluster_query)

  config :quantomelarischio, QuantomelarischioWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # IPv6 wildcard: binds every interface, IPv4 included.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
