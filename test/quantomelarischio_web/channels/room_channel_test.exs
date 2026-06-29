defmodule QuantomelarischioWeb.RoomChannelTest do
  use QuantomelarischioWeb.ChannelCase

  alias Quantomelarischio.Rooms

  setup do
    {:ok, room_id} = Rooms.create_room("guess the number")

    {:ok, reply, socket} =
      QuantomelarischioWeb.UserSocket
      |> socket("user_1", %{user_id: "user_1"})
      |> subscribe_and_join(QuantomelarischioWeb.RoomChannel, "room:#{room_id}")

    %{socket: socket, room_id: room_id, reply: reply}
  end

  test "join replies with the room info and the user id", %{reply: reply} do
    assert %{roomInfo: %Quantomelarischio.Rooms.Room{}, userId: "user_1"} = reply
  end

  test "send_challenge broadcasts the challenge to the room", %{socket: socket} do
    ref = push(socket, "send_challenge", %{"challenge_description" => "do a backflip"})
    assert_reply ref, :ok
    assert_broadcast "challenge_received", %{challenge_description: "do a backflip"}
  end

  test "accept_challenge broadcasts the accepted amount", %{socket: socket} do
    ref = push(socket, "accept_challenge", %{"amount" => 100})
    assert_reply ref, :ok
    assert_broadcast "challenge_accepted", %{amount: 100}
  end

  test "place_bet rejects an amount not below the challenge", %{socket: socket} do
    push(socket, "accept_challenge", %{"amount" => 100})
    ref = push(socket, "place_bet", %{"amount" => 100})
    assert_reply ref, :error, %{reason: :invalid_bet_amount}
  end

  test "place_bet is rejected before a challenge is accepted", %{socket: socket} do
    ref = push(socket, "place_bet", %{"amount" => 50})
    assert_reply ref, :error, %{reason: :challenge_not_accepted}
  end
end
