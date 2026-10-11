defmodule UadebateWeb.Manage.EventController do
  use UadebateWeb, :controller

  alias Uadebate.Events

  plug :put_view, UadebateWeb.Manage.HTML

  def new(conn, _params) do
    render(conn, :event_form,
      manage_active: :calendar,
      page_title: gettext("New event"),
      event: nil,
      form: to_form(Events.change(), as: :event)
    )
  end

  def create(conn, %{"event" => attrs}) do
    case Events.create(attrs, conn.assigns.manager.id) do
      {:ok, event} ->
        conn
        |> put_flash(:info, gettext("Event saved."))
        |> redirect(to: back_to(event))

      {:error, changeset} ->
        render(conn, :event_form,
          manage_active: :calendar,
          page_title: gettext("New event"),
          event: nil,
          form: to_form(changeset, as: :event)
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    event = Events.get!(id)

    render(conn, :event_form,
      manage_active: :calendar,
      page_title: event.title,
      event: event,
      form: to_form(Events.change(event), as: :event)
    )
  end

  def update(conn, %{"id" => id, "event" => attrs}) do
    event = Events.get!(id)

    case Events.update(event, attrs) do
      {:ok, event} ->
        conn
        |> put_flash(:info, gettext("Event saved."))
        |> redirect(to: back_to(event))

      {:error, changeset} ->
        render(conn, :event_form,
          manage_active: :calendar,
          page_title: event.title,
          event: event,
          form: to_form(changeset, as: :event)
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    event = Events.get!(id)
    {:ok, _} = Events.delete(event)

    conn
    |> put_flash(:info, gettext("Event deleted."))
    |> redirect(to: back_to(event))
  end

  def visibility(conn, %{"id" => id, "visibility" => visibility})
      when visibility in ~w(public private) do
    event = Events.get!(id)
    {:ok, event} = Events.set_visibility(event, visibility)
    redirect(conn, to: back_to(event))
  end

  defp back_to(event),
    do: ~p"/manage/calendar?#{[month: UadebateWeb.Month.param(event.starts_on)]}"
end
