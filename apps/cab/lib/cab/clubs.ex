defmodule Cab.Clubs do
  @moduledoc """
  Debate clubs directory. Clubs are gateway-owned records that may be
  linked to an engine organisation via `engine_organisation_id`.
  """

  import Ecto.Query

  alias Cab.Clubs.Club
  alias Cab.Repo

  def list_clubs, do: Repo.all(from c in Club, order_by: c.name)

  def list_visible_clubs do
    Repo.all(from c in Club, where: c.visible == true, order_by: c.name)
  end

  def get_club(id), do: Repo.get(Club, id)

  def get_club!(id), do: Repo.get!(Club, id)

  def create_club(attrs) do
    %Club{}
    |> Club.changeset(attrs)
    |> Repo.insert()
  end

  def update_club(%Club{} = club, attrs) do
    club
    |> Club.changeset(attrs)
    |> Repo.update()
  end

  def delete_club(%Club{} = club), do: Repo.delete(club)

  def change_club(%Club{} = club, attrs \\ %{}), do: Club.changeset(club, attrs)

  @doc """
  Session history of a club's engine organisation: its events, each
  annotated with `"winner"` (winner of the event's last round; club
  sessions have exactly one round — no finals involved).
  """
  def club_history(actor, org_id) do
    with {:ok, events} <- Cab.EngineApi.list_organisation_events(actor, org_id) do
      {:ok, Enum.map(events, &Map.put(&1, "winner", Cab.Tournaments.event_winner(actor, &1)))}
    end
  end
end
