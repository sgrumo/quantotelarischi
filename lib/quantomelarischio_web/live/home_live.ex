defmodule QuantomelarischioWeb.HomeLive do
  use QuantomelarischioWeb, :live_view

  @steps [
    {"1", "Crea una nuova stanza", "Scrivi la sfida e genera il tuo link."},
    {"2", "Invia il link", "Un solo idiota per stanza. Max 2 giocatori."},
    {"3", "Aspetta l'importo", "Lo sfidato decide quanto vale la stronzata (min 2)."},
    {"4", "Piazza le scommesse", "Ognuno sceglie un numero da 1 a (importo − 1)."},
    {"5", "Il vincitore è deciso!",
     "Se i numeri combaciano o la somma fa l'importo → lo sfidato deve farlo."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Quantotelarischi?", nav_step: nil, steps: @steps)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="animate-rise">
      <div class="mb-8 inline-block rounded-full bg-brand-soft px-4 py-2 text-sm font-semibold uppercase tracking-widest text-brand-dark">
        Party game · scommesse da idioti
      </div>
      <h1 class="font-display text-[clamp(64px,13vw,144px)] font-extrabold leading-[0.95] tracking-tight text-ink">
        Quanto te la rischi<span class="text-brand">?</span>
      </h1>
      <p class="my-8 max-w-[620px] text-2xl leading-relaxed text-muted2">
        Sfida un amico a fare una stronzata. Un numero decide chi si copre di ridicolo.
        Hai le palle o sei il solito cagasotto?
      </p>
      <.button navigate={~p"/new"} class="max-w-md">
        Crea una stanza <i class="ri-arrow-right-line text-2xl"></i>
      </.button>

      <div class="mt-20">
        <div class="mb-6 text-sm font-semibold uppercase tracking-widest text-muted">
          Come si gioca
        </div>
        <div class="flex flex-col">
          <div
            :for={{{num, title, desc}, idx} <- Enum.with_index(@steps)}
            class={["flex items-start gap-5 py-6", idx < length(@steps) - 1 && "border-b border-line"]}
          >
            <span class={[
              "flex h-12 w-12 flex-none items-center justify-center rounded-full font-display text-xl font-bold",
              num == "5" && "bg-brand text-white",
              num != "5" && "bg-brand-soft text-brand-dark"
            ]}>
              {num}
            </span>
            <div>
              <div class="text-2xl font-semibold text-ink">{title}</div>
              <div class="mt-1 text-lg text-muted">{desc}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
