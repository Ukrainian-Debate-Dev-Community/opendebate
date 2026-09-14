defmodule CabWeb.MvpAuth do
  @moduledoc """
  on_mount hook for the MVP LiveViews: loads the session user (if any)
  and provides the `actor/1` helper resolving a gateway user to their
  engine user id, provisioning lazily when needed.
  """

  import Phoenix.Component, only: [assign: 2]

  alias Cab.Accounts

  def on_mount(:current_user, _params, session, socket) do
    user = session["user_id"] && Accounts.get_user(session["user_id"])
    dev_routes = Application.get_env(:cab, :dev_routes, false)

    {:cont,
     assign(socket,
       current_user: user,
       error: nil,
       dev_routes: dev_routes,
       dev_users: if(dev_routes, do: Accounts.list_users(), else: [])
     )}
  end

  @doc """
  Resolves the acting engine user id for `user`.
  """
  def actor(nil), do: {:error, "please sign in first (dev user switcher on /mvp, or GitHub)"}

  def actor(user) do
    case Accounts.ensure_node_user(user) do
      %{node_user_id: nil} ->
        {:error, "could not provision an engine user — is the engine running?"}

      %{node_user_id: node_user_id} ->
        {:ok, node_user_id}
    end
  end
end
