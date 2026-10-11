defmodule UadebateWeb.CalendarController do
  use UadebateWeb, :controller

  alias Uadebate.Events
  alias Uadebate.Events.Event
  alias UadebateWeb.Month

  def index(conn, params) do
    first = Month.parse(params["month"])
    kind = if params["kind"] in Event.kinds(), do: params["kind"]

    render(conn, :index,
      active: :calendar,
      page_title: gettext("Calendar"),
      first: first,
      kind: kind,
      events: Events.public_in_month(first, kind)
    )
  end

  # the public events as an iCalendar feed; private ones never leave /manage
  def ics(conn, _params) do
    conn
    |> put_resp_content_type("text/calendar")
    |> send_resp(200, Uadebate.ICal.feed(Events.all_public(), conn.host))
  end
end
