defmodule UadebateWeb.Site do
  @moduledoc """
  The site's pieces, ported from the design board (uadebate v6): the
  header and footer every page shares, the ribbon under /manage, page
  heads, tags, news cards, event rows, the month grid and the maps.
  """
  use Phoenix.Component
  use Gettext, backend: UadebateWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: UadebateWeb.Endpoint,
    router: UadebateWeb.Router,
    statics: UadebateWeb.static_paths()

  alias Uadebate.Geo

  @doc "Where cab lives; the Cabinet, Policy, Terms and club links point there."
  def cab_url(path \\ ""), do: Application.fetch_env!(:uadebate, :cab_url) <> path

  # ---------------------------------------------------------------
  # frame
  # ---------------------------------------------------------------

  attr :active, :atom, default: nil

  def site_header(assigns) do
    assigns =
      assign(assigns, :items, [
        {:home, ~p"/", gettext("Home")},
        {:news, ~p"/news", gettext("News")},
        {:calendar, ~p"/calendar", gettext("Calendar")},
        {:clubs, ~p"/clubs", gettext("Clubs")},
        {:about, ~p"/about", gettext("About")}
      ])

    ~H"""
    <header class="ua-top">
      <a class="ua-brand wordmark" href={~p"/"}>UAdebates</a>
      <nav class="ua-nav">
        <a :for={{key, href, label} <- @items} class={key == @active && "on"} href={href}>{label}</a>
      </nav>
      <div class="ua-right">
        <a class="ua-btn ua-btn--line ua-btn--sm" href={cab_url()}>{gettext("Cabinet")}</a>
      </div>
    </header>
    """
  end

  attr :access, :atom, required: true
  attr :manager, :map, required: true
  attr :active, :atom, default: nil

  def ribbon(assigns) do
    items = [
      {:dash, ~p"/manage", gettext("Overview")},
      {:news, ~p"/manage/news", gettext("News")},
      {:calendar, ~p"/manage/calendar", gettext("Calendar")}
    ]

    items =
      if assigns.access == :admin,
        do: items ++ [{:people, ~p"/manage/people", gettext("People")}],
        else: items

    assigns = assign(assigns, :items, items)

    ~H"""
    <div class="ua-cmbar">
      <span class="ua-cmrole">
        {if @access == :admin, do: gettext("Admin"), else: gettext("Content manager")}
      </span>
      <a :for={{key, href, label} <- @items} class={key == @active && "on"} href={href}>{label}</a>
      <span class="ua-cmme">
        <span class="ua-av">{initials(@manager)}</span>{display_name(@manager)}
      </span>
      <a class="ua-cmlink" href={~p"/"}>{gettext("View site")}</a>
      <a class="ua-cmlink" href={cab_url("/auth/logout")}>{gettext("Sign out")}</a>
    </div>
    """
  end

  def site_footer(assigns) do
    ~H"""
    <footer class="ua-foot">
      <div class="ua-foot-in ua-foot-in--3">
        <div>
          <a class="wordmark ua-foot-mark" href={~p"/"}>UAdebates</a>
          <p>{gettext("Debate Federation of Ukraine")}</p>
          <p>{gettext("A debate community since 2011")}</p>
        </div>
        <div>
          <b>{gettext("Site")}</b>
          <a href={~p"/news"}>{gettext("News")}</a>
          <a href={~p"/calendar"}>{gettext("Calendar")}</a>
          <a href={~p"/clubs"}>{gettext("Clubs")}</a>
          <a href={~p"/about"}>{gettext("About")}</a>
        </div>
        <div>
          <b>{gettext("Platform")}</b>
          <a href={cab_url()}>{gettext("Cabinet (cab)")}</a>
          <a href={cab_url("/policy")}>{gettext("Privacy policy")}</a>
          <a href={cab_url("/terms")}>{gettext("Terms of use")}</a>
        </div>
        <div>
          <b>{gettext("Contact")}</b>
          <a href="mailto:ngo.dfu@uadebate.com">ngo.dfu@uadebate.com</a>
          <a href="mailto:support@uadebate.com">support@uadebate.com</a>
          <a href="https://t.me/fdu_ua">t.me/fdu_ua</a>
        </div>
      </div>
    </footer>
    """
  end

  # ---------------------------------------------------------------
  # page pieces
  # ---------------------------------------------------------------

  attr :kicker, :string, required: true
  attr :title, :string, required: true
  attr :lead, :string, default: nil
  slot :actions

  def page_head(assigns) do
    ~H"""
    <div class="ua-head">
      <div>
        <span class="ua-kicker">{@kicker}</span>
        <h1>{@title}</h1>
        <p :if={@lead} class="ua-lead">{@lead}</p>
      </div>
      <div :if={@actions != []} class="ua-head-act">{render_slot(@actions)}</div>
    </div>
    """
  end

  attr :kind, :string, default: nil
  slot :inner_block, required: true

  def tag(assigns) do
    ~H"""
    <span class={["ua-tag", @kind && "ua-tag--#{@kind}"]}>{render_slot(@inner_block)}</span>
    """
  end

  attr :post, :map, required: true

  def news_card(assigns) do
    ~H"""
    <article class="ua-card ua-news">
      <div class={["ua-cover", "c#{rem(@post.id, 3) + 1}"]}>
        <.tag kind="cover">{rubric_label(@post.rubric)}</.tag>
      </div>
      <div class="ua-pad">
        <h3><a href={~p"/news/#{@post.slug}"}>{@post.title}</a></h3>
        <div class="ua-meta">
          {long_date(@post.published_at)}, {gettext("%{n} min read", n: read_minutes(@post.body))}
        </div>
      </div>
    </article>
    """
  end

  attr :event, :map, required: true
  slot :inner_block

  def event_row(assigns) do
    ~H"""
    <div class={["ua-ev", @event.visibility == "private" && "ua-ev--priv"]}>
      <.date_badge date={@event.starts_on} />
      <div class="ua-ev-body">
        <h4>
          <a :if={@event.link} href={@event.link}>{@event.title}</a>
          <span :if={!@event.link}>{@event.title}</span>
        </h4>
        <div class="ua-meta">{event_meta(@event)}</div>
      </div>
      <%= if @event.visibility == "private" do %>
        <.tag kind="priv">{gettext("Private")}</.tag>
      <% else %>
        <.tag kind={if @event.kind == "tournament", do: "ok", else: "info"}>
          {kind_label(@event.kind)}
        </.tag>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :date, Date, required: true

  def date_badge(assigns) do
    ~H"""
    <span class="ua-date"><b>{pad(@date.day)}</b><span>{short_month(@date.month)}</span></span>
    """
  end

  attr :first, Date, required: true
  attr :events, :list, required: true

  def month_grid(assigns) do
    first = assigns.first
    start = Date.beginning_of_week(first)
    stop = Date.end_of_week(Date.end_of_month(first))
    weeks = Date.range(start, stop) |> Enum.chunk_every(7)

    assigns =
      assign(assigns,
        weeks: weeks,
        heads: [
          gettext("Mon"),
          gettext("Tue"),
          gettext("Wed"),
          gettext("Thu"),
          gettext("Fri"),
          gettext("Sat"),
          gettext("Sun")
        ]
      )

    ~H"""
    <div class="ua-cal">
      <div class="ua-cal-h"><span :for={h <- @heads}>{h}</span></div>
      <div :for={week <- @weeks} class="ua-cal-w">
        <div :for={day <- week} class={["ua-day", day.month != @first.month && "out"]}>
          <span class="n">{day.day}</span>
          <span
            :for={e <- Enum.filter(@events, &on_day?(&1, day))}
            class={["ua-chip", e.visibility == "private" && "ua-chip--priv"]}
          >
            {e.title}
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp on_day?(event, day),
    do:
      Date.compare(event.starts_on, day) != :gt and
        Date.compare(event.ends_on || event.starts_on, day) != :lt

  @doc "The club map: a dot per city with clubs, sized by their number; a dot filters the list."
  attr :counts, :map, required: true
  attr :selected, :string, default: nil
  attr :labels, :boolean, default: true

  def club_map(assigns) do
    dots =
      for {city, n} <- assigns.counts, point = Geo.point(city), point != nil do
        {city, n, point, 7 + 3 * (min(n, 6) - 1)}
      end

    assigns = assign(assigns, dots: dots, outline: Geo.outline())

    ~H"""
    <svg
      class="ua-map"
      viewBox="0 0 640 440"
      role="img"
      aria-label={gettext("Map of debate clubs in Ukraine")}
    >
      <polygon class="ua-land" points={@outline} />
      <a
        :for={{city, n, {x, y}, r} <- @dots}
        class={["ua-city", city == @selected && "on"]}
        href={~p"/clubs?#{[city: city]}"}
      >
        <circle cx={x} cy={y} r={r} />
        <text :if={@labels} x={x + r + 5} y={y + 4}>{city}{if n > 1, do: " #{n}"}</text>
      </a>
    </svg>
    """
  end

  @doc "The old site's map of the sixteen branches; a city opens Clubs filtered to it."
  def branch_map(assigns) do
    assigns = assign(assigns, branches: Geo.branches(), outline: Geo.outline())

    ~H"""
    <svg
      class="ua-map ua-map--branches"
      viewBox="0 0 640 440"
      role="img"
      aria-label={gettext("Branches of the federation")}
    >
      <polygon class="ua-land" points={@outline} />
      <a :for={{city, {x, y}} <- @branches} class="ua-branch" href={~p"/clubs?#{[city: city]}"}>
        <circle cx={x} cy={y} r="5" />
        <text {branch_label(city, x, y)}>{city}</text>
      </a>
    </svg>
    """
  end

  defp branch_label(city, x, y) when city in ~w(Lutsk Lviv Khmelnytskyi Chernihiv),
    do: %{x: x - 9, y: y + 5, "text-anchor": "end"}

  defp branch_label("Ostroh", x, y), do: %{x: x + 9, y: y + 17}
  defp branch_label(_city, x, y), do: %{x: x + 9, y: y + 5}

  # ---------------------------------------------------------------
  # words
  # ---------------------------------------------------------------

  def rubric_label("announcements"), do: gettext("Announcements")
  def rubric_label("results"), do: gettext("Results")
  def rubric_label("interviews"), do: gettext("Interviews")
  def rubric_label("tips"), do: gettext("Tips")
  def rubric_label(_), do: gettext("Community")

  def kind_label("tournament"), do: gettext("Tournament")
  def kind_label("training"), do: gettext("Training")
  def kind_label("club"), do: gettext("Club event")
  def kind_label(_), do: gettext("Event")

  def format_label("bp"), do: gettext("BP")
  def format_label("apf"), do: gettext("APF")
  def format_label(_), do: gettext("Other format")

  def language_label("uk"), do: gettext("Ukrainian")
  def language_label("en"), do: gettext("English")
  def language_label(_), do: gettext("Other language")

  def audience_label("school"), do: gettext("School students")
  def audience_label("university"), do: gettext("University students")
  def audience_label(_), do: gettext("Open to all")

  def event_meta(event) do
    [kind_label(event.kind), event.city, event.format]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
  end

  def month_name(n) do
    Enum.at(
      [
        gettext("January"),
        gettext("February"),
        gettext("March"),
        gettext("April"),
        gettext("May"),
        gettext("June"),
        gettext("July"),
        gettext("August"),
        gettext("September"),
        gettext("October"),
        gettext("November"),
        gettext("December")
      ],
      n - 1
    )
  end

  def short_month(n) do
    Enum.at(
      [
        gettext("Jan"),
        gettext("Feb"),
        gettext("Mar"),
        gettext("Apr"),
        gettext("May"),
        gettext("Jun"),
        gettext("Jul"),
        gettext("Aug"),
        gettext("Sep"),
        gettext("Oct"),
        gettext("Nov"),
        gettext("Dec")
      ],
      n - 1
    )
  end

  def long_date(nil), do: gettext("Draft")
  def long_date(%DateTime{} = at), do: long_date(DateTime.to_date(at))
  def long_date(%Date{} = d), do: "#{d.day} #{month_name(d.month)} #{d.year}"

  def read_minutes(body), do: max(1, div(length(String.split(body || "")), 200))

  def display_name(user), do: user.name || user.username

  def initials(user) do
    user
    |> display_name()
    |> String.split()
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
