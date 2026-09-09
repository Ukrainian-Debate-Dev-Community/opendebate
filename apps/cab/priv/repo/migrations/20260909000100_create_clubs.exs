defmodule Cab.Repo.Migrations.CreateClubs do
  use Ecto.Migration

  def change do
    create table(:clubs) do
      add :name, :string, null: false
      add :city, :string
      add :university, :string
      add :meeting_hours, :string
      add :contact_telegram, :string
      # organisation id in the node engine, linked when the club goes online
      add :engine_organisation_id, :integer
      add :visible, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:clubs, [:name])
  end
end
