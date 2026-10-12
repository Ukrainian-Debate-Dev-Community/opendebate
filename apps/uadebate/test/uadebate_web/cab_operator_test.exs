defmodule UadebateWeb.CabOperatorTest do
  use UadebateWeb.ConnCase

  alias UadebateWeb.CabOperator

  defp uk(msgid), do: Gettext.with_locale(UadebateWeb.Gettext, "uk", fn -> Gettext.gettext(UadebateWeb.Gettext, msgid) end)

  test "cab runs with uadebate as its operator" do
    assert Application.get_env(:cab, :operator) == CabOperator
  end

  test "the texts follow cab's locale, the links and addresses stay" do
    en = Gettext.with_locale(CabWeb.Gettext, "en", &CabOperator.info/0)
    ua = Gettext.with_locale(CabWeb.Gettext, "uk", &CabOperator.info/0)

    assert en.org_label == "DFU"
    assert ua.org_label == uk("DFU")
    assert ua.org_label != en.org_label
    assert ua.about != en.about
    assert ua.org_text != en.org_text
    assert ua.signin_foot != en.signin_foot
    assert String.ends_with?(ua.signin_foot, " uadebate.com")

    for key <- [:site_url, :org_url, :contact_email, :support_email] do
      assert ua[key] == en[key]
    end

    assert en.site_url == "https://uadebate.com"
    assert en.support_email == "support@uadebate.com"
  end

  defp cab_page(path, headers \\ []) do
    headers
    |> Enum.reduce(build_conn(), fn {k, v}, conn -> put_req_header(conn, k, v) end)
    |> Phoenix.ConnTest.dispatch(CabWeb.Endpoint, :get, path)
    |> html_response(200)
  end

  test "cab's pages show them in the visitor's language" do
    en = Gettext.with_locale(CabWeb.Gettext, "en", &CabOperator.info/0)
    ua = Gettext.with_locale(CabWeb.Gettext, "uk", &CabOperator.info/0)

    assert cab_page("/signin") =~ en.signin_foot
    assert cab_page("/signin", [{"accept-language", "uk"}]) =~ ua.signin_foot

    footer = cab_page("/policy")
    assert footer =~ en.org_text
    assert footer =~ en.about
    assert footer =~ "mailto:ngo.dfu@uadebate.com"

    footer = cab_page("/policy", [{"accept-language", "uk"}])
    assert footer =~ ua.org_text
    assert footer =~ ua.about
    refute footer =~ en.org_text
  end
end
