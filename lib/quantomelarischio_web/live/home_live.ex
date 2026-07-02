defmodule QuantomelarischioWeb.HomeLive do
  use QuantomelarischioWeb, :live_view

  @steps [
    {"1", "Crea una nuova stanza"},
    {"2", "Invia il link (max 2 idioti)"},
    {"3", "Aspetta l'importo"},
    {"4", "Piazza le scommesse"},
    {"5", "Il vincitore è deciso!"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Quantotelarischi?", steps: @steps)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col gap-8">
      <section class="rounded-[22px] border-2 border-ink bg-white p-7 shadow-hard">
        <h1 class="text-center text-4xl font-extrabold uppercase leading-none tracking-tight text-ink">
          Quantotelarischi<span class="text-accent">?</span>
        </h1>
        <p class="mt-3 text-center font-hand text-base text-ink/60">
          Hai le palle o sei il solito cagasotto?
        </p>
        <.button navigate={~p"/new"} class="mt-6">Crea una stanza</.button>
      </section>

      <section>
        <h2 class="mb-4 text-center font-hand text-lg text-ink/60">— Come si gioca —</h2>
        <ol class="flex flex-col gap-3">
          <li :for={{num, label} <- @steps} class="flex items-center gap-3">
            <span class={[
              "flex h-8 w-8 flex-none items-center justify-center rounded-full text-sm font-bold text-white",
              num == "5" && "bg-accent",
              num != "5" && "bg-ink"
            ]}>
              {num}
            </span>
            <span class="font-hand text-base text-ink/70">{label}</span>
          </li>
        </ol>
      </section>
    </div>
    """
  end
end
