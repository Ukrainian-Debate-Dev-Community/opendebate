defmodule UadebateWeb.Manage.CalendarController do
  use UadebateWeb, :controller

  alias Uadebate.Events
  alias Uadebate.Events.Event
  alias UadebateWeb.Month

  def index(conn, params) do
    first = Month.parse(params["month"])
    kind = if params["kind"] in Event.kinds(), do: params["kind"]

    conn
    |> put_view(UadebateWeb.Manage.HTML)
    |> render(:calendar,
      manage_active: :calendar,
      page_title: gettext("Calendar"),
      first: first,
      kind: kind,
      events: Events.all_in_month(first, kind)
    )
  end
end
