defmodule Mix.Tasks.Uadebate.Grant do
  @shortdoc "Grants a cab account the uadebate.com content-manager role"
  @moduledoc """
  For the first setup, before any cab admin has used /manage/people:

      mix uadebate.grant <username-or-email>

  The person must have signed in to cab at least once.
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run([login]) do
    case Cab.Accounts.get_user_by_login(login) do
      nil ->
        Mix.raise("no cab account with the username or e-mail #{inspect(login)}")

      user ->
        {:ok, _} = Uadebate.Roles.grant(user.id)
        Mix.shell().info("#{user.username} can now manage uadebate.com at /manage")
    end
  end

  def run(_args), do: Mix.raise("usage: mix uadebate.grant <username-or-email>")
end
