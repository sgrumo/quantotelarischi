defmodule QuantomelarischioWeb.NewChallengeLive do
  use QuantomelarischioWeb, :live_view

  alias Quantomelarischio.Rooms

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Nuova stanza")
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
    <div class="flex flex-1 flex-col">
      <div class="rounded-md bg-ink px-3 py-2 text-center text-lg font-extrabold uppercase tracking-tight text-white">
        Nuova stanza
      </div>

      <.form for={@form} phx-submit="create" class="flex flex-1 flex-col">
        <p class="my-4 font-hand text-base text-ink/70">Quanto te la rischi a…</p>

        <.input
          field={@form[:challenge_description]}
          type="textarea"
          rows="5"
          placeholder="…mungere una mucca"
        />

        <p class="mt-3 font-hand text-sm text-ink/50">scrivi una stronzata</p>

        <div class="flex-1"></div>

        <.button type="submit">Sfida un idiota</.button>
      </.form>
    </div>
    """
  end
end
