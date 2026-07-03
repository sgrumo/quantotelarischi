defmodule QuantomelarischioWeb.RoomLiveTest do
  use QuantomelarischioWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Quantomelarischio.Rooms

  defp player_conn(user_id) do
    Phoenix.ConnTest.build_conn()
    |> Plug.Test.init_test_session(%{user_id: user_id})
  end

  describe "HomeLive" do
    test "renders the landing and links to room creation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Quanto te la rischi"
      assert html =~ "Regole"
      assert html =~ ~p"/new"
    end
  end

  describe "NewChallengeLive" do
    test "creates a room and navigates to it", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      {:error, {:live_redirect, %{to: to}}} =
        view
        |> form("form", %{"challenge_description" => "mungere una mucca"})
        |> render_submit()

      assert to =~ ~r"^/r/"
    end

    test "rejects an empty challenge", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      html =
        view
        |> form("form", %{"challenge_description" => "   "})
        |> render_submit()

      assert html =~ "Scrivi prima una stronzata"
    end
  end

  describe "RoomLive full flow" do
    setup do
      {:ok, room_id} = Rooms.create_room("mungere una mucca")
      %{room_id: room_id}
    end

    test "two players play through to a verdict", %{room_id: room_id} do
      {:ok, p1, _} = live(player_conn("p1"), ~p"/r/#{room_id}")
      assert render(p1) =~ "In attesa che un coglione"

      # P2 joins → challenged sets the amount, challenger waits.
      {:ok, p2, _} = live(player_conn("p2"), ~p"/r/#{room_id}")
      assert render(p2) =~ "Quanto vale questa stronzata"
      assert render(p1) =~ "sta decidendo quanto vali"

      # P2 locks the pot at 2 (submitting the form → Enter works the same way).
      p2 |> form("#amount-form", %{"amount" => "2"}) |> render_submit()
      assert render(p1) =~ "Un numero da 1 a 1"
      assert render(p2) =~ "Un numero da 1 a 1"

      # Both bet 1 → sum (2) == pot (2) → the challenge is won.
      p1 |> form("#pick-form", %{"pick" => "1"}) |> render_submit()
      assert render(p1) =~ "Aspettando lo sfidato"
      p2 |> form("#pick-form", %{"pick" => "1"}) |> render_submit()

      assert render(p1) =~ "LO DEVE FARE"
      assert render(p2) =~ "ORA LO FAI"

      # Rigioca closes the room and sends both players back home.
      render_click(p1, "reset")
      assert_redirect(p1, "/")
      assert_redirect(p2, "/")
      assert {:error, :room_not_found} = Rooms.get_room(room_id)
    end

    test "a third visitor is bounced from a full room", %{room_id: room_id} do
      {:ok, _p1, _} = live(player_conn("p1"), ~p"/r/#{room_id}")
      {:ok, _p2, _} = live(player_conn("p2"), ~p"/r/#{room_id}")

      assert {:error, {:live_redirect, %{to: "/"}}} =
               live(player_conn("p3"), ~p"/r/#{room_id}")
    end

    test "an unknown room redirects home", %{conn: _conn} do
      assert {:error, {:live_redirect, %{to: "/"}}} =
               live(player_conn("p1"), ~p"/r/nonexistent")
    end
  end
end
