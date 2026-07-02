defmodule QuantomelarischioWeb.RoomLive do
  use QuantomelarischioWeb, :live_view

  alias Quantomelarischio.Rooms
  alias Quantomelarischio.Rooms.Room

  @impl true
  def mount(%{"room_id" => room_id}, session, socket) do
    user_id = session["user_id"]

    socket =
      assign(socket,
        room_id: room_id,
        user_id: user_id,
        amount: 2,
        pick: 1,
        page_title: "Stanza"
      )

    if connected?(socket) do
      Rooms.subscribe(room_id)

      case Rooms.join_room(room_id, user_id) do
        {:ok, room} -> {:ok, assign_room(socket, room)}
        {:error, :user_already_inside} -> load_or_redirect(socket, room_id)
        {:error, reason} -> {:ok, redirect_with_error(socket, reason)}
      end
    else
      # Dead render before the socket connects: show whatever exists, if anything.
      case Rooms.get_room(room_id) do
        {:ok, room} -> {:ok, assign_room(socket, room)}
        {:error, _} -> {:ok, assign(socket, room: nil, role: :spectator, phase: :loading)}
      end
    end
  end

  @impl true
  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign_room(socket, room)}
  end

  @impl true
  def handle_event("amount_inc", _params, socket) do
    {:noreply, update(socket, :amount, &(&1 + 1))}
  end

  def handle_event("amount_dec", _params, socket) do
    {:noreply, update(socket, :amount, &max(2, &1 - 1))}
  end

  def handle_event("lock_amount", _params, socket) do
    case Rooms.accept_challenge(socket.assigns.room_id, socket.assigns.amount) do
      {:ok, _amount} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Importo non valido (minimo 2).")}
    end
  end

  def handle_event("pick_inc", _params, socket) do
    max = max_pick(socket.assigns.room)
    {:noreply, update(socket, :pick, &min(max, &1 + 1))}
  end

  def handle_event("pick_dec", _params, socket) do
    {:noreply, update(socket, :pick, &max(1, &1 - 1))}
  end

  def handle_event("place_bet", _params, socket) do
    case Rooms.place_bet(socket.assigns.room_id, socket.assigns.user_id, socket.assigns.pick) do
      :ok -> {:noreply, socket}
      {:ok, _result} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Numero non valido.")}
    end
  end

  def handle_event("reset", _params, socket) do
    Rooms.reset_game(socket.assigns.room_id)
    {:noreply, assign(socket, amount: 2, pick: 1)}
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:room_id] && socket.assigns[:user_id] && connected?(socket) do
      Rooms.leave_room(socket.assigns.room_id, socket.assigns.user_id)
    end

    :ok
  end

  ## Rendering

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="room"
      class={[
        "flex flex-1 flex-col rounded-[22px] border-2 border-ink bg-white p-5 shadow-hard",
        @phase == :verdict && @room.status == "completed" && "animate-shake"
      ]}
    >
      <%= case @phase do %>
        <% :loading -> %>
          <.header_bar title="Stanza" />
          <div class="mt-6 text-center font-hand text-ink/60">Carico la stanza…</div>
        <% :lobby -> %>
          {lobby(assigns)}
        <% :set_amount -> %>
          {set_amount(assigns)}
        <% :betting -> %>
          {betting(assigns)}
        <% :verdict -> %>
          {verdict(assigns)}
      <% end %>
    </div>
    """
  end

  # Screen 03 — lobby: challenger waiting for a second player, shareable link.
  defp lobby(assigns) do
    ~H"""
    <.header_bar title={"Stanza ##{@room_id}"} />
    <.challenge text={@room.challenge_description} label="La tua sfida" />

    <p class="mt-3 font-hand text-sm text-ink/50">link condivisibile</p>
    <div class="mt-1 flex gap-2">
      <div class="flex-1 truncate rounded-lg border-2 border-ink/20 bg-paper px-3 py-2 font-hand text-sm text-ink/70">
        {share_url(@room_id)}
      </div>
      <button
        id="copy-link"
        type="button"
        phx-hook="CopyLink"
        data-clipboard={share_url(@room_id)}
        class="rounded-lg border-2 border-ink bg-white px-3 py-2 text-xs font-bold uppercase text-ink hover:bg-paper"
      >
        Copia
      </button>
    </div>

    <div class="mt-4 flex flex-col gap-2">
      <.slot_row label="P1 · TU" filled={true} />
      <.slot_row label="P2 · vuoto" filled={false} />
    </div>

    <div class="mt-auto flex items-center justify-center pt-6 text-center font-hand text-ink/60">
      "In attesa che un coglione abbocchi…"
    </div>
    """
  end

  # Screen 04 / 03b — challenged sets the pot; challenger waits.
  defp set_amount(%{role: :challenged} = assigns) do
    ~H"""
    <.header_bar title="Lo sfidato decide" />
    <.challenge text={@room.challenge_description} />

    <p class="mt-3 text-center font-hand text-ink/70">Quanto vale questa stronzata?</p>

    <div class="my-4 flex flex-1 items-center justify-center rounded-xl border-2 border-ink text-7xl font-extrabold text-ink">
      {@amount}
    </div>

    <div class="flex gap-2">
      <.button variant="ghost" phx-click="amount_dec" class="flex-1">−</.button>
      <.button phx-click="amount_inc" class="flex-1">+</.button>
    </div>
    <p class="mt-1 text-center font-hand text-sm text-ink/50">minimo 2</p>

    <.button phx-click="lock_amount" class="mt-3">Blocca l'importo</.button>
    """
  end

  defp set_amount(assigns) do
    ~H"""
    <.header_bar title={"Stanza ##{@room_id}"} />
    <.challenge text={@room.challenge_description} label="La tua sfida" />

    <div class="mt-4 flex flex-col gap-2">
      <.slot_row label="P1 · TU" filled={true} />
      <.slot_row label="P2 · L'IDIOTA" filled={true} />
    </div>

    <div class="mt-auto pt-6 text-center font-hand text-ink/60">
      ⏳<br /> "L'idiota sta decidendo quanto vali… aspetta, pezzo di merda."
    </div>
    """
  end

  # Screen 05 — pick a secret number from 1 to (pot − 1).
  defp betting(assigns) do
    assigns = assign(assigns, :placed, my_bet(assigns.room, assigns.role))

    ~H"""
    <.header_bar title="In segreto" />
    <.challenge text={@room.challenge_description} />

    <%= if @placed do %>
      <div class="mt-6 flex flex-1 flex-col items-center justify-center gap-3 text-center">
        <div class="text-2xl">🔒</div>
        <p class="font-hand text-ink/60">Numero bloccato. Aspetta l'altro coglione…</p>
      </div>
    <% else %>
      <p class="mt-3 text-center font-hand text-sm text-ink/60">
        un numero da 1 a {max_pick(@room)}
      </p>
      <div class="my-3 flex items-stretch gap-2">
        <.button variant="ghost" phx-click="pick_dec" class="flex !w-12 items-center justify-center !p-0 text-2xl">
          −
        </.button>
        <div class="flex flex-1 items-center justify-center rounded-xl border-2 border-ink py-4 text-5xl font-extrabold text-ink">
          {@pick}
        </div>
        <.button phx-click="pick_inc" class="flex !w-12 items-center justify-center !p-0 text-2xl">
          +
        </.button>
      </div>
      <.button phx-click="place_bet" class="mt-auto">Conferma il numero</.button>
    <% end %>
    """
  end

  # Screen 06 — verdict.
  defp verdict(assigns) do
    a = assigns.room.challenger_bet_amount
    b = assigns.room.challenged_bet_amount
    pot = assigns.room.challenge_amount

    assigns =
      assign(assigns,
        a: a,
        b: b,
        pot: pot,
        sum_hit: a + b == pot,
        equal_hit: a == b,
        must_do: assigns.room.status == "completed"
      )

    ~H"""
    <.header_bar title="Verdetto" />
    <.challenge text={@room.challenge_description} />

    <div class="mt-3 text-center">
      <span class="inline-block rounded-full border-2 border-ink px-3 py-1 text-xs font-bold uppercase text-ink">
        ① Posta: {@pot}
      </span>
    </div>

    <div class="mt-3 flex items-end gap-2">
      <div class="flex-1 text-center">
        <p class="mb-1 font-hand text-sm text-ink/60">② TU · sfidante</p>
        <div class="flex h-14 items-center justify-center rounded-xl border-2 border-ink text-2xl font-extrabold">
          {@a}
        </div>
      </div>
      <div class="pb-4 text-xl font-extrabold">+</div>
      <div class="flex-1 text-center">
        <p class="mb-1 font-hand text-sm text-ink/60">③ IDIOTA · sfidato</p>
        <div class="flex h-14 items-center justify-center rounded-xl border-2 border-ink text-2xl font-extrabold">
          {@b}
        </div>
      </div>
    </div>

    <div class="mt-3 flex flex-col gap-2">
      <.check_row hit={@sum_hit} label={"④ Somma · #{@a} + #{@b} = #{@a + @b}"} target={"= #{@pot}"} />
      <.check_row hit={@equal_hit} label={"⑤ Uguali? · #{@a}"} target={"= #{@b}"} />
    </div>

    <div class={[
      "mt-4 rounded-md px-3 py-3 text-center text-lg font-extrabold uppercase tracking-tight text-white",
      @must_do && "bg-accent",
      !@must_do && "bg-ink"
    ]}>
      {if @must_do, do: "Devi farlo", else: "Te la sei scampata"}
    </div>

    <.button variant="ghost" phx-click="reset" class="mt-auto">Rigioca</.button>
    """
  end

  ## Small shared pieces

  attr :title, :string, required: true

  defp header_bar(assigns) do
    ~H"""
    <div class="rounded-md bg-ink px-3 py-2 text-center text-base font-extrabold uppercase tracking-tight text-white">
      {@title}
    </div>
    """
  end

  attr :text, :string, required: true
  attr :label, :string, default: "La sfida"

  defp challenge(assigns) do
    ~H"""
    <div class="mt-3 rounded-lg border-2 border-dashed border-ink/25 bg-paper px-3 py-2 text-center">
      <p class="text-[10px] font-bold uppercase tracking-wide text-accent">{@label}</p>
      <p class="font-hand text-sm text-ink/70">{@text}</p>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :filled, :boolean, required: true

  defp slot_row(assigns) do
    ~H"""
    <div class={[
      "flex items-center gap-2 rounded-lg border-2 px-3 py-2 text-xs font-bold uppercase",
      @filled && "border-accent text-ink",
      !@filled && "border-dashed border-ink/30 text-ink/40"
    ]}>
      {@label}
      <span class="ml-auto">{if @filled, do: "●", else: "○"}</span>
    </div>
    """
  end

  attr :hit, :boolean, required: true
  attr :label, :string, required: true
  attr :target, :string, required: true

  defp check_row(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-between rounded-lg border-2 px-3 py-2 text-sm font-bold",
      @hit && "border-accent text-accent",
      !@hit && "border-ink/20 text-ink/50"
    ]}>
      <span>{@label} {@target}</span>
      <span>{if @hit, do: "✓", else: "✗"}</span>
    </div>
    """
  end

  ## Helpers

  defp assign_room(socket, %Room{} = room) do
    pick =
      if room.challenge_amount,
        do: min(socket.assigns[:pick] || 1, max(1, room.challenge_amount - 1)),
        else: socket.assigns[:pick] || 1

    assign(socket,
      room: room,
      role: role(room, socket.assigns.user_id),
      phase: phase(room),
      pick: pick
    )
  end

  defp load_or_redirect(socket, room_id) do
    case Rooms.get_room(room_id) do
      {:ok, room} -> {:ok, assign_room(socket, room)}
      {:error, reason} -> {:ok, redirect_with_error(socket, reason)}
    end
  end

  defp redirect_with_error(socket, reason) do
    socket
    |> put_flash(:error, error_message(reason))
    |> push_navigate(to: ~p"/")
  end

  defp error_message(:room_full), do: "La stanza è piena. Due idioti bastano."
  defp error_message(:room_not_found), do: "Stanza non trovata o scaduta."
  defp error_message(_), do: "Qualcosa è andato storto."

  defp role(%Room{challenger_id: id}, id), do: :challenger
  defp role(%Room{challenged_id: id}, id), do: :challenged
  defp role(_room, _user_id), do: :spectator

  defp phase(%Room{status: status}) when status != nil, do: :verdict
  defp phase(%Room{challenge_amount: amount}) when amount != nil, do: :betting

  defp phase(%Room{challenger_id: c, challenged_id: d}) when c != nil and d != nil,
    do: :set_amount

  defp phase(_room), do: :lobby

  defp my_bet(%Room{challenger_bet_amount: amount}, :challenger), do: amount
  defp my_bet(%Room{challenged_bet_amount: amount}, :challenged), do: amount
  defp my_bet(_room, _role), do: nil

  defp max_pick(%Room{challenge_amount: nil}), do: 1
  defp max_pick(%Room{challenge_amount: amount}), do: max(1, amount - 1)

  defp share_url(room_id), do: url(~p"/r/#{room_id}")
end
