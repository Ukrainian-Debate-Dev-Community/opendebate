defmodule CabWeb.Router do
  use CabWeb, :router

  import CabWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CabWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Server-to-server API for the uadebate.com portal (static bearer token).
  pipeline :public_api do
    plug :accepts, ["json"]
    plug CabWeb.Plugs.PortalApiAuth
  end

  scope "/", CabWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/auth", CabWeb do
    pipe_through :browser

    get "/logout", AuthController, :logout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Robust plain-HTML MVP: full-control tournament direction.
  scope "/mvp", CabWeb do
    pipe_through :browser

    live_session :mvp, on_mount: {CabWeb.MvpAuth, :current_user} do
      live "/", MvpLive.Dashboard
      live "/club", MvpLive.Club
      live "/t/:id", MvpLive.Tournament
      live "/t/:id/setup", MvpLive.Setup
      live "/t/:id/r/:n/checkin", MvpLive.Checkin
      live "/t/:id/r/:n/draw", MvpLive.Draw
      live "/t/:id/r/:n/ballots", MvpLive.Ballots
    end
  end

  scope "/api/public", CabWeb do
    pipe_through :public_api

    get "/tournaments", PublicApiController, :tournaments
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:cab, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CabWeb.Telemetry

      # DEV ONLY: session user switcher for the MVP pages (bypasses OAuth).
      get "/switch-user", CabWeb.DevSessionController, :switch
    end
  end
end
