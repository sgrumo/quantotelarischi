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
    {:ok,
     assign(socket,
       page_title: "Quantotelarischi?",
       nav_step: nil,
       full_viewport: :desktop,
       steps: @steps
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-7xl animate-rise flex-col gap-8 px-5 py-8 sm:px-8 lg:h-full lg:flex-row lg:items-center lg:justify-center lg:gap-16 lg:py-4">
      <div class="flex flex-col justify-center lg:flex-1">
        <img
          src={~p"/images/hero.svg"}
          alt=""
          class="mb-4 h-[min(14rem,30dvh)] w-auto self-center sm:h-[min(20rem,36dvh)] lg:h-[min(26rem,42dvh)] lg:self-start"
        />
        <h1 class="font-display text-[clamp(44px,7.5vw,110px)] font-extrabold leading-[0.95] tracking-tight text-ink">
          Quanto te la rischi<span class="text-brand">?</span>
        </h1>
        <p class="mt-5 max-w-[620px] text-xl leading-relaxed text-muted2 sm:text-2xl">
          Un numero decide chi si copre di ridicolo.
        </p>
      </div>

      <div class="flex min-h-0 flex-col justify-center lg:flex-1">
        <div class="mb-3 text-sm font-semibold uppercase tracking-widest text-muted">
          Regole
        </div>
        <div class="flex flex-col">
          <div
            :for={{{num, title, desc}, idx} <- Enum.with_index(@steps)}
            class={[
              "flex items-start gap-4 py-2.5",
              idx < length(@steps) - 1 && "border-b border-line"
            ]}
          >
            <span class={[
              "flex h-9 w-9 flex-none items-center justify-center rounded-full font-display text-base font-bold",
              num == "5" && "bg-brand text-white",
              num != "5" && "bg-brand-soft text-brand-dark"
            ]}>
              {num}
            </span>
            <div>
              <div class="text-lg font-semibold leading-snug text-ink">{title}</div>
              <div class="text-sm text-muted">{desc}</div>
            </div>
          </div>
        </div>

        <div class="order-first mb-8 lg:order-none lg:mb-0 lg:mt-6">
          <.button navigate={~p"/new"}>
            Crea una stanza <i class="ri-arrow-right-line text-2xl"></i>
          </.button>
        </div>
      </div>
    </div>
    """
  end
end
