defmodule UadebateWeb.HealthTest do
  use UadebateWeb.ConnCase

  test "GET /healthz answers ok and sets no cookie", %{conn: conn} do
    conn = get(conn, "/healthz")
    assert response(conn, 200) == "ok"
    assert get_resp_header(conn, "set-cookie") == []
  end

  test "the release can migrate" do
    Code.ensure_loaded!(Uadebate.Release)
    assert function_exported?(Uadebate.Release, :migrate, 0)
  end
end
