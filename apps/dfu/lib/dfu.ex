defmodule Dfu do
  @moduledoc """
  NGO cabinet (dfu.uadebate.com) - skeleton.

  Will own digital post / journal numbers, cases (open / waiting /
  closed), scoped votes with quorum, and internal announcements, with
  its own Repo and migrations. Identity comes from cab (SSO); the
  dependency points down (dfu -> cab -> core). uadebate, above,
  aggregates the public subset exposed here - never the reverse.
  """

  @doc """
  Public subset of org documents for the portal. Placeholder until the
  document store lands; the contract (list of maps with `title` and
  `published_at`) is what uadebate builds against.
  """
  def public_documents, do: []
end
