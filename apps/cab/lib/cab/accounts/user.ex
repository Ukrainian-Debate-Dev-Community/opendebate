defmodule Cab.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string
    field :is_admin, :boolean, default: false
    field :node_user_id, :integer

    has_many :identities, Cab.Accounts.Identity

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :name, :email, :avatar_url, :node_user_id])
    |> validate_required([:username])
    |> unique_constraint(:username)
    |> unique_constraint(:node_user_id)
  end
end
