# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# cab and core: their own configuration from the cab submodule (it
# imports cab's dev.exs / test.exs / prod.exs in turn). Only what
# uadebate changes is overridden below and in this folder's env files.
import_config "../cab/config/config.exs"

# cab's asset builders find phoenix, phoenix_html and phoenix_live_view
# in the deps folder: here it is this umbrella's, not the submodule's
node_path = %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
config :esbuild, :cab, env: node_path
config :tailwind, :cab, env: node_path

# Who runs this cab: the name, links and addresses in cab's footer, on
# its sign-in and account pages
config :cab, :operator, UadebateWeb.CabOperator

# uadebate.com: its own repo (news, events, roles) and endpoint. It
# reads cab downward; :cab_url is where its Cabinet links point.
config :uadebate,
  ecto_repos: [Uadebate.Repo],
  generators: [timestamp_type: :utc_datetime]

config :uadebate, UadebateWeb.Gettext, default_locale: "en", locales: ~w(en uk)

config :uadebate, UadebateWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: UadebateWeb.ErrorHTML], layout: false]

config :uadebate, :cab_url, "http://localhost:4000"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
