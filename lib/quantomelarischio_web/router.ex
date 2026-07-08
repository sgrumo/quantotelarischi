defmodule QuantomelarischioWeb.Router do
  use QuantomelarischioWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_user_id
    plug :fetch_live_flash
    plug :put_root_layout, html: {QuantomelarischioWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Guards the LiveDashboard. In prod, credentials come from config
  # (:dashboard_auth, set in runtime.exs from env vars) and are required;
  # in dev, no credentials are configured so the dashboard stays open.
  pipeline :dashboard do
    plug :fetch_session
    plug :protect_from_forgery
    plug :dashboard_auth
  end

  scope "/", QuantomelarischioWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/new", NewChallengeLive
    live "/r/:room_id", RoomLive
  end

  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :dashboard

    live_dashboard "/dashboard", metrics: QuantomelarischioWeb.Telemetry
  end

  # Assigns a stable, anonymous per-browser id used to claim a player slot in a room.
  defp put_user_id(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      put_session(conn, :user_id, generate_user_id())
    end
  end

  defp generate_user_id do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
  end

  # Requires HTTP basic auth for the dashboard when credentials are configured
  # (prod). When none are set (dev), the request passes through untouched.
  defp dashboard_auth(conn, _opts) do
    case Application.get_env(:quantomelarischio, :dashboard_auth) do
      [username: username, password: password]
      when is_binary(username) and is_binary(password) ->
        Plug.BasicAuth.basic_auth(conn, username: username, password: password)

      _ ->
        conn
    end
  end
end
