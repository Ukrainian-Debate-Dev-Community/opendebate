defmodule CabWeb.MvpComponents do
  @moduledoc """
  Plain-HTML shared components for the MVP pages: top navigation with
  the flow links, inline error line, current-user badge.
  """

  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: CabWeb.Endpoint, router: CabWeb.Router

  attr :current_user, :any, default: nil
  attr :event_id, :any, default: nil
  attr :rounds, :list, default: []

  def mvp_nav(assigns) do
    ~H"""
    <nav style="border-bottom: 1px solid #999; padding-bottom: 0.5em; margin-bottom: 1em;">
      <a href={~p"/mvp"}>Dashboard</a>
      | <a href={~p"/mvp/club"}>Club session</a>
      <span :if={@event_id}>
        | <a href={~p"/mvp/t/#{@event_id}"}>Tournament</a>
        | <a href={~p"/mvp/t/#{@event_id}/setup"}>Setup</a>
        <span :for={round <- @rounds}>
          | R{round["sequence"]}:
          <a href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/checkin"}>check-in</a>
          / <a href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/draw"}>draw</a>
          / <a href={~p"/mvp/t/#{@event_id}/r/#{round["sequence"]}/ballots"}>ballots</a>
        </span>
      </span>
      <span style="float: right;">
        <span :if={@current_user}>
          user: <strong>{@current_user.username}</strong>
          (engine id: {@current_user.node_user_id || "?"})
        </span>
        <span :if={is_nil(@current_user)}>not signed in</span>
      </span>
    </nav>
    """
  end

  attr :error, :any, default: nil

  def mvp_error(assigns) do
    ~H"""
    <p :if={@error} style="color: #b00020; border: 1px solid #b00020; padding: 0.5em;">
      Error: {@error}
    </p>
    """
  end
end
