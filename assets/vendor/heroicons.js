// Tailwind v4 plugin that exposes the Heroicons set fetched into deps/heroicons
// as `hero-<name>`, `hero-<name>-solid`, `hero-<name>-mini`, `hero-<name>-micro`
// utility classes (rendered via mask-image so they inherit currentColor).
const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = plugin(function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, "../../deps/heroicons/optimized")
  let values = {}
  let icons = [
    ["", "/24/outline"],
    ["-solid", "/24/solid"],
    ["-mini", "/20/solid"],
    ["-micro", "/16/solid"]
  ]

  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
      let name = path.basename(file, ".svg") + suffix
      values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
    })
  })

  matchComponents(
    {
      hero: ({ name, fullPath }) => {
        let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
        let size = theme("spacing.6")
        if (name.endsWith("-mini")) {
          size = theme("spacing.5")
        } else if (name.endsWith("-micro")) {
          size = theme("spacing.4")
        }
        return {
          width: size,
          height: size,
          "mask-image": `url('data:image/svg+xml;utf8,${content}')`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block"
        }
      }
    },
    { values }
  )
})
