defmodule CabWeb.MvpLive.Ballots do
  @moduledoc """
  Per-room ballots for a round: 8 speaker score inputs (team ranks are
  derived from team score sums), submit/reopen/confirm, and completing
  the round once every room is confirmed.
  """

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(%{"id" => id, "n" => n}, _session, socket) do
    socket =
      assign(socket,
        page_title: "Ballots R#{n}",
        event_id: id,
        sequence: String.to_integer(n),
        rounds: [],
        round: nil,
        rooms: [],
        notice: nil
      )

    {:ok, load(socket)}
  end

  defp load(socket) do
    %{event_id: event_id, sequence: sequence} = socket.assigns

    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, rounds} <- EngineApi.list_rounds(actor, event_id),
         {:ok, round} <- Mvp.round_by_sequence(actor, event_id, sequence),
         {:ok, rooms} <- EngineApi.list_rooms(actor, round["id"]) do
      assign(socket, rounds: rounds, round: round, rooms: rooms, error: nil)
    else
      {:error, message} -> assign(socket, error: message)
    end
  end

  def handle_event("submit_ballot", %{"room_id" => room_id, "scores" => scores}, socket) do
    room = Enum.find(socket.assigns.rooms, &(to_string(&1["id"]) == room_id))

    with true <- room != nil,
         {:ok, parsed} <- parse_scores(scores),
         {:ok, team_rankings, speaker_scores} <- Mvp.ballot_payload(room, parsed),
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <- EngineApi.submit_scores(actor, room["id"], team_rankings, speaker_scores) do
      {:noreply, socket |> assign(notice: "ballot submitted for room #{room_id}") |> load()}
    else
      false -> {:noreply, assign(socket, error: "unknown room")}
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("confirm", %{"room-id" => room_id}, socket) do
    room_action(socket, room_id, &EngineApi.confirm_room/2, "ballot confirmed")
  end

  def handle_event("unconfirm", %{"room-id" => room_id}, socket) do
    room_action(socket, room_id, &EngineApi.unconfirm_room/2, "ballot unconfirmed")
  end

  def handle_event("reopen", %{"room-id" => room_id}, socket) do
    room_action(socket, room_id, &EngineApi.reopen_room/2, "room reopened, ballot cleared")
  end

  def handle_event("complete_round", _params, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <-
           EngineApi.update_round(actor, socket.assigns.round["id"], %{status: "completed"}) do
      {:noreply, socket |> assign(notice: "round completed") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  defp room_action(socket, room_id, fun, notice) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <- fun.(actor, room_id) do
      {:noreply, socket |> assign(notice: notice) |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  defp parse_scores(scores) do
    Enum.reduce_while(scores, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      with {speaker_id, ""} <- Integer.parse(key),
           {score, ""} <- Float.parse(String.trim(value)) do
        {:cont, {:ok, Map.put(acc, speaker_id, score)}}
      else
        _ -> {:halt, {:error, "scores must be numbers (got #{inspect(value)})"}}
      end
    end)
  end

  defp all_confirmed?(rooms), do: rooms != [] and Enum.all?(rooms, &(&1["status"] == "confirmed"))

  defp speakers_in_order(room) do
    for room_team <- Enum.sort_by(room["RoomTeams"] || [], & &1["position"]),
        speaker <- room_team["RoomSpeakers"] || [] do
      {speaker, room_team}
    end
  end

  def render(assigns) do
    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} event_id={@event_id} rounds={@rounds} />
      <h1>Round {@sequence} — ballots</h1>
      <.mvp_error error={@error} />
      <p :if={@notice} style="color: #080;">{@notice}</p>
      <p :if={@round}>Round status: <strong>{@round["status"]}</strong></p>

      <div :for={room <- @rooms} style="border: 1px solid #666; padding: 0.5em; margin-bottom: 1em;">
        <h2>Room {room["id"]} — status: {room["status"]}</h2>

        <form :if={room["status"] in ["pending", "judging"]} phx-submit="submit_ballot">
          <input type="hidden" name="room_id" value={room["id"]} />
          <table border="1" cellpadding="4">
            <tr>
              <th>Team (pos)</th>
              <th>Speaker</th>
              <th>Score (50-100)</th>
            </tr>
            <tr :for={{speaker, room_team} <- speakers_in_order(room)}>
              <td>{get_in(room_team, ["Team", "name"])} ({room_team["position"]})</td>
              <td>{get_in(speaker, ["EventParticipant", "display_name"])}</td>
              <td>
                <input
                  type="number"
                  name={"scores[#{speaker["id"]}]"}
                  min="50"
                  max="100"
                  step="0.5"
                  required
                />
              </td>
            </tr>
          </table>
          <button type="submit">Submit ballot (ranks derived from team totals)</button>
        </form>

        <div :if={room["status"] in ["completed", "confirmed"]}>
          <table border="1" cellpadding="4">
            <tr>
              <th>Rank</th>
              <th>Team</th>
            </tr>
            <tr :for={room_team <- Enum.sort_by(room["RoomTeams"] || [], & &1["rank"])}>
              <td>{room_team["rank"]}</td>
              <td>{get_in(room_team, ["Team", "name"])}</td>
            </tr>
          </table>
          <button :if={room["status"] == "completed"} phx-click="confirm" phx-value-room-id={room["id"]}>
            Confirm ballot
          </button>
          <button :if={room["status"] == "completed"} phx-click="reopen" phx-value-room-id={room["id"]}>
            Reopen (edit scores)
          </button>
          <button :if={room["status"] == "confirmed"} phx-click="unconfirm" phx-value-room-id={room["id"]}>
            Unconfirm
          </button>
        </div>
      </div>
      <p :if={@rooms == []}>No rooms in this round yet.</p>

      <p>
        <button
          phx-click="complete_round"
          disabled={not all_confirmed?(@rooms) or (@round && @round["status"] == "completed")}
        >
          Complete round (all ballots confirmed)
        </button>
      </p>
    </div>
    """
  end
end
