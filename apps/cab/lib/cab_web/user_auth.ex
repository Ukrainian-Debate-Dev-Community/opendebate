defmodule CabWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Cab.Accounts

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    assign(conn, :current_user, user_id && Accounts.get_user(user_id))
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "Please sign in.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  @doc """
  Plug skeleton guarding event-scoped routes by elevation role.

      plug :require_elevation, "organiser"

  Expects an authenticated `:current_user` and an `"event_id"` path
  param naming the engine event. Admins pass unconditionally.
  """
  def require_elevation(conn, role) when is_binary(role) do
    user = conn.assigns[:current_user]
    event_id = parse_event_id(conn.params["event_id"])

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:error, "Please sign in.")
        |> redirect(to: "/")
        |> halt()

      user.is_admin ->
        conn

      event_id && Cab.Events.elevated?(user.id, event_id, role) ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.put_view(html: CabWeb.ErrorHTML, json: CabWeb.ErrorJSON)
        |> Phoenix.Controller.render(:"403")
        |> halt()
    end
  end

  defp parse_event_id(nil), do: nil

  defp parse_event_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp parse_event_id(value) when is_integer(value), do: value
end
