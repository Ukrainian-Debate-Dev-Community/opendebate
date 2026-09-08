defmodule Cab.Accounts do
  @moduledoc """
  OAuth-backed accounts. Users sign in only via external providers;
  an Identity row links each (provider, uid) pair to a User.
  """

  import Ecto.Query

  alias Cab.Accounts.{Identity, User}
  alias Cab.Repo

  def get_user(id), do: Repo.get(User, id)

  @doc """
  Finds the user for an Ueberauth result, creating user + identity on
  first login. Profile fields are refreshed from the provider each time.
  """
  def upsert_from_oauth(%Ueberauth.Auth{} = auth) do
    provider = to_string(auth.provider)
    uid = to_string(auth.uid)

    attrs = %{
      username: auth.info.nickname || auth.info.email || "#{provider}-#{uid}",
      name: auth.info.name,
      email: auth.info.email,
      avatar_url: auth.info.image
    }

    case Repo.one(from i in Identity, where: [provider: ^provider, provider_uid: ^uid]) do
      %Identity{user_id: user_id} ->
        get_user(user_id)
        |> User.changeset(Map.delete(attrs, :username))
        |> Repo.update()

      nil ->
        create_from_oauth(provider, uid, attrs)
    end
  end

  defp create_from_oauth(provider, uid, attrs) do
    Repo.transaction(fn ->
      user =
        %User{}
        |> User.changeset(attrs)
        |> ensure_free_username()
        |> Repo.insert!()

      %Identity{}
      |> Identity.changeset(%{provider: provider, provider_uid: uid, user_id: user.id})
      |> Repo.insert!()

      user
    end)
  end

  defp ensure_free_username(changeset) do
    username = Ecto.Changeset.get_field(changeset, :username)

    if Repo.exists?(from u in User, where: u.username == ^username) do
      suffix = :crypto.strong_rand_bytes(3) |> Base.encode16(case: :lower)
      Ecto.Changeset.put_change(changeset, :username, "#{username}-#{suffix}")
    else
      changeset
    end
  end
end
