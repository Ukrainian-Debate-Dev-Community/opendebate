defmodule UadebateWeb.CalendarHTML do
  use UadebateWeb, :html

  alias UadebateWeb.Month

  embed_templates "calendar_html/*"

  attr :first, Date, required: true
  attr :kind, :string, default: nil
  attr :base, :string, required: true
  attr :tag, :any, default: nil

  # month arrows and the kind filter; both are links, no script. Under
  # /manage the links keep a chosen tag.
  def toolbar(assigns) do
    ~H"""
    <div class="ua-toolbar">
      <div class="ua-month">
        <a class="ua-btn ua-btn--line ua-btn--sm" href={link(@base, Month.prev(@first), @kind, @tag)}>
          {month_name(Month.prev(@first).month)}
        </a>
        <b>{month_name(@first.month)} {@first.year}</b>
        <a class="ua-btn ua-btn--line ua-btn--sm" href={link(@base, Month.next(@first), @kind, @tag)}>
          {month_name(Month.next(@first).month)}
        </a>
      </div>
      <div class="ua-seg">
        <a class={is_nil(@kind) && "on"} href={link(@base, @first, nil, @tag)}>{gettext("All")}</a>
        <a
          :for={k <- Uadebate.Events.Event.kinds()}
          class={k == @kind && "on"}
          href={link(@base, @first, k, @tag)}
        >
          {kinds_label(k)}
        </a>
      </div>
    </div>
    """
  end

  def link(base, first, kind, tag) do
    query =
      [month: Month.param(first), kind: kind, tag: tag && tag.id]
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    base <> "?" <> URI.encode_query(query)
  end
end
