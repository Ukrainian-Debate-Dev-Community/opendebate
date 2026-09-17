defmodule UadebateTest do
  use ExUnit.Case, async: true

  test "portal reads tournaments through cab's public context" do
    Req.Test.stub(Core.Engine, fn conn ->
      assert conn.request_path == "/api/events"

      Req.Test.json(conn, %{
        "status" => "success",
        "data" => [%{"id" => 1, "name" => "Kyiv Open", "status" => "scheduled"}]
      })
    end)

    assert {:ok, [%{"name" => "Kyiv Open"}]} = Uadebate.tournaments()
  end

  test "portal aggregates public documents from dfu" do
    assert is_list(Uadebate.documents())
  end
end
