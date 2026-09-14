defmodule CabWeb.MvpLive.Tournament do
  @moduledoc "Tournament overview: rounds, standings, break to final, champion."

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(%{"id" => id}, _session, socket) do
    socket = assign(socket, event_id: id, event: nil, rounds: [], team_standings: [], speaker_standings: [], champion: nil)
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

  def render(assigns) do
    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} event_id={@event_id} rounds={@rounds} />
      <h1>Tournament: {(@event && @event["name"]) || "##{@event_id}"}</h1>
      <.mvp_error error={@error} />
      <p :if={@event}>Status: {@event["status"]} <button phx-click="refresh">Refresh</button></p>

      <p :if={@champion} style="font-size: 1.3em; border: 2px solid #080; padding: 0.5em;">
        Champion: <strong>{@champion}</strong>
      </p>

      <h2>Rounds</h2>
      <table border="1" cellpadding="4">
        <tr>
          <th>#</th>
          <th>Name</th>
          <th>Status</th>
          <th>Links</th>
        </tr>
        <tr :for={round <- @rounds}>
          <td>{round["sequence"]}</td>
          <td>{round["name"]}</td>
          <td>{round["status"]}</td>
          <td>
            <a href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/checkin"}>check-in</a>
            | <a href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/draw"}>draw + motion</a>
            | <a href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/ballots"}>ballots</a>
          </td>
        </tr>
      </table>

      <p :if={is_nil(@champion)}>
        <button phx-click="break_final">Break to final (top 4 by standings)</button>
      </p>

      <h2>Team standings</h2>
      <table border="1" cellpadding="4">
        <tr>
          <th>#</th>
          <th>Team</th>
          <th>Points</th>
        </tr>
        <tr :for={{team, index} <- Enum.with_index(@team_standings, 1)}>
          <td>{index}</td>
          <td>{team["name"]}</td>
          <td>{team["total_points"]}</td>
        </tr>
      </table>

      <h2>Speaker standings</h2>
      <table border="1" cellpadding="4">
        <tr>
          <th>#</th>
          <th>Speaker</th>
          <th>Points</th>
        </tr>
        <tr :for={{speaker, index} <- Enum.with_index(@speaker_standings, 1)}>
          <td>{index}</td>
          <td>{speaker["name"]}</td>
          <td>{speaker["total_points"]}</td>
        </tr>
      </table>
    </div>
    """
  end
end
