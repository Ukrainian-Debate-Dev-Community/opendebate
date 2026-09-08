defmodule Cab.Accounts.Identity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "identities" do
    field :provider, :string
    field :provider_uid, :string

    belongs_to :user, Cab.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :user_id])
    |> validate_required([:provider, :provider_uid, :user_id])
    |> unique_constraint([:provider, :provider_uid])
  end
end
