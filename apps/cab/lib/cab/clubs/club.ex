defmodule Cab.Clubs.Club do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clubs" do
    field :name, :string
    field :city, :string
    field :university, :string
    field :meeting_hours, :string
    field :contact_telegram, :string
    field :engine_organisation_id, :integer
    field :visible, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(club, attrs) do
    club
    |> cast(attrs, [
      :name,
      :city,
      :university,
      :meeting_hours,
      :contact_telegram,
      :engine_organisation_id,
      :visible
    ])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
