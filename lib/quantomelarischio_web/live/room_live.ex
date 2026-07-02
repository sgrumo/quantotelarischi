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
      case Rooms.get_room(room_id) do
        {:ok, room} ->
          {:ok, assign_room(socket, room)}

        {:error, _} ->
          {:ok, assign(socket, room: nil, role: :spectator, phase: :loading, nav_step: 2)}
      end
    end
  end

  @impl true
  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign_room(socket, room)}
  end

  @impl true
  def handle_event("amount_change", %{"amount" => amount}, socket) do
    {:noreply, assign(socket, :amount, parse_int(amount, socket.assigns.amount))}
  end

  def handle_event("lock_amount", %{"amount" => amount}, socket) do
    case Rooms.accept_challenge(socket.assigns.room_id, parse_int(amount, 0)) do
      {:ok, _amount} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Importo non valido (minimo 2).")}
    end
  end

  def handle_event("pick_change", %{"pick" => pick}, socket) do
    {:noreply, assign(socket, :pick, parse_int(pick, socket.assigns.pick))}
  end

  def handle_event("place_bet", %{"pick" => pick}, socket) do
    case Rooms.place_bet(socket.assigns.room_id, socket.assigns.user_id, parse_int(pick, 0)) do
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
    <div class="animate-rise mx-auto max-w-2xl">
      <%= case @phase do %>
        <% :loading -> %>
          <div class="rounded-3xl border border-line bg-white p-8 text-center text-xl text-muted shadow-card">
            <i class="ri-loader-4-line animate-spin-slow text-4xl text-brand"></i>
            <p class="mt-4">Carico la stanza…</p>
          </div>
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

  # Screen 2 — lobby: challenger waiting for a second player.
  defp lobby(assigns) do
    ~H"""
    <.room_header room_id={@room_id} />
    <div class="rounded-3xl border border-line bg-white p-6 shadow-card sm:p-8">
      <.challenge_box text={@room.challenge_description} label="La tua sfida" />

      <div class="mb-2 text-base text-muted">Link condivisibile</div>
      <div class="mb-6 flex gap-2.5">
        <div class="flex min-w-0 flex-1 items-center overflow-hidden text-ellipsis whitespace-nowrap rounded-full border border-line2 bg-paper px-5 py-3.5 text-base text-muted2">
          {share_url(@room_id)}
        </div>
        <button
          id="copy-link"
          type="button"
          phx-hook="CopyLink"
          data-clipboard={share_url(@room_id)}
          aria-label="Copia il link della stanza"
          class="flex flex-none items-center gap-2 rounded-full bg-ink px-6 text-base font-semibold text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-brand/30"
        >
          <i class="ri-file-copy-line text-lg"></i>Copia
        </button>
      </div>

      <div class="flex flex-col gap-3">
        <.player_slot name="Tu · lo sfidante" state="in" />
        <.player_slot name="In attesa dell'idiota" state="empty" />
      </div>

      <p class="mt-6 text-center text-lg italic text-muted">
        "In attesa che un coglione abbocchi…"
      </p>
    </div>
    """
  end

  # Screen 4 (challenged) / screen 3 (challenger waiting) — set the pot.
  defp set_amount(%{role: :challenged} = assigns) do
    ~H"""
    <div class="mb-3 text-sm font-semibold uppercase tracking-widest text-muted">
      Lo sfidato decide
    </div>
    <.challenge_box text={@room.challenge_description} />
    <h2 class="mb-8 font-display text-[clamp(34px,7vw,56px)] font-bold leading-[1.05] tracking-tight text-ink">
      Quanto vale questa stronzata?
    </h2>

    <form id="amount-form" phx-submit="lock_amount" phx-change="amount_change">
      <label for="amount" class="sr-only">Importo della posta (minimo 2)</label>
      <input
        id="amount"
        type="number"
        name="amount"
        value={@amount}
        min="2"
        inputmode="numeric"
        autocomplete="off"
        class="no-spin w-full rounded-3xl border border-line2 bg-white py-7 text-center font-display text-[clamp(72px,20vw,120px)] font-extrabold leading-none text-ink focus:border-brand focus:outline-none focus:ring-4 focus:ring-brand/15"
      />
      <p class="mb-8 mt-4 text-center text-base text-muted">Importo minimo: 2 · premi Invio per bloccare</p>
      <.button type="submit">
        Blocca l'importo <i class="ri-lock-line text-2xl"></i>
      </.button>
    </form>
    """
  end

  defp set_amount(assigns) do
    ~H"""
    <.room_header room_id={@room_id} />
    <div class="rounded-3xl border border-line bg-white p-6 shadow-card sm:p-8">
      <.challenge_box text={@room.challenge_description} label="La tua sfida" />
      <div class="flex flex-col gap-3">
        <.player_slot name="Tu · lo sfidante" state="in" />
        <.player_slot name="L'idiota · lo sfidato" state="in" />
      </div>
      <div class="mt-7 text-center">
        <i class="ri-loader-4-line animate-spin-slow text-4xl text-brand"></i>
        <p class="mt-4 text-lg leading-snug text-muted">
          "L'idiota sta decidendo quanto vali… aspetta, pezzo di merda."
        </p>
      </div>
    </div>
    """
  end

  # Screen 5 — pick a secret number from 1 to (pot − 1).
  defp betting(assigns) do
    assigns = assign(assigns, :placed, my_bet(assigns.room, assigns.role))

    ~H"""
    <%= if @placed do %>
      <div class="rounded-3xl border border-line bg-white p-8 text-center shadow-card">
        <i class="ri-lock-2-line text-4xl text-brand"></i>
        <p class="mt-4 text-lg leading-snug text-muted">
          Numero bloccato. Aspetta l'altro coglione…
        </p>
      </div>
    <% else %>
      <div class="mb-3 flex items-center gap-2 text-sm font-semibold uppercase tracking-widest text-muted">
        <i class="ri-eye-off-line text-base"></i>In segreto
      </div>
      <.challenge_box text={@room.challenge_description} />
      <h2 class="mb-2 font-display text-[clamp(34px,7vw,56px)] font-bold leading-[1.05] tracking-tight text-ink">
        Scegli il tuo numero
      </h2>
      <p class="mb-8 text-xl text-muted">
        Un numero da 1 a {max_pick(@room)}. Non farti fregare.
      </p>

      <form id="pick-form" phx-submit="place_bet" phx-change="pick_change">
        <label for="pick" class="sr-only">Il tuo numero segreto</label>
        <input
          id="pick"
          type="number"
          name="pick"
          value={@pick}
          min="1"
          max={max_pick(@room)}
          inputmode="numeric"
          autocomplete="off"
          class="no-spin w-full rounded-3xl border border-line2 bg-white py-7 text-center font-display text-[clamp(72px,20vw,120px)] font-extrabold leading-none text-brand focus:border-brand focus:outline-none focus:ring-4 focus:ring-brand/15"
        />
        <.button type="submit" class="mt-8">
          Conferma il numero <i class="ri-check-line text-2xl"></i>
        </.button>
      </form>
    <% end %>
    """
  end

  # Screen 6 — verdict.
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
    <div class="text-center text-sm font-semibold uppercase tracking-widest text-muted">
      Il verdetto
    </div>
    <div :if={@must_do} class="red-flash"></div>
    <div
      id="verdict-card"
      phx-hook="Verdict"
      data-mustdo={to_string(@must_do)}
      class={[
        "mt-3 rounded-3xl border border-line bg-white p-6 shadow-verdict sm:p-8",
        @must_do && "animate-shake"
      ]}
    >
      <.challenge_box text={@room.challenge_description} center={true} />

      <div class="mb-5 flex justify-center">
        <span class="inline-flex items-center gap-2 rounded-full border border-line2 px-5 py-2 text-lg font-semibold text-ink">
          <i class="ri-coins-line text-brand"></i>Posta: {@pot}
        </span>
      </div>

      <div class="mb-6 flex items-stretch gap-4">
        <.verdict_number caption={left_caption(@role)} value={@a} />
        <div class="flex flex-none items-center font-display text-4xl font-bold text-line2">+</div>
        <.verdict_number caption={right_caption(@role)} value={@b} />
      </div>

      <div class="mb-6 flex flex-col gap-2.5">
        <.verdict_row hit={@sum_hit}>
          <:label>Somma · {@a} + {@b} = {@a + @b}</:label>
          <:verb>{if @sum_hit, do: "= #{@pot}", else: "≠ #{@pot}"}</:verb>
        </.verdict_row>
        <.verdict_row hit={@equal_hit}>
          <:label>Uguali? · {@a} e {@b}</:label>
          <:verb>{if @equal_hit, do: "Sì", else: "No"}</:verb>
        </.verdict_row>
      </div>

      <div class={[
        "flex w-full items-center justify-center gap-3 rounded-3xl border p-7 font-display text-[clamp(30px,7vw,44px)] font-extrabold leading-none tracking-tight",
        @must_do && "border-bad-line bg-bad-bg text-bad",
        !@must_do && "border-good-line bg-good-bg text-good"
      ]}>
        <i class={if @must_do, do: "ri-emotion-normal-line", else: "ri-emotion-laugh-line"} style="font-size:36px"></i>
        {if @must_do, do: "DEVI FARLO", else: "TE LA SEI SCAMPATA"}
      </div>
      <p class="mt-4 text-center text-lg italic text-muted">
        {if @must_do,
          do: "Niente scuse, coglione. Ora esegui.",
          else: "Culo sfacciato. Stavolta l'hai scampata."}
      </p>
    </div>

    <.button variant="ghost" phx-click="reset" class="mt-5">
      <i class="ri-restart-line text-2xl"></i>Rigioca
    </.button>
    """
  end

  ## Shared pieces

  attr :room_id, :string, required: true

  defp room_header(assigns) do
    ~H"""
    <div class="mb-6 flex items-center justify-between">
      <div class="text-sm font-semibold uppercase tracking-widest text-muted">La stanza</div>
      <span class="rounded-full bg-brand-soft px-4 py-1.5 font-display text-base font-semibold text-brand">
        #{String.upcase(@room_id)}
      </span>
    </div>
    """
  end

  attr :text, :string, required: true
  attr :label, :string, default: "La sfida"
  attr :center, :boolean, default: false

  defp challenge_box(assigns) do
    ~H"""
    <div class={[
      "mb-6 rounded-2xl border border-line bg-paper px-5 py-5",
      @center && "text-center"
    ]}>
      <div class="text-xs font-semibold uppercase tracking-wider text-brand">{@label}</div>
      <div class="mt-1.5 font-display text-2xl font-medium leading-snug text-ink">{@text}</div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :state, :string, required: true, values: ~w(in empty)

  defp player_slot(%{state: "in"} = assigns) do
    ~H"""
    <div class="flex items-center gap-4 rounded-2xl border border-brand-soft bg-white p-4">
      <span class="flex h-12 w-12 flex-none items-center justify-center rounded-full bg-brand font-display text-lg font-bold text-white">
        {String.first(@name)}
      </span>
      <div class="flex-1">
        <div class="text-lg font-semibold text-ink">{@name}</div>
        <div class="text-sm font-medium text-good">Nella stanza</div>
      </div>
      <i class="ri-checkbox-circle-fill text-2xl text-good"></i>
    </div>
    """
  end

  defp player_slot(assigns) do
    ~H"""
    <div class="flex items-center gap-4 rounded-2xl border border-dashed border-line2 bg-paper p-4">
      <span class="flex h-12 w-12 flex-none items-center justify-center rounded-full bg-line text-faint">
        <i class="ri-question-mark text-xl"></i>
      </span>
      <div class="flex-1">
        <div class="text-lg font-semibold text-faint">{@name}</div>
        <div class="text-sm text-line2">Slot libero</div>
      </div>
      <i class="ri-loader-4-line animate-spin-slow text-xl text-line2"></i>
    </div>
    """
  end

  attr :caption, :string, required: true
  attr :value, :integer, required: true

  defp verdict_number(assigns) do
    ~H"""
    <div class="flex-1 text-center">
      <div class="mb-2 text-sm font-medium text-muted">{@caption}</div>
      <div class="rounded-2xl border border-line bg-paper py-6 font-display text-[clamp(48px,13vw,84px)] font-extrabold leading-none text-ink">
        {@value}
      </div>
    </div>
    """
  end

  attr :hit, :boolean, required: true
  slot :label, required: true
  slot :verb, required: true

  defp verdict_row(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-between rounded-2xl border px-5 py-4 text-lg font-medium",
      @hit && "border-good-line bg-good-bg text-good",
      !@hit && "border-line bg-paper text-faint"
    ]}>
      <span class="flex items-center gap-2">
        <i class={[@hit && "ri-checkbox-circle-fill", !@hit && "ri-close-circle-line", "text-xl"]}></i>
        {render_slot(@label)}
      </span>
      <span class="font-bold">{render_slot(@verb)}</span>
    </div>
    """
  end

  ## Helpers

  defp assign_room(socket, %Room{} = room) do
    phase = phase(room)

    pick =
      if room.challenge_amount,
        do: min(socket.assigns[:pick] || 1, max(1, room.challenge_amount - 1)),
        else: socket.assigns[:pick] || 1

    assign(socket,
      room: room,
      role: role(room, socket.assigns.user_id),
      phase: phase,
      nav_step: nav_step(phase),
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

  defp nav_step(:lobby), do: 2
  defp nav_step(:set_amount), do: 3
  defp nav_step(:betting), do: 4
  defp nav_step(:verdict), do: 5

  defp my_bet(%Room{challenger_bet_amount: amount}, :challenger), do: amount
  defp my_bet(%Room{challenged_bet_amount: amount}, :challenged), do: amount
  defp my_bet(_room, _role), do: nil

  defp max_pick(%Room{challenge_amount: nil}), do: 1
  defp max_pick(%Room{challenge_amount: amount}), do: max(1, amount - 1)

  defp left_caption(:challenger), do: "Tu · sfidante"
  defp left_caption(_), do: "Sfidante"

  defp right_caption(:challenged), do: "Tu · sfidato"
  defp right_caption(_), do: "L'idiota · sfidato"

  defp parse_int(value, default) do
    case Integer.parse(to_string(value)) do
      {int, _rest} -> int
      :error -> default
    end
  end

  defp share_url(room_id), do: url(~p"/r/#{room_id}")
end
