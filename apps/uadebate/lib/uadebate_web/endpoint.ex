defmodule UadebateWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :uadebate

  # uadebate's own small cookie, only for the forms under /manage
  # (CSRF and flash). Public pages never fetch a session, so they never
  # set or read a cookie; the sign-in is cab's, read in UadebateWeb.ManageAccess.
  @session_options [
    store: :cookie,
    key: "_uadebate_key",
    signing_salt: "m7Qz4kWp",
    same_site: "Lax"
  ]

  plug Plug.Static, at: "/", from: :uadebate, gzip: false, only: UadebateWeb.static_paths()
  plug UadebateWeb.UploadsStatic

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Parsers, parsers: [:urlencoded, :multipart], pass: ["*/*"]
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug UadebateWeb.Router
end
