defmodule QuantomelarischioWeb.CoreComponents do
  @moduledoc """
  Provides core UI components, styled with Tailwind for the Quantotelarischi theme
  (paper background, ink foreground, orange accent).
  """
  use Phoenix.Component

  use Gettext, backend: QuantomelarischioWeb.Gettext

  alias Phoenix.LiveView.JS

  attr :name, :string, required: true
  attr :class, :string, default: nil

  @spec icon(map()) :: Phoenix.LiveView.Rendered.t()
  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders a flash message.
  """
  attr :flash, :map, required: true
  attr :kind, :atom, values: [:info, :error], required: true

  @spec flash_message(map()) :: Phoenix.LiveView.Rendered.t()
  def flash_message(assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      role="alert"
      class={[
        "fixed top-4 right-4 z-50 flex items-start gap-3 rounded-xl border-2 border-ink px-4 py-3 shadow-hard",
        @kind == :info && "bg-white text-ink",
        @kind == :error && "bg-accent text-white"
      ]}
    >
      <p class="text-sm font-semibold">{msg}</p>
      <button type="button" class="opacity-70 hover:opacity-100" phx-click={JS.push("lv:clear-flash", value: %{key: @kind})}>
        <.icon name="hero-x-mark" class="h-5 w-5" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a flash group (info + error). Only used inside layouts.
  """
  attr :flash, :map, required: true

  @spec flash_group(map()) :: Phoenix.LiveView.Rendered.t()
  def flash_group(assigns) do
    ~H"""
    <.flash_message flash={@flash} kind={:info} />
    <.flash_message flash={@flash} kind={:error} />
    """
  end

  @doc """
  Renders a button or link styled as a button.

  ## Examples

      <.button>Send</.button>
      <.button variant="ghost" navigate={~p"/"}>Back</.button>
  """
  attr :type, :string, default: "button"
  attr :variant, :string, default: "solid", values: ~w(solid ghost)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value navigate patch href method)

  slot :inner_block, required: true

  @spec button(map()) :: Phoenix.LiveView.Rendered.t()
  def button(%{rest: rest} = assigns) do
    base =
      "block w-full rounded-lg px-4 py-3 text-center text-sm font-bold uppercase tracking-wide transition active:translate-y-px disabled:opacity-40 disabled:pointer-events-none"

    variant =
      case assigns.variant do
        "ghost" -> "bg-white text-ink border-2 border-ink hover:bg-paper"
        _ -> "bg-accent text-white border-2 border-accent hover:brightness-95"
      end

    assigns = assign(assigns, :classes, [base, variant, assigns.class])

    if rest[:navigate] || rest[:patch] || rest[:href] do
      ~H"""
      <.link class={@classes} {@rest}>{render_slot(@inner_block)}</.link>
      """
    else
      ~H"""
      <button type={@type} class={@classes} {@rest}>{render_slot(@inner_block)}</button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(placeholder required disabled readonly rows maxlength min max step inputmode)

  @spec input(map()) :: Phoenix.LiveView.Rendered.t()
  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="mb-2 block text-sm font-semibold text-ink">{@label}</label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "w-full rounded-lg border-2 border-ink/30 bg-white p-3 text-ink focus:border-accent focus:outline-none",
          @class
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <p :for={msg <- @errors} class="mt-1 text-sm text-accent">{msg}</p>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="mb-2 block text-sm font-semibold text-ink">{@label}</label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "w-full rounded-lg border-2 border-ink/30 bg-white p-3 text-ink focus:border-accent focus:outline-none",
          @class
        ]}
        {@rest}
      />
      <p :for={msg <- @errors} class="mt-1 text-sm text-accent">{msg}</p>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end
