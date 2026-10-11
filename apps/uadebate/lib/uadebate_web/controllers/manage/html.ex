defmodule UadebateWeb.Manage.HTML do
  @moduledoc "The /manage pages: cab's form look, the command in the bar above."
  use UadebateWeb, :html

  embed_templates "html/*"

  attr :form, :any, required: true
  attr :field, :atom, required: true

  def errors(assigns) do
    assigns =
      assign(assigns, :messages, Enum.map(assigns.form[assigns.field].errors, &translate/1))

    ~H"""
    <div :for={msg <- @messages} class="hint" style="color:var(--warn)">{msg}</div>
    """
  end

  defp translate({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  attr :action, :string, required: true
  attr :method, :string, default: "post"
  attr :class, :string, default: "ua-btn ua-btn--line ua-btn--sm"
  attr :confirm, :string, default: nil
  slot :inner_block, required: true

  # a one-button form (publish, revoke, delete): POST with the CSRF token
  def button_to(assigns) do
    ~H"""
    <.form for={%{}} action={@action} method={@method} class="ua-inline-form">
      <button type="submit" class={@class}>{render_slot(@inner_block)}</button>
    </.form>
    """
  end
end
