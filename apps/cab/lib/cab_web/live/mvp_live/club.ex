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

  @example_teams "Reds: Ann, Andy\nBlues: Ben, Bea\nGreens: Cam, Cal\nGolds: Dee, Dan"

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
       notice: nil,
       example_teams: @example_teams
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
           EngineApi.provision_participant(
             actor,
             event["id"],
             presence(judge, "Club judge"),
             "adjudicator"
           ),
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

  def handle_event("pick_winner", %{"room-team-id" => room_team_id}, socket) do
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

      {:noreply, socket |> assign(step: :done, winner: winner, error: nil) |> load_history()}
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

  defp ensure_club_org(actor, club) do
    case club.engine_organisation_id do
      nil ->
        with {:ok, org} <- EngineApi.create_organisation(actor, "#{club.name} (club)"),
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

  defp stage_index(:pick, club), do: if(club, do: 1, else: 0)
  defp stage_index(:running, _club), do: 2
  defp stage_index(:done, _club), do: 3

  defp speakers_of(room_team) do
    Enum.map_join(room_team["RoomSpeakers"] || [], ", ", fn speaker ->
      get_in(speaker, ["EventParticipant", "display_name"])
    end)
  end

  def render(assigns) do
    assigns = assign(assigns, :stage, stage_index(assigns.step, assigns.club))

    ~H"""
    <.mvp_shell
      current_user={@current_user}
      dev_routes={@dev_routes}
      dev_users={@dev_users}
      context={@club && "#{@club.name} — club session"}
      return_to="/mvp/club"
      title="Club session"
      error={@error}
      notice={@notice}
    >
      <:head_tag>
        <span :if={@club} class="tag tag--info">{@club.name}</span>
      </:head_tag>

      <div class="progressline">
        <span
          :for={{label, index} <- Enum.with_index(["club", "set up", "debate", "done"])}
          class={["pseg", index < @stage && "done", index == @stage && "live"]}
        >
          {label}
        </span>
      </div>

      <.guide :if={@step == :pick && is_nil(@club)}>
        Pick your club below — or create one — then set up tonight's session.
      </.guide>
      <.guide :if={@step == :pick && @club}>
        Set up tonight's session at <b>{@club.name}</b>: 4 teams, 1 judge, one room.
      </.guide>
      <.guide :if={@step == :running}>
        Debate in progress. When it ends, click the winning team.
      </.guide>
      <.guide :if={@step == :done}>
        Session finished and recorded to club history.
        <:action>
          <button class="btn btn--cta btn--sm" phx-click="new_session">Start another</button>
        </:action>
      </.guide>

      <div :if={@step == :pick} class="card">
        <div class="card__head"><b>1 · Your club</b></div>
        <div class="card__pad">
          <div class="f-row">
            <button
              :for={club <- @clubs}
              class={["btn", "btn--sm", (@club && @club.id == club.id && "btn--primary") || "btn--soft"]}
              phx-click="select_club"
              phx-value-club-id={club.id}
            >
              {club.name}
            </button>
          </div>
          <form phx-submit="create_club" class="f-row" style="margin-top:10px;">
            <input class="input" type="text" name="name" placeholder="New club name" />
            <button class="btn btn--soft btn--sm" type="submit">Create club</button>
          </form>
        </div>
      </div>

      <div :if={@step == :pick && @club} class="card">
        <div class="card__head"><b>2 · Tonight's session</b></div>
        <div class="card__pad">
          <form phx-submit="start_session">
            <div class="f-row" style="margin-bottom:10px;">
              <input
                class="input"
                type="text"
                name="event_name"
                placeholder="Session name (optional)"
                style="flex:1; min-width:220px;"
              />
              <input class="input" type="text" name="judge" placeholder="Judge name" />
            </div>
            <span class="f-label">4 teams — one per line: Team: Speaker1, Speaker2</span>
            <textarea name="teams" rows="4" style="width:100%;">{@example_teams}</textarea>
            <div class="f-row" style="margin-top:10px;">
              <button class="btn btn--cta" type="submit">Make the room</button>
              <span class="f-help">creates the event, speakers, teams and the room</span>
            </div>
          </form>
        </div>
      </div>

      <div :if={@step == :running && @room} class="table-card card scroll-x">
        <table class="tbl drawtbl">
          <thead>
            <tr>
              <th>Team</th>
              <th>Speakers</th>
              <th>Winner?</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={room_team <- Enum.sort_by(@room["RoomTeams"] || [], & &1["position"])}>
              <td><b>{get_in(room_team, ["Team", "name"])}</b></td>
              <td>{speakers_of(room_team)}</td>
              <td>
                <button
                  class="btn btn--soft btn--sm"
                  phx-click="pick_winner"
                  phx-value-room-team-id={room_team["id"]}
                >
                  This team won
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@step == :done} class="alert alert--ok" style="font-size:1rem;">
        <b>🏆</b> Winner: <b>{@winner}</b>
      </div>

      <div :if={@club}>
        <div class="section-title">Club history</div>
        <div class="table-card card scroll-x">
          <table class="tbl">
            <thead>
              <tr>
                <th>Session</th>
                <th>Status</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={event <- @history}>
                <td><b>{event["name"]}</b></td>
                <td><.status_tag status={event["status"]} /></td>
                <td>
                  <a class="btn btn--soft btn--sm" href={~p"/mvp/t/#{event["id"]}"}>Open</a>
                </td>
              </tr>
              <tr :if={@history == []}>
                <td colspan="3" class="text-muted">No sessions yet.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </.mvp_shell>
    """
  end
end
