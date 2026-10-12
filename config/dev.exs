import Config

# cab's development settings come from cab/config/dev.exs (imported with
# cab's config.exs); only uadebate's and the overrides are here.

# Policy and Terms: the server checkout next to this repo (uadebate-server
# after the rename, opendebate-server until then); LEGAL_DIR in .env wins
config :cab,
       :legal_dir,
       Enum.find(
         [
           Path.expand("../../uadebate-server/legal", __DIR__),
           Path.expand("../../opendebate-server/legal", __DIR__)
         ],
         Path.expand("../../opendebate-server/legal", __DIR__),
         &File.dir?/1
       )

# uadebate.com on :4001, its own database
config :uadebate, Uadebate.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "uadebate_dev",
  port: 5432,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 5

config :uadebate, UadebateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Wq3oV0bKq8fD2n7mS5yH1cR4tL9xE6jA0pZ3uG8vN2kT7wB5sY1dF4hJ6mQ9rX2c"

# news cover images (gitignored)
config :uadebate, :uploads_dir, Path.expand("../uploads", __DIR__)
