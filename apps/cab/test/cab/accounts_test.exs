defmodule Cab.AccountsTest do
  use Cab.DataCase, async: true

  alias Cab.Accounts

  defp auth(overrides \\ %{}) do
    info =
      Map.merge(
        %{nickname: "debater", name: "Debate Person", email: "d@example.com", image: nil},
        Map.get(overrides, :info, %{})
      )

    %Ueberauth.Auth{
      provider: Map.get(overrides, :provider, :github),
      uid: Map.get(overrides, :uid, 12_345),
      info: struct(Ueberauth.Auth.Info, info)
    }
  end

  test "first oauth login creates user and identity" do
    assert {:ok, user} = Accounts.upsert_from_oauth(auth())
    assert user.username == "debater"
    assert user.email == "d@example.com"
    assert [identity] = Repo.preload(user, :identities).identities
    assert identity.provider == "github"
    assert identity.provider_uid == "12345"
  end

  test "second login with same identity reuses the user and refreshes profile" do
    {:ok, first} = Accounts.upsert_from_oauth(auth())

    {:ok, second} =
      Accounts.upsert_from_oauth(auth(%{info: %{name: "Renamed", email: "new@example.com"}}))

    assert second.id == first.id
    assert second.name == "Renamed"
    assert second.email == "new@example.com"
    assert Repo.aggregate(Accounts.User, :count) == 1
  end

  test "username collision from another provider gets a suffix" do
    {:ok, _github} = Accounts.upsert_from_oauth(auth())
    {:ok, google} = Accounts.upsert_from_oauth(auth(%{provider: :google, uid: 999}))

    assert google.username != "debater"
    assert String.starts_with?(google.username, "debater-")
  end
end
