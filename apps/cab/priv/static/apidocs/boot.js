// cab's API reference: Scalar, served by cab itself. Nothing is loaded
// from other companies: no default fonts, no telemetry, no AI agent or
// MCP, no request proxy (try-it calls go straight to cab) and no button
// out to Scalar's hosted client. The
// engine is internal, so its description has no try-it client.
(function () {
  var stored = null
  try { stored = localStorage.getItem("cab-theme") } catch (_e) {}
  var dark = stored === "dark" ||
    (stored !== "light" && window.matchMedia("(prefers-color-scheme: dark)").matches)
  document.body.classList.add(dark ? "dark-mode" : "light-mode")

  var el = document.getElementById("api-docs")
  var common = {
    theme: "none",
    withDefaultFonts: false,
    telemetry: false,
    proxyUrl: "",
    agent: { disabled: true },
    mcp: { disabled: true },
    darkMode: dark,
    showDeveloperTools: "never",
    // no button out to Scalar's hosted client (client.scalar.com):
    // try-it stays on this page
    hideClientButton: true
  }
  var cab = Object.assign({}, common, {
    title: el.dataset.cabTitle, slug: "cab", url: el.dataset.cabSpec, default: true
  })
  var engine = Object.assign({}, common, {
    title: el.dataset.engineTitle, slug: "engine", url: el.dataset.engineSpec,
    hideTestRequestButton: true
  })
  Scalar.createApiReference("#api-docs", [cab, engine])
})()
