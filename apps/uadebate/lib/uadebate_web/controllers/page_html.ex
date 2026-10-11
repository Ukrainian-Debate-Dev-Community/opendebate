defmodule UadebateWeb.PageHTML do
  use UadebateWeb, :html

  embed_templates "page_html/*"

  # the start of the story, as on the old site's About page
  def story do
    [
      {"2011", gettext("First founding conference of the federation")},
      {"2012", gettext("First tournament, the Federation Cup in Vinnytsia")},
      {"2013", gettext("First Ukrainian Debate Championship")},
      {"2015", gettext("11 regional and 2 city branches; the first English-language league")}
    ]
  end

  # the year line of the old site's About page, dates as there
  def timeline do
    [
      {"2011",
       [
         {"07/05/2011",
          gettext(
            "First founding conference of the All-Ukrainian youth organisation \"Debate Federation of Ukraine\""
          )}
       ]},
      {"2012",
       [
         {"06/2012",
          gettext(
            "First debate tournament, the Federation Cup in Vinnytsia, for members of the organisation"
          )}
       ]},
      {"2013", [{"09-11/05/2013", gettext("First Ukrainian Debate Championship")}]},
      {"2015",
       [
         {"03/2015",
          gettext("The number of branches grew to 11 regional and 2 city branches of the DFU")},
         {"12/2015", gettext("The first English-language debate league was held in Kharkiv")}
       ]}
    ]
  end

  # entries alternate left and right of the year line
  def timeline_sides do
    {items, _} =
      Enum.map_reduce(timeline(), 0, fn {year, entries}, n ->
        sided = entries |> Enum.with_index(n) |> Enum.map(fn {e, i} -> {e, rem(i, 2)} end)
        {{year, sided}, n + length(entries)}
      end)

    items
  end
end
