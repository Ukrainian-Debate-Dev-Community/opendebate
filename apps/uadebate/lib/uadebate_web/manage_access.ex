defmodule UadebateWeb.ManageAccess do
  @moduledoc """
  Lets into /manage only content managers and cab admins. It reads
  cab's session cookie (never writes it) through CabWeb.Session, loads
  the cab account and asks Uadebate.Roles; anyone else, signed out
  included, gets the same 404 as for a page that does not exist.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)
    user_id = CabWeb.Session.user_id(conn.req_cookies[CabWeb.Session.cookie_key()])
    user = user_id && Cab.Accounts.get_viewer(user_id)

    case user && !user.guest && Uadebate.Roles.access(user) do
      access when access in [:admin, :content_manager] ->
        conn |> assign(:manager, user) |> assign(:access, access)

      _ ->
        raise UadebateWeb.NotFound
    end
  end
end
