defmodule Quantomelarischio.Rooms.Room do
  alias __MODULE__

  @derive {Jason.Encoder,
           only: [
             :room_id,
             :challenge_amount,
             :challenger_id,
             :challenged_id,
             :status,
             :challenger_bet_amount,
             :challenged_bet_amount,
             :challenge_description,
             :created_at
           ]}

  defstruct [
    :room_id,
    :challenge_amount,
    :challenger_id,
    :challenged_id,
    :status,
    :challenger_bet_amount,
    :challenged_bet_amount,
    :challenge_description,
    :created_at
  ]

  @opaque t :: %Room{
            room_id: String.t(),
            challenge_amount: pos_integer() | nil,
            challenger_id: String.t() | nil,
            challenged_id: String.t() | nil,
            status: String.t() | nil,
            challenger_bet_amount: pos_integer() | nil,
            challenged_bet_amount: pos_integer() | nil,
            challenge_description: String.t() | nil,
            created_at: Datetime.t()
          }

  @type error_reason ::
          :user_already_inside | :room_full | :invalid_bet_amount | :invalid_challenge_bet_amount
  @type error :: {:error, error_reason()}
  @type ok_response :: {:ok, t()}
  @type response :: error() | ok_response()

  @spec new(String.t(), String.t()) :: t()
  def new(room_id, challenge_description) do
    %Room{
      room_id: room_id,
      challenge_amount: nil,
      challenger_id: nil,
      challenged_id: nil,
      status: nil,
      challenger_bet_amount: nil,
      challenged_bet_amount: nil,
      challenge_description: challenge_description,
      created_at: DateTime.utc_now()
    }
  end

  @spec join(String.t(), t()) :: error()
  def join(user_id, %{challenger_id: challenger_id, challenged_id: challenged_id} = _state)
      when challenged_id == user_id or challenger_id == user_id do
    {:error, :user_already_inside}
  end

  @spec join(String.t(), t()) :: error()
  def join(_user_id, %{challenger_id: challenger_id, challenged_id: challenged_id} = _state)
      when challenged_id != nil and challenger_id != nil do
    {:error, :room_full}
  end

  @spec join(String.t(), t()) :: response()
  def join(user_id, %{challenger_id: challenger_id, challenged_id: challenged_id} = state) do
    new_state =
      case {challenger_id, challenged_id} do
        {nil, _} -> %{state | challenger_id: user_id}
        {_, nil} -> %{state | challenged_id: user_id}
      end

    {:ok, new_state}
  end

  @spec accept_challenge(pos_integer(), t()) :: error()
  def accept_challenge(challenge_amount, _state) when challenge_amount < 1 do
    {:error, :invalid_challenge_bet_amount}
  end

  @spec accept_challenge(pos_integer(), t()) :: ok_response()
  def accept_challenge(challenge_amount, state) do
    {:ok, %{state | challenge_amount: challenge_amount}}
  end

  @spec place_bet(String.t(), pos_integer(), t()) :: error()
  def place_bet(
        _user_id,
        amount,
        %{
          challenge_amount: challenge_amount
        } = _state
      )
      when amount >= challenge_amount or amount < 1 do
    {:error, :invalid_bet_amount}
  end

  @spec place_bet(String.t(), pos_integer(), t()) :: ok_response()
  def place_bet(
        user_id,
        amount,
        %{
          challenge_amount: challenge_amount,
          challenged_id: challenged_id,
          challenger_id: challenger_id
        } = state
      ) do
    new_state =
      case user_id do
        ^challenger_id -> %{state | challenger_bet_amount: amount}
        ^challenged_id -> %{state | challenged_bet_amount: amount}
        _ -> state
      end

    case {new_state.challenger_bet_amount, new_state.challenged_bet_amount} do
      {nil, _} ->
        {:ok, new_state}

      {_, nil} ->
        {:ok, new_state}

      {challenger_amount, challenged_amount} ->
        total_bet = challenger_amount + challenged_amount

        cond do
          total_bet == challenge_amount ->
            {:ok, %{new_state | status: "completed"}}

          challenger_amount == challenged_amount ->
            {:ok, %{new_state | status: "completed"}}

          true ->
            {:ok, %{new_state | status: "not_completed"}}
        end
    end
  end

  @spec reset_game(t()) :: ok_response()
  def reset_game(
        %{
          room_id: room_id,
          created_at: created_at,
          challenger_id: challenger_id,
          challenged_id: challenged_id
        } = _state
      ) do
    new_state = %Room{
      room_id: room_id,
      challenge_amount: nil,
      challenger_id: challenger_id,
      challenged_id: challenged_id,
      status: nil,
      challenger_bet_amount: nil,
      challenged_bet_amount: nil,
      challenge_description: nil,
      created_at: created_at
    }

    {:ok, new_state}
  end

  @spec leave(String.t(), t()) :: ok_response()
  def leave(user_id, %{challenger_id: challenger_id, challenged_id: challenged_id} = state) do
    new_state =
      case {user_id, challenger_id, challenged_id} do
        {id, id, _} -> %{state | challenger_id: nil}
        {id, _id, id} -> %{state | challenged_id: nil}
        _ -> state
      end

    {:ok, new_state}
  end
end
