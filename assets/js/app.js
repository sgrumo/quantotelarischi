// Quantotelarischi LiveView client.
//
// Bundled by esbuild (no Node toolchain). Vendored JS deps are resolved from
// the `deps/` directory via the NODE_PATH set in config/config.exs.
import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

let Hooks = {}

// Copy-to-clipboard for the shareable room link (screen 03).
Hooks.CopyLink = {
  mounted() {
    this.el.addEventListener("click", () => {
      let text = this.el.dataset.clipboard
      navigator.clipboard?.writeText(text)
      let original = this.el.innerText
      this.el.innerText = "COPIATO!"
      setTimeout(() => (this.el.innerText = original), 1200)
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

liveSocket.connect()
window.liveSocket = liveSocket
