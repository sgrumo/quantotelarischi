// Bundled by esbuild (no Node toolchain); imports resolve from `deps/` via the
// NODE_PATH set in config/config.exs.
import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

let Hooks = {}

Hooks.CopyLink = {
  mounted() {
    this.el.addEventListener("click", () => {
      let text = this.el.dataset.clipboard
      navigator.clipboard?.writeText(text)
      let original = this.el.innerHTML
      this.el.innerText = "Fatto"
      setTimeout(() => (this.el.innerHTML = original), 1400)
    })
  }
}

Hooks.Verdict = {
  mounted() {
    if (this.el.dataset.mustdo === "true") {
      this.playSound("/assets/bruh.mp3")
    } else {
      this.playSound("/assets/faaah.mp3")
    }
  },
  playSound(src) {
    try {
      let audio = new Audio(src)
      audio.play().catch(() => {})
    } catch (e) {}
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

liveSocket.connect()
window.liveSocket = liveSocket
