defmodule Cab.EventsTest do
  use Cab.DataCase, async: true

  alias Cab.Accounts.User
  alias Cab.Events
  alias Cab.Events.Elevation

  defp user(username \\ "organiser") do
    Repo.insert!(%User{username: username})
  end

  test "grant_elevation/3 creates an elevation for a valid role" do
    u = user()

    assert {:ok, %Elevation{} = elevation} = Events.grant_elevation(u, 101, "organiser")
    assert elevation.user_id == u.id
    assert elevation.engine_event_id == 101
    assert elevation.role == "organiser"
  end

  test "grant_elevation/3 rejects unknown roles" do
    u = user()

    assert {:error, changeset} = Events.grant_elevation(u, 101, "supreme-leader")
    assert %{role: ["is invalid"]} = errors_on(changeset)
  end

  test "the same grant cannot be issued twice" do
    u = user()

    assert {:ok, _} = Events.grant_elevation(u, 101, "tab")
    assert {:error, changeset} = Events.grant_elevation(u, 101, "tab")
    refute changeset.valid?
  end

  test "revoke_elevation/3 deletes the grant" do
    u = user()
    {:ok, _} = Events.grant_elevation(u, 101, "adjcore")

    assert :ok = Events.revoke_elevation(u, 101, "adjcore")
    refute Events.elevated?(u.id, 101, "adjcore")
    assert {:error, :not_found} = Events.revoke_elevation(u, 101, "adjcore")
  end

  test "list_elevations_for_user/1 returns only that user's grants" do
    u1 = user("one")
    u2 = user("two")
    {:ok, _} = Events.grant_elevation(u1, 101, "organiser")
    {:ok, _} = Events.grant_elevation(u1, 102, "tab")
    {:ok, _} = Events.grant_elevation(u2, 101, "tab")

    assert [%{engine_event_id: 101, role: "organiser"}, %{engine_event_id: 102, role: "tab"}] =
             Events.list_elevations_for_user(u1)
  end

  test "elevated?/3 matches exact user, event and role" do
    u = user()
    {:ok, _} = Events.grant_elevation(u, 101, "organiser")

    assert Events.elevated?(u.id, 101, "organiser")
    refute Events.elevated?(u.id, 101, "tab")
    refute Events.elevated?(u.id, 999, "organiser")
  end
end
