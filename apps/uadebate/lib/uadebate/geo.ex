defmodule Uadebate.Geo do
  @moduledoc """
  uadebate's own map of Ukraine: a simplified outline and the points of
  the cities it knows, in the 640x440 space of the site's SVG map
  (longitude and latitude projected as on the design board). Clubs are
  placed by the city cab gives; nothing is stored per club.
  """

  @outline "11.9,214.2 27.2,178.5 30.6,153.0 61.2,112.2 78.2,86.7 71.4,51.0 88.4,35.7 125.8,34.7 159.8,40.8 204.0,51.0 234.6,58.6 255.0,61.2 285.6,56.1 299.2,66.3 309.4,28.1 340.0,25.5 367.2,15.3 387.6,12.8 418.2,45.9 428.4,68.9 452.2,71.4 462.4,102.0 489.6,112.2 533.8,114.8 550.8,135.1 591.6,142.8 622.2,153.0 622.2,170.9 608.6,193.8 618.8,221.9 612.0,242.2 578.0,242.2 557.6,280.5 533.8,290.7 503.2,298.4 462.4,316.2 442.0,326.4 448.8,351.9 472.6,367.2 499.8,369.8 462.4,397.8 428.4,413.1 397.8,408.0 363.8,367.2 380.8,341.7 404.6,329.0 377.4,331.5 329.8,311.1 302.6,311.1 268.6,367.2 238.0,369.8 217.6,362.1 241.4,316.2 275.4,316.2 282.2,295.8 265.2,270.3 251.6,239.7 217.6,224.4 193.8,211.6 163.2,221.9 108.8,239.7 74.8,237.1 47.6,229.5 27.2,229.5"

  @cities %{
    "Chernihiv" => {322.7, 56.6},
    "Chernivtsi" => {140.8, 219.8},
    "Dnipro" => {450.5, 211.1},
    "Ivano-Frankivsk" => {98.9, 187.7},
    "Kharkiv" => {490.6, 133.1},
    "Khmelnytskyi" => {176.5, 162.2},
    "Kremenchuk" => {395.1, 180.0},
    "Krolevets" => {394.1, 53.6},
    "Kyiv" => {296.5, 109.6},
    "Lutsk" => {120.4, 94.4},
    "Lviv" => {75.8, 140.8},
    "Odesa" => {303.6, 312.1},
    "Ostroh" => {160.5, 115.8},
    "Poltava" => {433.5, 153.5},
    "Rivne" => {151.3, 101.0},
    "Vinnytsia" => {226.8, 171.9},
    "Zaporizhzhia" => {453.6, 242.8}
  }

  # the sixteen branches on the old site's About map, in its order
  @branches ~w(Kharkiv Odesa Kyiv Lutsk Chernihiv Zaporizhzhia Rivne Vinnytsia Khmelnytskyi Ostroh Dnipro Chernivtsi Kremenchuk Krolevets Lviv Ivano-Frankivsk)

  def outline, do: @outline

  @doc "The {x, y} point of a city, or nil when the map does not know it."
  def point(nil), do: nil
  def point(city), do: Map.get(@cities, String.trim(city))

  def branches, do: Enum.map(@branches, &{&1, Map.fetch!(@cities, &1)})
end
