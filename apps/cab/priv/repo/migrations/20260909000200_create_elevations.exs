defmodule Cab.Repo.Migrations.CreateElevations do
  use Ecto.Migration

  def change do
    create table(:elevations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      # event id in the node engine (events are not mirrored locally)
      add :engine_event_id, :integer, null: false
      add :role, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:elevations, [:user_id, :engine_event_id, :role])
    create index(:elevations, [:engine_event_id])
  end
end
