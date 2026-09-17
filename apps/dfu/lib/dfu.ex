defmodule Dfu do
  @moduledoc """
  NGO cabinet (dfu.uadebate.com) — skeleton.

  Will own digital post / journal numbers, cases (open / waiting /
  closed), scoped votes with quorum, and internal announcements, with
  its own Repo and migrations. Identity comes from cab (SSO); the
  dependency points down (dfu -> cab -> core), never up.
  """
end
