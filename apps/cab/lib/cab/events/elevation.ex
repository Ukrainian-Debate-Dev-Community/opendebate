defmodule Cab.Events.Elevation do
  @moduledoc """
  A per-event privilege grant: a gateway user acts as organiser, tab or
  adjudication-core member for one engine event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(organiser tab adjcore)

  schema "elevations" do
    field :engine_event_id, :integer
    field :role, :string

    belongs_to :user, Cab.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def roles, do: @roles

  def changeset(elevation, attrs) do
    elevation
    |> cast(attrs, [:user_id, :engine_event_id, :role])
    |> validate_required([:user_id, :engine_event_id, :role])
    |> validate_inclusion(:role, @roles)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :engine_event_id, :role])
  end
end
