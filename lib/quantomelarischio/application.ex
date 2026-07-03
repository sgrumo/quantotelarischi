defmodule Quantomelarischio.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      QuantomelarischioWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:quantomelarischio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Quantomelarischio.PubSub},
      {Registry, keys: :unique, name: Quantomelarischio.RoomRegistry},
      {DynamicSupervisor, name: Quantomelarischio.RoomSupervisor, strategy: :one_for_one},
      QuantomelarischioWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Quantomelarischio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    QuantomelarischioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
