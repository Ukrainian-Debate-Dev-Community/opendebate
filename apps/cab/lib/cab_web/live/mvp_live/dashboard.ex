defmodule CabWeb.MvpLive.Dashboard do
  @moduledoc "MVP dashboard: public engine event list, create tournament, dev user switcher."

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.EngineApi
  alias CabWeb.MvpAuth

  def mount(_params, _session, socket) do
    {events, error} =
      case EngineApi.list_public_events() do
        {:ok, events} -> {events, nil}
        {:error, message} -> {[], message}
      end

    {:ok,
     assign(socket,
       page_title: "MVP dashboard",
       events: events,
       error: error,
       dev_routes: Application.get_env(:cab, :dev_routes, false),
       dev_users: if(Application.get_env(:cab, :dev_routes, false), do: Cab.Accounts.list_users(), else: [])
     )}
  end

  def handle_event("create_tournament", %{"name" => name}, socket) do
    name = String.trim(name)

    with :ok <- validate_name(name),
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, %{"event" => event}} <- EngineApi.create_tournament(actor, name),
         {:ok, _} <- create_prelim_rounds(actor, event["id"]) do
      {:noreply, push_navigate(socket, to: ~p"/mvp/t/#{event["id"]}/setup")}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  defp validate_name(""), do: {:error, "tournament name required"}
  defp validate_name(_), do: :ok

  defp create_prelim_rounds(actor, event_id) do
    Enum.reduce_while(1..3, {:ok, 0}, fn n, {:ok, count} ->
      case EngineApi.create_round(actor, event_id, "Round #{n}", n) do
        {:ok, _} -> {:cont, {:ok, count + 1}}
        {:error, message} -> {:halt, {:error, "creating round #{n}: #{message}"}}
      end
    end)
  end

  def render(assigns) do
    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} />
      <h1>MVP dashboard</h1>
      <.mvp_error error={@error} />

      <h2>Create tournament</h2>
      <form phx-submit="create_tournament">
        <input type="text" name="name" placeholder="Tournament name" />
        <button type="submit">Create tournament (with rounds 1-3)</button>
      </form>

      <h2>Engine events (public list)</h2>
      <table border="1" cellpadding="4">
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Status</th>
          <th>Organisation</th>
          <th></th>
        </tr>
        <tr :for={event <- @events}>
          <td>{event["id"]}</td>
          <td>{event["name"]}</td>
          <td>{event["status"]}</td>
          <td>{get_in(event, ["Organisation", "name"])}</td>
          <td><a href={~p"/mvp/t/#{event["id"]}"}>open</a></td>
        </tr>
      </table>
      <p :if={@events == []}>No events yet.</p>

      <div :if={@dev_routes} style="margin-top: 2em; border: 2px dashed #c60; padding: 0.5em;">
        <h2>Dev user switcher (DEV ONLY)</h2>
        <p>Bypasses OAuth; sets the session user. Not available in production builds.</p>
        <form action="/dev/switch-user" method="get">
          <input type="hidden" name="return_to" value="/mvp" />
          <input type="text" name="username" placeholder="username (created if missing)" />
          <button type="submit">Switch user</button>
        </form>
        <p>
          Cast:
          <a :for={user <- @dev_users} href={"/dev/switch-user?username=#{user.username}&return_to=/mvp"} style="margin-right: 0.6em;">
            {user.username}
          </a>
        </p>
      </div>
    </div>
    """
  end
end
