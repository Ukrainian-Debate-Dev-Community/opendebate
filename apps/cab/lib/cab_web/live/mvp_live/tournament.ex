defmodule CabWeb.MvpLive.Tournament do
  @moduledoc "Tournament overview: round flow, standings, break to final, champion."

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(%{"id" => id}, _session, socket) do
    socket =
      assign(socket,
        event_id: id,
        event: nil,
        rounds: [],
        team_standings: [],
        speaker_standings: [],
        champion: nil
      )

    {:ok, load(socket)}
  end

  defp load(socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, event} <- EngineApi.get_event(actor, socket.assigns.event_id),
         {:ok, rounds} <- EngineApi.list_rounds(actor, socket.assigns.event_id),
         {:ok, team_standings} <- EngineApi.team_standings(actor, socket.assigns.event_id),
         {:ok, speaker_standings} <- EngineApi.speaker_standings(actor, socket.assigns.event_id),
         {:ok, champion} <- Mvp.champion(actor, socket.assigns.event_id) do
      assign(socket,
        page_title: event["name"],
        event: event,
        rounds: rounds,
        team_standings: team_standings,
        speaker_standings: speaker_standings,
        champion: champion,
        error: nil
      )
    else
      {:error, message} -> assign(socket, error: message)
    end
  end

  def handle_event("break_final", _params, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, round} <- Mvp.break_to_final(actor, socket.assigns.event_id) do
      {:noreply,
       push_navigate(socket,
         to: ~p"/mvp/t/#{socket.assigns.event_id}/r/#{round["sequence"]}/ballots"
       )}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, load(socket)}
  end

  defp current_round(rounds), do: Enum.find(rounds, &(&1["status"] != "completed"))

  defp prelims_done?(rounds) do
    prelims = Enum.reject(rounds, &(&1["name"] == "Final"))
    prelims != [] and Enum.all?(prelims, &(&1["status"] == "completed"))
  end

  defp has_final?(rounds), do: Enum.any?(rounds, &(&1["name"] == "Final"))

  def render(assigns) do
    assigns = assign(assigns, :current_round, current_round(assigns.rounds))

    ~H"""
    <.mvp_shell
      current_user={@current_user}
      dev_routes={@dev_routes}
      dev_users={@dev_users}
      context={@event && @event["name"]}
      return_to={"/mvp/t/#{@event_id}"}
      title={(@event && @event["name"]) || "Tournament ##{@event_id}"}
      error={@error}
    >
      <:head_tag>
        <.status_tag :if={@event} status={@event["status"]} />
        <a class="btn btn--soft btn--sm" href={~p"/mvp/t/#{@event_id}/setup"}>Setup</a>
        <button class="btn btn--soft btn--sm" phx-click="refresh">Refresh</button>
      </:head_tag>

      <.td_flow event_id={@event_id} rounds={@rounds} />

      <div :if={@champion} class="alert alert--ok" style="font-size:1rem;">
        <b>🏆</b> Champion: <b>{@champion}</b>
      </div>

      <.guide :if={is_nil(@champion) && @current_round && @current_round["name"] == "Final"}>
        The final room is set — enter and confirm its ballot to crown the champion.
        <:action>
          <a
            class="btn btn--cta btn--sm"
            href={~p"/mvp/t/#{@event_id}/r/#{@current_round["sequence"]}/ballots"}
          >
            Final ballot
          </a>
        </:action>
      </.guide>

      <.guide :if={is_nil(@champion) && @current_round && @current_round["name"] != "Final"}>
        Next: run <b>{@current_round["name"]}</b> — check-in → draw + motion → ballots.
        First time here? Add teams and judges in
        <a href={~p"/mvp/t/#{@event_id}/setup"}>Setup</a> first.
        <:action>
          <a
            class="btn btn--cta btn--sm"
            href={~p"/mvp/t/#{@event_id}/r/#{@current_round["sequence"]}/checkin"}
          >
            Run {@current_round["name"]}
          </a>
        </:action>
      </.guide>

      <.guide :if={is_nil(@champion) && prelims_done?(@rounds) && !has_final?(@rounds)}>
        All preliminary rounds are done — break the top 4 teams to the final.
        <:action>
          <button class="btn btn--cta btn--sm" phx-click="break_final">Break to final</button>
        </:action>
      </.guide>

      <div class="section-title">Rounds</div>
      <div class="table-card card scroll-x">
        <table class="tbl">
          <thead>
            <tr>
              <th>Round</th>
              <th>Status</th>
              <th>Steps</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={round <- @rounds}>
              <td><b>{round["name"]}</b></td>
              <td><.status_tag status={round["status"]} /></td>
              <td>
                <a
                  class="btn btn--soft btn--sm"
                  href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/checkin"}
                >
                  Check-in
                </a>
                <a
                  class="btn btn--soft btn--sm"
                  href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/draw"}
                >
                  Draw
                </a>
                <a
                  class="btn btn--soft btn--sm"
                  href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/ballots"}
                >
                  Ballots
                </a>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="section-title">Team standings</div>
      <div class="table-card card scroll-x">
        <table class="tbl">
          <thead>
            <tr>
              <th>#</th>
              <th>Team</th>
              <th>Pts</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{team, index} <- Enum.with_index(@team_standings, 1)}>
              <td class="rank">{index}</td>
              <td><b>{team["name"]}</b></td>
              <td>{team["total_points"]}</td>
            </tr>
            <tr :if={@team_standings == []}>
              <td colspan="3" class="text-muted">Standings appear once ballots are in.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="section-title">Speaker standings</div>
      <div class="table-card card scroll-x">
        <table class="tbl">
          <thead>
            <tr>
              <th>#</th>
              <th>Speaker</th>
              <th>Pts</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{speaker, index} <- Enum.with_index(@speaker_standings, 1)}>
              <td class="rank">{index}</td>
              <td>{speaker["name"]}</td>
              <td>{speaker["total_points"]}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </.mvp_shell>
    """
  end
end
