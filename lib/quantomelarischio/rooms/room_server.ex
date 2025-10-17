defmodule Quantomelarischio.Rooms.RoomServer do
  use GenServer
  alias Quantomelarischio.Rooms.Room

  def start_link(%{room_id: room_id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(room_id))
  end

  def join(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:join, user_id})
  end

  def leave(room_id, user_id) do
    GenServer.cast(via_tuple(room_id), {:leave, user_id})
  end

  def send_challenge(room_id, challenge_description) do
    GenServer.call(via_tuple(room_id), {:send_challenge, challenge_description})
  end

  def accept_challenge(room_id, user_id, challenge_amount) do
    GenServer.call(via_tuple(room_id), {:accept_challenge, user_id, challenge_amount})
  end

  def decline_challenge(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:decline_challenge, user_id})
  end

  def place_bet(room_id, user_id, bet_amount) do
    GenServer.call(via_tuple(room_id), {:place_bet, user_id, bet_amount})
  end

  def forfeit_bet(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:forfeit_bet, user_id})
  end

  def shutdown(room_id) do
    GenServer.cast(via_tuple(room_id), :shutdown)
  end

  def get_info(room_id) do
    GenServer.cast(via_tuple(room_id), :get_info)
  end

  def reset_game(room_id) do
    GenServer.call(via_tuple(room_id), :reset_game)
  end

  @impl true
  def init(%{room_id: room_id, challenge_description: challenge_description} = _params) do
    state = Room.new(room_id, challenge_description)
    {:ok, state}
  end

  @impl true
  def handle_call(
        {:join, user_id},
        _from,
        state
      ) do
    case Room.join(user_id, state) do
      {:error, reason} -> {:error, reason}
      {:ok, new_state} -> {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call({:send_challenge, challenge_description}, _from, state) do
    new_state = %{state | challenge_description: challenge_description}

    {:reply, {:ok, challenge_description}, new_state}
  end

  @impl true
  def handle_call({:accept_challenge, challenge_amount}, _from, state) do
    case Room.accept_challenge(challenge_amount, state) do
      {:error, reason} -> {:error, reason}
      {:ok, new_state} -> {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:decline_challenge}, _from, state) do
    {:reply, {:ok, :declined}, state}
  end

  @impl true
  def handle_call(
        {:forfeit_bet, user_id},
        _from,
        %{
          challenged_id: challenged_id,
          challenger_id: challenger_id
        } = state
      ) do
    new_state =
      case {user_id, challenger_id, challenged_id} do
        {id, id, _} -> %{state | challenger_id: nil}
        {id, _id, id} -> %{state | challenged_id: nil}
        _ -> state
      end

    {:reply, {:ok, {:user_has_forfeited}}, new_state}
  end

  @impl true
  def handle_call(
        {:place_bet, user_id, amount},
        _from,
        state
      ) do
    case Room.place_bet(user_id, amount, state) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok,
       %{
         status: status,
         challenger_amount: challenger_bet_amount,
         challenged_amount: challenged_bet_amount
       } = state}
      when status != nil ->
        {:reply,
         {:ok,
          %{
            status: status,
            challenger_bet_amount: challenger_bet_amount,
            challenged_bet_amount: challenged_bet_amount
          }}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:reset_game, _from, state) do
    new_state = Room.reset_game(state)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast(
        {:leave, user_id},
        state
      ) do
    {:ok, new_state} = Room.leave(user_id, state)

    if new_state.challenged_id == nil and new_state.challenger_id == nil do
      Process.send_after(self(), :shutdown_if_empty, 30_000)
    end

    {:noreply, new_state}
  end

  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:shutdown_if_empty, %{users: []} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:shutdown_if_empty, state) do
    {:noreply, state}
  end

  defp via_tuple(room_id) do
    {:via, Registry, {Quantomelarischio.RoomRegistry, room_id}}
  end
end
