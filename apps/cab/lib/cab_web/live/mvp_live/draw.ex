defmodule CabWeb.MvpLive.Draw do
  @moduledoc "Round draw: rooms table, team-slot swaps, motion set/release."

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(%{"id" => id, "n" => n}, _session, socket) do
    socket =
      assign(socket,
        page_title: "Draw R#{n}",
        event_id: id,
        sequence: String.to_integer(n),
        rounds: [],
        round: nil,
        rooms: [],
        motion: nil,
        notice: nil
      )

    {:ok, load(socket)}
  end

  defp load(socket) do
    %{event_id: event_id, sequence: sequence} = socket.assigns

    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, rounds} <- EngineApi.list_rounds(actor, event_id),
         {:ok, round} <- Mvp.round_by_sequence(actor, event_id, sequence),
         {:ok, rooms} <- EngineApi.list_rooms(actor, round["id"]),
         {:ok, motion} <- Mvp.round_motion(actor, event_id, sequence) do
      assign(socket, rounds: rounds, round: round, rooms: rooms, motion: motion, error: nil)
    else
      {:error, message} -> assign(socket, error: message)
    end
  end

  def handle_event("swap", %{"slot_a" => a, "slot_b" => b}, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <-
           EngineApi.swap_teams(actor, socket.assigns.round["id"], a, b) do
      {:noreply, socket |> assign(notice: "teams swapped") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("save_motion", %{"text" => text}, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <-
           Mvp.set_round_motion(actor, socket.assigns.event_id, socket.assigns.sequence, text) do
      {:noreply, socket |> assign(notice: "motion saved") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("release_motion", _params, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <-
           Mvp.release_round_motion(actor, socket.assigns.event_id, socket.assigns.sequence) do
      {:noreply, socket |> assign(notice: "motion released") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  defp slot_options(rooms) do
    for room <- rooms,
        room_team <- Enum.sort_by(room["RoomTeams"] || [], & &1["position"]) do
      label =
        "Room #{room["id"]} pos #{room_team["position"]}: #{get_in(room_team, ["Team", "name"])}"

      {room_team["id"], label}
    end
  end

  def render(assigns) do
    assigns = assign(assigns, :slots, slot_options(assigns.rooms))

    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} event_id={@event_id} rounds={@rounds} />
      <h1>Round {@sequence} — draw &amp; motion</h1>
      <.mvp_error error={@error} />
      <p :if={@notice} style="color: #080;">{@notice}</p>

      <h2>Motion</h2>
      <form phx-submit="save_motion">
        <input
          type="text"
          name="text"
          size="80"
          value={@motion && @motion["motion_text"]}
          placeholder="This House would..."
        />
        <button type="submit">Save motion</button>
      </form>
      <p :if={@motion}>
        Released: <strong>{if @motion["is_released"], do: "yes", else: "no"}</strong>
        <button :if={!@motion["is_released"]} phx-click="release_motion">Release motion</button>
      </p>

      <h2>Rooms</h2>
      <div :for={room <- @rooms} style="margin-bottom: 1em;">
        <h3>Room {room["id"]} — status: {room["status"]}</h3>
        <p>
          Judges: {Enum.map_join(room["RoomAdjudicators"] || [], ", ", fn adjudicator ->
            "#{get_in(adjudicator, ["EventParticipant", "display_name"])} (#{adjudicator["role"]})"
          end)}
        </p>
        <table border="1" cellpadding="4">
          <tr>
            <th>Pos</th>
            <th>Team</th>
            <th>Speakers</th>
            <th>Rank</th>
          </tr>
          <tr :for={room_team <- Enum.sort_by(room["RoomTeams"] || [], & &1["position"])}>
            <td>{room_team["position"]}</td>
            <td>{get_in(room_team, ["Team", "name"])} (slot {room_team["id"]})</td>
            <td>
              {Enum.map_join(room_team["RoomSpeakers"] || [], ", ", fn speaker ->
                get_in(speaker, ["EventParticipant", "display_name"])
              end)}
            </td>
            <td>{room_team["rank"]}</td>
          </tr>
        </table>
      </div>
      <p :if={@rooms == []}>
        No rooms yet — generate them on the
        <a href={~p"/mvp/t/#{@event_id}/r/#{@sequence}/checkin"}>check-in</a> page.
      </p>

      <h2 :if={length(@slots) > 1}>Swap team slots</h2>
      <form :if={length(@slots) > 1} phx-submit="swap">
        <select name="slot_a">
          <option :for={{id, label} <- @slots} value={id}>{label}</option>
        </select>
        &lt;-&gt;
        <select name="slot_b">
          <option :for={{id, label} <- @slots} value={id}>{label}</option>
        </select>
        <button type="submit">Swap</button>
      </form>
    </div>
    """
  end
end
