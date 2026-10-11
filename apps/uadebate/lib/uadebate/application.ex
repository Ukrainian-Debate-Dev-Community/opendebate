defmodule Uadebate.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Uadebate.Repo,
      UadebateWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Uadebate.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    UadebateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
