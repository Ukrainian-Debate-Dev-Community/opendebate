defmodule CabWeb.Plugs.PortalApiAuth do
  @moduledoc """
  Guards the public portal API with a static bearer token
  (`PORTAL_API_TOKEN`). Meant for the uadebate.com portal, not for
  end users.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.get_env(:cab, :portal_api_token)

    with true <- is_binary(expected) and expected != "",
         ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         true <- Plug.Crypto.secure_compare(token, expected) do
      conn
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "unauthorized"}))
        |> halt()
    end
  end
end
