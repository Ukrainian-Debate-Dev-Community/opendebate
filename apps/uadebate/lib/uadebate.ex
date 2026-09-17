defmodule Uadebate do
  @moduledoc """
  Public portal facade (uadebate.com) — skeleton.

  The facade at the top of the platform: it aggregates the other
  services read-only. Tournaments, calendar and motions come from
  cab; public org documents come from dfu. Dependencies point down
  (uadebate -> dfu -> cab -> core), never up.
  """

  @doc "Tournaments feed for the portal (calendar / front page)."
  defdelegate tournaments(params \\ []), to: Cab.EngineApi, as: :list_public_events

  @doc "Public org documents feed (from the dfu cabinet)."
  defdelegate documents, to: Dfu, as: :public_documents
end
