defmodule Quantomelarischio.Rooms do
  alias Quantomelarischio.Rooms.RoomServer

  @pubsub Quantomelarischio.PubSub

  @doc "Subscribe the calling process to a room's state-change broadcasts."
  def subscribe(room_id) do
    Phoenix.PubSub.subscribe(@pubsub, RoomServer.topic(room_id))
  end

  @doc "Fetch the current room state. Returns {:error, :room_not_found} if absent."
  def get_room(room_id) do
    RoomServer.get_room(room_id)
  catch
    :exit, _ -> {:error, :room_not_found}
  end

  def create_room(challenge_description) do
    room_id = generate_room_id()

    case DynamicSupervisor.start_child(
           Quantomelarischio.RoomSupervisor,
           {RoomServer, %{room_id: room_id, challenge_description: challenge_description}}
         ) do
      {:ok, _pid} -> {:ok, room_id}
      {:error, {:already_started, _pid}} -> {:ok, room_id}
      error -> error
    end
  end

  def join_room(room_id, user_id) do
    RoomServer.join(room_id, user_id)
  catch
    :exit, _ -> {:error, :room_not_found}
  end

  def leave_room(room_id, user_id) do
    RoomServer.leave(room_id, user_id)
  end

  def send_challenge(room_id, challenge_description) do
    RoomServer.send_challenge(room_id, challenge_description)
  end

  def accept_challenge(room_id, challenge_amount) do
    case RoomServer.accept_challenge(room_id, challenge_amount) do
      :ok -> {:ok, challenge_amount}
      {:error, reason} -> {:error, reason}
    end
  end

  def place_bet(room_id, user_id, bet_amount) do
    case RoomServer.place_bet(room_id, user_id, bet_amount) do
      :ok -> :ok
      {:ok, bet} -> {:ok, bet}
      {:error, reason} -> {:error, reason}
    end
  end

  def decline_challenge(room_id, user_id) do
    case RoomServer.decline_challenge(room_id, user_id) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  def forfeit_bet(room_id, user_id) do
    case RoomServer.forfeit_bet(room_id, user_id) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  def reset_game(room_id) do
    case RoomServer.reset_game(room_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Close the room for everyone. Subscribers receive {:room_closed, room_id}."
  def close_room(room_id) do
    RoomServer.close(room_id)
  catch
    :exit, _ -> :ok
  end

  def list_active_rooms() do
    Quantomelarischio.RoomSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->
      case GenServer.call(pid, :get_room_id, 5000) do
        {:ok, room_id} -> room_id
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def get_room_count() do
    Quantomelarischio.RoomSupervisor
    |> DynamicSupervisor.count_children()
    |> Map.get(:active, 0)
  end

  @doc """
  Emit periodic usage telemetry. Called by the telemetry poller so the
  LiveDashboard shows a live gauge of how many rooms are currently alive.
  """
  def dispatch_stats() do
    # The poller's first tick can fire before RoomSupervisor is up (Telemetry
    # starts first in the supervision tree), so guard against :noproc.
    if Process.whereis(Quantomelarischio.RoomSupervisor) do
      :telemetry.execute([:quantomelarischio, :rooms], %{active: get_room_count()}, %{})
    end

    :ok
  end

  defp generate_room_id() do
    :crypto.strong_rand_bytes(6) |> Base.encode32(case: :lower, padding: false)
  end

  def broadcast_to_user(user_id, event, payload) do
    QuantomelarischioWeb.Endpoint.broadcast("user_socket:#{user_id}", event, payload)
  end
end
