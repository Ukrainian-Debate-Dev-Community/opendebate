defmodule CabWeb.MvpLive.Club do
  @moduledoc """
  Club session flow: create/select a club (gateway record linked to an
  engine organisation), run a one-round session (4 teams x 2 speakers,
  1 judge, 1 room), pick the winner, finish, and browse the history of
  past sessions for the club.
  """

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{Clubs, EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Club session",
       clubs: Clubs.list_clubs(),
       club: nil,
       step: :pick,
       event: nil,
       round: nil,
       room: nil,
       winner: nil,
       history: [],
       notice: nil
     )}
  end

  def handle_event("create_club", %{"name" => name}, socket) do
    case Clubs.create_club(%{name: String.trim(name)}) do
      {:ok, club} ->
        {:noreply, assign(socket, clubs: Clubs.list_clubs(), club: club, error: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, error: "could not create club: #{inspect(changeset.errors)}")}
    end
  end

  def handle_event("select_club", %{"club-id" => club_id}, socket) do
    club = Clubs.get_club(club_id)
    {:noreply, socket |> assign(club: club, step: :pick, winner: nil, error: nil) |> load_history()}
  end

  def handle_event(
        "start_session",
        %{"event_name" => event_name, "teams" => teams_text, "judge" => judge},
        socket
      ) do
    club = socket.assigns.club

    with true <- club != nil,
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, org_id} <- ensure_club_org(actor, club),
         {:ok, event} <-
           EngineApi.create_event(actor, org_id, presence(event_name, "Club session")),
         {:ok, round} <- EngineApi.create_round(actor, event["id"], "Club round", 1),
         {:ok, _count} <- Mvp.create_teams_from_lines(actor, event["id"], teams_text),
         {:ok, judge_participant} <-
           EngineApi.provision_participant(actor, event["id"], presence(judge, "Club judge"), "adjudicator"),
         {:ok, teams} <- EngineApi.list_teams(actor, event["id"]),
         {:ok, _} <- club_room(actor, round, teams, judge_participant),
         {:ok, [room | _]} <- EngineApi.list_rooms(actor, round["id"]) do
      {:noreply,
       socket
       |> assign(step: :running, event: event, round: round, room: room, error: nil)
       |> load_history()}
    else
      false -> {:noreply, assign(socket, error: "select or create a club first")}
      {:ok, []} -> {:noreply, assign(socket, error: "room was not created")}
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("pick_winner", %{"room_team_id" => room_team_id}, socket) do
    %{room: room, round: round, event: event} = socket.assigns

    with {winner_id, ""} <- Integer.parse(room_team_id),
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, rankings, scores} <- Mvp.winner_ballot_payload(room, winner_id),
         {:ok, _} <- EngineApi.submit_scores(actor, room["id"], rankings, scores),
         {:ok, _} <- EngineApi.confirm_room(actor, room["id"]),
         {:ok, _} <- EngineApi.update_round(actor, round["id"], %{status: "completed"}),
         {:ok, _} <- EngineApi.update_event(actor, event["id"], %{status: "completed"}) do
      winner =
        room["RoomTeams"]
        |> Enum.find(&(&1["id"] == winner_id))
        |> get_in(["Team", "name"])

      {:noreply,
       socket |> assign(step: :done, winner: winner, error: nil) |> load_history()}
    else
      :error -> {:noreply, assign(socket, error: "pick a team first")}
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("new_session", _params, socket) do
    {:noreply, assign(socket, step: :pick, event: nil, round: nil, room: nil, winner: nil)}
  end

  defp presence(value, default) do
    case String.trim(value) do
      "" -> default
      trimmed -> trimmed
    end
  end

  # The engine org backing this club: reuse the linked one (making sure
  # the actor is an owner) or create + link a fresh one.
  defp ensure_club_org(actor, club) do
    case club.engine_organisation_id do
      nil ->
        with {:ok, org} <- EngineApi.create_organisation(actor, "#{club.name} (club)"),
             {:ok, _} <- EngineApi.add_owner(actor, org["id"], actor),
             {:ok, _} <- Clubs.update_club(club, %{engine_organisation_id: org["id"]}) do
          {:ok, org["id"]}
        end

      org_id ->
        case EngineApi.add_owner(actor, org_id, actor) do
          {:ok, _} -> {:ok, org_id}
          {:error, "User is already an owner" <> _} -> {:ok, org_id}
          {:error, message} -> {:error, message}
        end
    end
  end

  defp club_room(actor, round, teams, judge_participant) do
    slots =
      teams
      |> Enum.with_index(1)
      |> Enum.map(fn {team, position} -> %{team_id: team["id"], position: position} end)

    EngineApi.create_room(actor, round["id"], slots, [
      %{participant_id: judge_participant["id"], role: "chair"}
    ])
  end

  defp load_history(socket) do
    with %{engine_organisation_id: org_id} when not is_nil(org_id) <-
           socket.assigns.club && Clubs.get_club(socket.assigns.club.id),
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, events} <- EngineApi.list_organisation_events(actor, org_id) do
      assign(socket, history: events)
    else
      _ -> assign(socket, history: [])
    end
  end

  def render(assigns) do
    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} />
      <h1>Club session</h1>
      <.mvp_error error={@error} />

      <h2>1. Pick a club</h2>
      <p>
        <span :for={club <- @clubs} style="margin-right: 0.8em;">
          <button phx-click="select_club" phx-value-club-id={club.id}>
            {club.name}{if @club && @club.id == club.id, do: " (selected)"}
          </button>
        </span>
      </p>
      <form phx-submit="create_club">
        <input type="text" name="name" placeholder="New club name" />
        <button type="submit">Create club</button>
      </form>

      <div :if={@club && @step == :pick}>
        <h2>2. Start a session at {@club.name}</h2>
        <form phx-submit="start_session">
          <p><input type="text" name="event_name" size="40" placeholder="Session name (optional)" /></p>
          <p>4 teams, one per line (<code>Team: Speaker1, Speaker2</code>):</p>
          <textarea name="teams" rows="4" cols="60" placeholder="Reds: Ann, Andy&#10;Blues: Ben, Bea&#10;Greens: Cam, Cal&#10;Golds: Dee, Dan"></textarea>
          <p><input type="text" name="judge" size="30" placeholder="Judge name" /></p>
          <button type="submit">Start session (creates event, room, everyone)</button>
        </form>
      </div>

      <div :if={@step == :running && @room}>
        <h2>3. Pick the winner — {@event["name"]}</h2>
        <form phx-submit="pick_winner">
          <p :for={room_team <- Enum.sort_by(@room["RoomTeams"] || [], & &1["position"])}>
            <label>
              <input type="radio" name="room_team_id" value={room_team["id"]} />
              {get_in(room_team, ["Team", "name"])} —
              {Enum.map_join(room_team["RoomSpeakers"] || [], ", ", fn speaker ->
                get_in(speaker, ["EventParticipant", "display_name"])
              end)}
            </label>
          </p>
          <button type="submit">Finish session with this winner</button>
        </form>
      </div>

      <div :if={@step == :done}>
        <h2 style="color: #080;">Session finished — winner: {@winner}</h2>
        <button phx-click="new_session">Start another session</button>
      </div>

      <div :if={@club}>
        <h2>History — {@club.name}</h2>
        <table border="1" cellpadding="4">
          <tr>
            <th>ID</th>
            <th>Session</th>
            <th>Status</th>
          </tr>
          <tr :for={event <- @history}>
            <td>{event["id"]}</td>
            <td><a href={~p"/mvp/t/#{event["id"]}"}>{event["name"]}</a></td>
            <td>{event["status"]}</td>
          </tr>
        </table>
        <p :if={@history == []}>No sessions yet.</p>
      </div>
    </div>
    """
  end
end
