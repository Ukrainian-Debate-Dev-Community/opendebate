defmodule Uadebate do
  @moduledoc """
  Public portal facade (uadebate.com) — skeleton.

  The portal aggregates the other services read-only: tournaments,
  calendar and motions come from cab, public org documents from dfu.
  It consumes cab strictly through cab's public contexts — the
  dependency points down (uadebate -> cab -> core), never up.
  """

  @doc "Tournaments feed for the portal (calendar / front page)."
  defdelegate tournaments(params \\ []), to: Cab.EngineApi, as: :list_public_events
end
