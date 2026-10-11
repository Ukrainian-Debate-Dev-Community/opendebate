defmodule Mix.Tasks.Uadebate.GrantTest do
  use UadebateWeb.ConnCase

  test "mix uadebate.grant gives a cab account the role" do
    user = cab_user(%{username: "first-editor"})
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)

    Mix.Tasks.Uadebate.Grant.run(["first-editor"])
    assert Uadebate.Roles.content_manager?(user.id)
    assert_received {:mix_shell, :info, [msg]}
    assert msg =~ "first-editor"

    assert_raise Mix.Error, fn -> Mix.Tasks.Uadebate.Grant.run(["nobody-here"]) end
  end
end
