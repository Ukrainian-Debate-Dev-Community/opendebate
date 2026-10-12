defmodule UadebateWeb.ErrorHTML do
  @moduledoc "Error pages: a short page in the site's colours."
  use UadebateWeb, :html

  def render(template, _assigns) do
    status = Phoenix.Controller.status_message_from_template(template)

    """
    <!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{status} | UAdebate</title><link rel="stylesheet" href="/css/app.css"></head>
    <body><div class="ua"><main class="ua-main"><span class="ua-kicker">UAdebate</span>
    <h1>#{status}</h1><p class="ua-lead"><a href="/">#{gettext("Back to the home page")}</a></p>
    </main></div></body></html>
    """
  end
end
