defmodule Cab.Repo do
  use Ecto.Repo,
    otp_app: :cab,
    adapter: Ecto.Adapters.Postgres
end
