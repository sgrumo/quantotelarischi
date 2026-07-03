defmodule QuantomelarischioWeb.NewChallengeLive do
  use QuantomelarischioWeb, :live_view

  alias Quantomelarischio.Rooms

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Nuova stanza", nav_step: 1, full_viewport: true)
     |> assign(form: to_form(%{"challenge_description" => ""}))}
  end

  @impl true
  def handle_event("create", %{"challenge_description" => description}, socket) do
    case String.trim(description) do
      "" ->
        {:noreply, put_flash(socket, :error, "Scrivi prima una stronzata.")}

      description ->
        case Rooms.create_room(description) do
          {:ok, room_id} ->
            {:noreply, push_navigate(socket, to: ~p"/r/#{room_id}")}

          _error ->
            {:noreply, put_flash(socket, :error, "Qualcosa è andato storto. Riprova.")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto flex h-full w-full max-w-2xl animate-rise flex-col justify-center px-5 py-4 sm:px-6">
      <div class="mb-3 text-sm font-semibold uppercase tracking-widest text-muted">
        Nuova stanza
      </div>
      <h2 class="mb-5 font-display text-[clamp(38px,8vw,68px)] font-bold leading-[1.02] tracking-tight text-ink sm:mb-8">
        Quanto te la rischi a…
      </h2>

      <.form for={@form} phx-submit="create">
        <.input
          field={@form[:challenge_description]}
          type="textarea"
          placeholder="…mungere una mucca davanti a tutti"
        />
        <.button class="mt-3" type="submit">
          Sfida un idiota <i class="ri-user-add-line text-2xl"></i>
        </.button>
      </.form>
    </div>
    """
  end
end
