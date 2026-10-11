defmodule UadebateWeb.Router do
  use UadebateWeb, :router

  # Public pages read nothing about the visitor: no session, no cookie.
  # They look the same for everyone, content managers included.
  pipeline :public do
    plug :accepts, ["html"]
    plug UadebateWeb.Locale
    plug :put_root_layout, html: {UadebateWeb.Layouts, :root}
    plug :put_secure_browser_headers
  end

  # /manage: the only place that knows who is signed in; 404 for anyone
  # without the content-manager role, so the public never sees it exists.
  pipeline :manage do
    plug :accepts, ["html"]
    plug UadebateWeb.ManageAccess
    plug UadebateWeb.Locale
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_root_layout, html: {UadebateWeb.Layouts, :root}
    plug :put_secure_browser_headers
  end

  scope "/", UadebateWeb do
    get "/calendar.ics", CalendarController, :ics
    # the language menu: sets its own cookie, never the session
    get "/locale/:locale", LocaleController, :set
  end

  scope "/", UadebateWeb do
    pipe_through :public

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/news", NewsController, :index
    get "/news/:slug", NewsController, :show
    get "/calendar", CalendarController, :index
    get "/clubs", ClubController, :index
    get "/clubs/:uuid", ClubController, :show
  end

  scope "/manage", UadebateWeb.Manage do
    pipe_through :manage

    get "/", DashController, :show

    get "/news", NewsController, :index
    get "/news/new", NewsController, :new
    post "/news", NewsController, :create
    get "/news/:id/edit", NewsController, :edit
    put "/news/:id", NewsController, :update
    post "/news/:id/publish", NewsController, :publish
    post "/news/:id/unpublish", NewsController, :unpublish

    get "/calendar", CalendarController, :index
    post "/calendar/public", CalendarController, :set_public
    get "/events/new", EventController, :new
    post "/events", EventController, :create
    get "/events/:id/edit", EventController, :edit
    put "/events/:id", EventController, :update
    delete "/events/:id", EventController, :delete
    post "/events/:id/visibility", EventController, :visibility

    get "/people", PeopleController, :index
    post "/people", PeopleController, :grant
    delete "/people/:user_id", PeopleController, :revoke
  end
end
