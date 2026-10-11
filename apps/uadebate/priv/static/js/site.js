// The header's theme button: each click moves light -> auto -> dark.
// auto follows the system; the choice is kept in this browser only.
// The language menu closes on any click outside it or on Escape.
(() => {
  const key = "uadebate-theme"
  const themes = ["light", "auto", "dark"]
  const stored = () => {
    try { return localStorage.getItem(key) || "auto" } catch (_e) { return "auto" }
  }
  const mark = () => {
    const current = stored()
    document.querySelectorAll('[data-cycle="theme"]').forEach(b => {
      b.dataset.state = current
      const label = b.dataset["label" + current.charAt(0).toUpperCase() + current.slice(1)]
      if (label) b.setAttribute("aria-label", label)
    })
  }
  const apply = choice => {
    if (choice === "auto") delete document.documentElement.dataset.theme
    else document.documentElement.dataset.theme = choice
    try {
      choice === "auto" ? localStorage.removeItem(key) : localStorage.setItem(key, choice)
    } catch (_e) { /* private mode */ }
    mark()
  }
  document.addEventListener("click", e => {
    const button = e.target.closest('[data-cycle="theme"]')
    if (button) apply(themes[(themes.indexOf(stored()) + 1) % themes.length])
    document.querySelectorAll("details[data-langs][open]").forEach(d => {
      if (!d.contains(e.target)) d.open = false
    })
  })
  document.addEventListener("keydown", e => {
    if (e.key === "Escape") document.querySelectorAll("details[data-langs][open]").forEach(d => { d.open = false })
  })
  mark()
})()
