defmodule UadebateWeb do
  @moduledoc "The web layer of uadebate.com: `use UadebateWeb, :controller` and friends."

  def static_paths, do: ~w(css fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html]
      use Gettext, backend: UadebateWeb.Gettext
      import Plug.Conn
      import Phoenix.Component, only: [to_form: 2]
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller, only: [get_csrf_token: 0]
      use Gettext, backend: UadebateWeb.Gettext
      import UadebateWeb.Site
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: UadebateWeb.Endpoint,
        router: UadebateWeb.Router,
        statics: UadebateWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
