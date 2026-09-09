defmodule Cab.ClubsTest do
  use Cab.DataCase, async: true

  alias Cab.Clubs
  alias Cab.Clubs.Club

  @valid_attrs %{
    name: "DC Phoenix",
    city: "Kyiv",
    university: "KNU",
    meeting_hours: "Wed 18:00",
    contact_telegram: "@dcphoenix",
    engine_organisation_id: 11,
    visible: true
  }

  test "create_club/1 with valid attrs persists the club" do
    assert {:ok, %Club{} = club} = Clubs.create_club(@valid_attrs)
    assert club.name == "DC Phoenix"
    assert club.engine_organisation_id == 11
    assert club.visible
  end

  test "create_club/1 requires a name" do
    assert {:error, changeset} = Clubs.create_club(%{city: "Kyiv"})
    assert %{name: ["can't be blank"]} = errors_on(changeset)
  end

  test "visible defaults to false" do
    assert {:ok, club} = Clubs.create_club(%{name: "Hidden Club"})
    refute club.visible
  end

  test "club names are unique" do
    assert {:ok, _} = Clubs.create_club(%{name: "DC Phoenix"})
    assert {:error, changeset} = Clubs.create_club(%{name: "DC Phoenix"})
    assert %{name: ["has already been taken"]} = errors_on(changeset)
  end

  test "list_clubs/0 and list_visible_clubs/0" do
    {:ok, visible} = Clubs.create_club(%{name: "A Club", visible: true})
    {:ok, hidden} = Clubs.create_club(%{name: "B Club"})

    assert Enum.map(Clubs.list_clubs(), & &1.id) == [visible.id, hidden.id]
    assert Enum.map(Clubs.list_visible_clubs(), & &1.id) == [visible.id]
  end

  test "get_club/1, update_club/2 and delete_club/1" do
    {:ok, club} = Clubs.create_club(@valid_attrs)

    assert Clubs.get_club(club.id).id == club.id

    assert {:ok, updated} = Clubs.update_club(club, %{city: "Lviv"})
    assert updated.city == "Lviv"

    assert {:ok, _} = Clubs.delete_club(club)
    assert Clubs.get_club(club.id) == nil
  end

  test "change_club/2 returns a changeset" do
    assert %Ecto.Changeset{} = Clubs.change_club(%Club{}, %{name: "X"})
  end
end
