defmodule CabWeb.MvpLive.Setup do
  @moduledoc """
  Full-control setup: bulk-create teams from "Team: Speaker1, Speaker2"
  lines (each speaker becomes a gateway-provisioned shadow engine
  user), add judges by name, appoint organizer roles.
  """

  use CabWeb, :live_view

  import CabWeb.MvpComponents

  alias Cab.{EngineApi, Mvp}
  alias CabWeb.MvpAuth

  def mount(%{"id" => id}, _session, socket) do
    socket =
      assign(socket,
        page_title: "Setup",
        event_id: id,
        rounds: [],
        teams: [],
        participants: [],
        organizers: [],
        notice: nil
      )

    {:ok, load(socket)}
  end

  defp load(socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, rounds} <- EngineApi.list_rounds(actor, socket.assigns.event_id),
         {:ok, teams} <- EngineApi.list_teams(actor, socket.assigns.event_id),
         {:ok, participants} <- EngineApi.list_participants(actor, socket.assigns.event_id),
         {:ok, organizers} <- EngineApi.list_organizers(actor, socket.assigns.event_id) do
      assign(socket,
        rounds: rounds,
        teams: teams,
        participants: participants,
        organizers: organizers,
        error: nil
      )
    else
      {:error, message} -> assign(socket, error: message)
    end
  end

  def handle_event("create_teams", %{"lines" => lines}, socket) do
    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, count} <- Mvp.create_teams_from_lines(actor, socket.assigns.event_id, lines) do
      {:noreply, socket |> assign(notice: "created #{count} team(s)") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("add_judges", %{"names" => names}, socket) do
    judge_names =
      names |> String.split(~r/\R/) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

    with {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, count} <- add_judges(actor, socket.assigns.event_id, judge_names) do
      {:noreply, socket |> assign(notice: "added #{count} judge(s)") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  def handle_event("add_organizer", %{"user_id" => user_id, "role" => role}, socket) do
    with {:ok, target} <- parse_int(user_id, "engine user id"),
         {:ok, actor} <- MvpAuth.actor(socket.assigns.current_user),
         {:ok, _} <- EngineApi.add_organizer(actor, socket.assigns.event_id, target, role) do
      {:noreply, socket |> assign(notice: "organizer role granted") |> load()}
    else
      {:error, message} -> {:noreply, assign(socket, error: message)}
    end
  end

  defp add_judges(actor, event_id, names) do
    Enum.reduce_while(names, {:ok, 0}, fn name, {:ok, count} ->
      case EngineApi.provision_participant(actor, event_id, name, "adjudicator") do
        {:ok, _} -> {:cont, {:ok, count + 1}}
        {:error, message} -> {:halt, {:error, "#{name}: #{message}"}}
      end
    end)
  end

  defp parse_int(value, label) do
    case Integer.parse(String.trim(value)) do
      {int, ""} -> {:ok, int}
      _ -> {:error, "#{label} must be an integer"}
    end
  end

  def render(assigns) do
    ~H"""
    <div style="font-family: sans-serif; margin: 1em;">
      <.mvp_nav current_user={@current_user} event_id={@event_id} rounds={@rounds} />
      <h1>Setup</h1>
      <.mvp_error error={@error} />
      <p :if={@notice} style="color: #080;">{@notice}</p>

      <h2>Create teams</h2>
      <p>One team per line: <code>Team name: Speaker1, Speaker2</code></p>
      <form phx-submit="create_teams">
        <textarea name="lines" rows="10" cols="60" placeholder="Alpha: Alice, Aaron&#10;Bravo: Bob, Bella"></textarea>
        <br />
        <button type="submit">Provision speakers + create teams</button>
      </form>

      <h2>Add judges</h2>
      <p>One judge name per line.</p>
      <form phx-submit="add_judges">
        <textarea name="names" rows="3" cols="40" placeholder="Judge Judy&#10;Judge Dredd"></textarea>
        <br />
        <button type="submit">Provision judges</button>
      </form>

      <h2>Appoint organizer role</h2>
      <form phx-submit="add_organizer">
        <input type="text" name="user_id" placeholder="engine user id" size="12" />
        <select name="role">
          <option value="organiser">organiser</option>
          <option value="tab">tab</option>
          <option value="adjcore">adjcore</option>
        </select>
        <button type="submit">Grant role</button>
      </form>

      <h2>Teams ({length(@teams)})</h2>
      <table border="1" cellpadding="4">
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Speakers</th>
          <th>Flags</th>
        </tr>
        <tr :for={team <- @teams}>
          <td>{team["id"]}</td>
          <td>{team["name"]}</td>
          <td>{Enum.map_join(team["speakers"], ", ", & &1["name"])}</td>
          <td>
            {if team["is_swing"], do: "swing "}{if team["is_eliminated"], do: "eliminated "}{if team[
              "is_temporary"
            ],
              do: "temp"}
          </td>
        </tr>
      </table>

      <h2>Participants ({length(@participants)})</h2>
      <table border="1" cellpadding="4">
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Role</th>
          <th>Engine user</th>
          <th>Checked in</th>
        </tr>
        <tr :for={participant <- @participants}>
          <td>{participant["id"]}</td>
          <td>{participant["display_name"]}</td>
          <td>{participant["role"]}</td>
          <td>{participant["user_id"]}</td>
          <td>{if participant["checked_in"], do: "yes", else: "no"}</td>
        </tr>
      </table>

      <h2>Organizers</h2>
      <ul>
        <li :for={organizer <- @organizers}>
          user {organizer["user_id"]}
          ({get_in(organizer, ["User", "username"])}) — {organizer["role"]}
        </li>
      </ul>
    </div>
    """
  end
end
