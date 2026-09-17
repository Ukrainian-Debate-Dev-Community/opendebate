defmodule Uadebate.MixProject do
  use Mix.Project

  # L2 of the umbrella: the public portal (uadebate.com). Reads through
  # cab's public contexts; cab never depends on uadebate.
  def project do
    [
      app: :uadebate,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:core, in_umbrella: true},
      {:cab, in_umbrella: true}
    ]
  end
end
