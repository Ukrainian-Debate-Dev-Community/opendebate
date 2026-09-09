defmodule Cab.Events do
  @moduledoc """
  Event-scoped concerns on the gateway side. Events themselves live in
  the Node engine; the gateway only tracks per-event privilege
  elevations (organiser / tab / adjcore).
  """

  import Ecto.Query

  alias Cab.Accounts.User
  alias Cab.Events.Elevation
  alias Cab.Repo

  def grant_elevation(%User{id: user_id}, engine_event_id, role),
    do: grant_elevation(user_id, engine_event_id, role)

  def grant_elevation(user_id, engine_event_id, role) do
    %Elevation{}
    |> Elevation.changeset(%{user_id: user_id, engine_event_id: engine_event_id, role: role})
    |> Repo.insert()
  end

  def revoke_elevation(%User{id: user_id}, engine_event_id, role),
    do: revoke_elevation(user_id, engine_event_id, role)

  def revoke_elevation(user_id, engine_event_id, role) do
    {count, _} =
      Repo.delete_all(
        from e in Elevation,
          where:
            e.user_id == ^user_id and e.engine_event_id == ^engine_event_id and
              e.role == ^role
      )

    if count > 0, do: :ok, else: {:error, :not_found}
  end

  def list_elevations_for_user(%User{id: user_id}), do: list_elevations_for_user(user_id)

  def list_elevations_for_user(user_id) do
    Repo.all(
      from e in Elevation,
        where: e.user_id == ^user_id,
        order_by: [e.engine_event_id, e.role]
    )
  end

  def elevated?(user_id, engine_event_id, role) do
    Repo.exists?(
      from e in Elevation,
        where:
          e.user_id == ^user_id and e.engine_event_id == ^engine_event_id and
            e.role == ^role
    )
  end
end
