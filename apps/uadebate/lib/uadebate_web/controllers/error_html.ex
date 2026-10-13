defmodule UadebateWeb.ErrorHTML do
  @moduledoc """
  Error pages: one centered block under the UAdebate wordmark, with
  plain links back into the site. A 404 never says why, so /manage
  stays unknown to anyone without access.
  """
  use UadebateWeb, :html

  def render(template, _assigns) do
    code = template |> String.split(".") |> hd()

    assigns = %{
      code: code,
      title: title(code),
      lead: lead(code),
      locale: Gettext.get_locale(UadebateWeb.Gettext)
    }

    ~H"""
    <!DOCTYPE html>
    <html lang={@locale}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@title} | UAdebate</title>
        <script>
          try {
            const theme = localStorage.getItem("uadebate-theme")
            if (theme === "light" || theme === "dark") document.documentElement.dataset.theme = theme
          } catch (_e) {}
        </script>
        <link rel="stylesheet" href={~p"/css/app.css"} />
      </head>
      <body>
        <div class="ua">
          <main class="ua-error">
            <a class="wordmark ua-error-mark" href={~p"/"}>UAdebate<.beta /></a>
            <span class="ua-kicker">{@code}</span>
            <h1>{@title}</h1>
            <p>{@lead}</p>
            <nav class="ua-error-links">
              <a href={~p"/"}>{gettext("Back to the home page")}</a>
              <a href={~p"/calendar"}>{gettext("Calendar")}</a>
              <a href={~p"/news"}>{gettext("News")}</a>
            </nav>
          </main>
        </div>
      </body>
    </html>
    """
  end

  defp title("404"), do: gettext("Page not found")
  defp title("500"), do: gettext("Something went wrong")
  defp title(code), do: Phoenix.Controller.status_message_from_template(code <> ".html")

  defp lead("404"), do: gettext("There is nothing at this address. It may have moved, or the link is mistyped.")
  defp lead("500"), do: gettext("We could not show this page. Please try again in a minute.")
  defp lead(_code), do: gettext("This page cannot be shown.")
end
