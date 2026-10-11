defmodule UadebateWeb.PublicPagesTest do
  use UadebateWeb.ConnCase

  alias Uadebate.{Events, News, Roles}

  @pages ["/", "/news", "/calendar", "/clubs", "/about"]

  test "every public page renders and sets no cookie", %{conn: conn} do
    for path <- @pages do
      resp = get(conn, path)
      assert html_response(resp, 200) =~ "UAdebates"
      assert get_resp_header(resp, "set-cookie") == [], "#{path} set a cookie"
    end
  end

  test "a signed-in editor sees exactly what everyone sees", %{conn: conn} do
    editor = cab_user()
    {:ok, _} = Roles.grant(editor.id)
    admin = cab_user(%{is_admin: true})

    for path <- @pages do
      anonymous = conn |> get(path) |> html_response(200)
      assert conn |> cab_sign_in(editor) |> get(path) |> html_response(200) == anonymous
      assert conn |> cab_sign_in(admin) |> get(path) |> html_response(200) == anonymous
      refute anonymous =~ "ua-cmbar"
      refute anonymous =~ "Sign in"
    end
  end

  test "published news is public; drafts stay hidden", %{conn: conn} do
    {:ok, shown} = News.create(%{"title" => "Kyiv Open results", "body" => "**Winners**"}, 1)
    {:ok, _} = News.publish(shown, 1)
    {:ok, draft} = News.create(%{"title" => "Secret plans"}, 1)

    html = conn |> get(~p"/news") |> html_response(200)
    assert html =~ "Kyiv Open results"
    refute html =~ "Secret plans"

    article = conn |> get(~p"/news/kyiv-open-results") |> html_response(200)
    assert article =~ "<strong>Winners</strong>"

    assert_error_sent 404, fn -> get(conn, ~p"/news/#{draft.slug}") end
  end

  test "private events never leave /manage", %{conn: conn} do
    today = Date.utc_today()
    {:ok, _} = Events.create(%{"title" => "Open Cup", "starts_on" => today}, 1)

    {:ok, _} =
      Events.create(%{"title" => "Board meeting", "starts_on" => today, "visibility" => "private"}, 1)

    for path <- ["/", "/calendar", "/calendar.ics"] do
      body = conn |> get(path) |> response(200)
      assert body =~ "Open Cup"
      refute body =~ "Board meeting", "#{path} shows a private event"
    end
  end

  test "the iCal feed is a calendar of the public events", %{conn: conn} do
    {:ok, _} =
      Events.create(%{"title" => "Kharkiv Open, BP", "starts_on" => ~D[2026-11-14], "city" => "Kharkiv"}, 1)

    resp = get(conn, ~p"/calendar.ics")
    assert ["text/calendar" <> _] = get_resp_header(resp, "content-type")
    body = response(resp, 200)
    assert body =~ "BEGIN:VCALENDAR\r\n"
    assert body =~ "SUMMARY:Kharkiv Open\\, BP\r\n"
    assert body =~ "DTSTART;VALUE=DATE:20261114\r\n"
    assert body =~ "DTEND;VALUE=DATE:20261115\r\n"
  end

  test "clubs come from cab, filtered by city and format", %{conn: conn} do
    head = cab_user(%{name: "Olena Head"})

    kyiv =
      cab_club(head, %{name: "Kyiv Debate Club", city: "Kyiv", formats: ["bp"], languages: ["uk"]})

    _lviv = cab_club(head, %{name: "Lviv Club", city: "Lviv", formats: ["apf"]})

    all = conn |> get(~p"/clubs") |> html_response(200)
    assert all =~ "Kyiv Debate Club" and all =~ "Lviv Club"

    by_city = conn |> get(~p"/clubs?#{[city: "Lviv"]}") |> html_response(200)
    assert by_city =~ "Lviv Club"
    refute by_city =~ "Kyiv Debate Club"

    by_format = conn |> get(~p"/clubs?#{[format: "bp"]}") |> html_response(200)
    assert by_format =~ "Kyiv Debate Club"
    refute by_format =~ "Lviv Club"

    page = conn |> get(~p"/clubs/#{kyiv.uuid}") |> html_response(200)
    assert page =~ "Olena Head"
    assert page =~ "/c/#{kyiv.uuid}"
    assert page =~ "Club details are kept by the club in cab."
  end

  test "an archived or unknown club is not found", %{conn: conn} do
    club = cab_club(cab_user())
    {:ok, _} = Cab.Clubs.archive_club(club)

    assert_error_sent 404, fn -> get(conn, ~p"/clubs/#{club.uuid}") end
    assert_error_sent 404, fn -> get(conn, "/clubs/not-a-uuid") end
  end
end
