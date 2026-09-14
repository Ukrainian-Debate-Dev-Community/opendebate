defmodule CabWeb.MvpLive.Checkin do
  @moduledoc "Per-round team check-in and room generation."

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(%{"id" => id, "n" => n}, _session, socket) do
    socket =
      assign(socket,
        page_title: "Check-in R#{n}",
        event_id: id,
        sequence: String.to_integer(n),
        rounds: [],
        round: nil,
        teams: [],
        rooms: []
      )

    {:ok, load(socket)}
  end

  defp load(socket) do
    %{event_id: event_id, sequence: sequence} = socket.assigns

    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, rounds} <- EngineApi.list_rounds(actor, event_id),
         {:ok, round} <- Mvp.round_by_sequence(actor, event_id, sequence),
         {:ok, teams} <- Mvp.teams_with_checkin(actor, event_id),
         {:ok, rooms} <- EngineApi.list_rooms(actor, round["id"]) do
      assign(socket, rounds: rounds, round: round, teams: teams, rooms: rooms, error: nil)
    else
      {:error, message} -> assign(socket, error: message)
    end
  end

  def handle_event("toggle", %{"team-id" => team_id}, socket) do
    team = Enum.find(socket.assigns.teams, &(to_string(&1["id"]) == team_id))

    with true <- team != nil,
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <-
           Mvp.set_team_checkin(actor, socket.assigns.event_id, team, !team["checked_in"]) do
      {:noreply, load(socket)}
    else
      false -> {:noreply, assign(socket, error: "unknown team")}
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("generate_rooms", _params, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _count} <- Mvp.generate_rooms(actor, socket.assigns.event_id, socket.assigns.round) do
      {:noreply,
       push_navigate(socket,
         to: ~p"/mvp/t/#{socket.assigns.event_id}/r/#{socket.assigns.sequence}/draw"
       )}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def render(assigns) do
    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} event_id={@event_id} rounds={@rounds} />
      <h1>Round {@sequence} — check-in</h1>
      <.mvp_error error={@error} />

      <table border="1" cellpadding="4">
        <tr>
          <th>Checked in</th>
          <th>Team</th>
          <th>Speakers</th>
        </tr>
        <tr :for={team <- @teams}>
          <td style="text-align: center;">
            <input
              type="checkbox"
              checked={team["checked_in"]}
              phx-click="toggle"
              phx-value-team-id={team["id"]}
            />
          </td>
          <td>{team["name"]}</td>
          <td>{Enum.map_join(team["speakers"], ", ", & &1["name"])}</td>
        </tr>
      </table>
      <p :if={@teams == []}>No teams yet — create them on the Setup page.</p>

      <p>
        Checked-in teams: {Enum.count(@teams, & &1["checked_in"])} / {length(@teams)}.
        Rooms in this round: {length(@rooms)}.
      </p>

      <button phx-click="generate_rooms" disabled={@rooms != []}>
        Generate rooms (groups of {Cab.Mvp.teams_per_room()} from checked-in teams)
      </button>
      <span :if={@rooms != []}>
        — rooms already exist, go to
        <a href={~p"/mvp/t/#{@event_id}/r/#{@sequence}/draw"}>draw</a>
      </span>
    </div>
    """
  end
end
