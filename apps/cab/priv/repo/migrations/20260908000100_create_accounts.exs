defmodule Cab.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :name, :string
      add :email, :string
      add :avatar_url, :string
      add :is_admin, :boolean, default: false, null: false
      # principal id in the node engine, provisioned on first login
      add :node_user_id, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:node_user_id])

    create table(:identities) do
      add :provider, :string, null: false
      add :provider_uid, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:identities, [:provider, :provider_uid])
    create index(:identities, [:user_id])
  end
end
