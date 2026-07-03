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

  scope "/", QuantomelarischioWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/new", NewChallengeLive
    live "/r/:room_id", RoomLive
  end

  if Application.compile_env(:quantomelarischio, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: QuantomelarischioWeb.Telemetry
    end
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
end
