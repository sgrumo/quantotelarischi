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

// Copy-to-clipboard for the shareable room link.
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

// On a losing verdict ("DEVI FARLO"), play a synthesized fart. Ported from the design.
Hooks.Verdict = {
  mounted() {
    if (this.el.dataset.mustdo === "true") this.playFart()
  },
  playFart() {
    try {
      let Ctx = window.AudioContext || window.webkitAudioContext
      let ctx = new Ctx()
      let dur = 0.65
      let now = ctx.currentTime
      let o = ctx.createOscillator()
      let g = ctx.createGain()
      o.type = "sawtooth"
      o.frequency.setValueAtTime(155, now)
      o.frequency.exponentialRampToValueAtTime(55, now + dur)
      let lfo = ctx.createOscillator()
      let lfoGain = ctx.createGain()
      lfo.type = "square"
      lfo.frequency.setValueAtTime(22, now)
      lfo.frequency.exponentialRampToValueAtTime(9, now + dur)
      lfoGain.gain.value = 48
      lfo.connect(lfoGain)
      lfoGain.connect(o.frequency)
      g.gain.setValueAtTime(0.0001, now)
      g.gain.exponentialRampToValueAtTime(0.42, now + 0.05)
      g.gain.exponentialRampToValueAtTime(0.0001, now + dur)
      o.connect(g)
      g.connect(ctx.destination)
      o.start(now)
      lfo.start(now)
      o.stop(now + dur)
      lfo.stop(now + dur)
      setTimeout(() => { try { ctx.close() } catch (e) {} }, 900)
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
