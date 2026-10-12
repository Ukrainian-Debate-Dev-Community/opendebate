import Config

# cab's test settings come from cab/config/test.exs (imported with cab's
# config.exs); only uadebate's are here.

config :uadebate, Uadebate.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "uadebate_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :uadebate, :uploads_dir, Path.join(System.tmp_dir!(), "uadebate-uploads-test")

config :uadebate, UadebateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "Tz8mK2vQ5nB1xR7cL4wH9dF3jS6pA0gE2uY5kN8tM1qV4zC7bX0rD3fG6hJ9wP2s",
  server: false
