# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
mix setup                       # install deps + assets.setup + assets.build
mix phx.server                  # run the server on localhost:4000
iex -S mix phx.server           # run with an interactive shell
mix test                        # run the full test suite
mix test path/to/file_test.exs            # run a single test file
mix test path/to/file_test.exs:42         # run the test at line 42
mix format                      # format code (.formatter.exs)
mix dialyzer                    # run dialyxir static analysis
mix assets.build                # build JS (esbuild) + CSS (tailwind), no Node
mix assets.deploy               # minify + digest assets for prod
```

There is no database — the project does not use Ecto. State lives entirely in memory (see below).

Assets use the **esbuild + Tailwind v4 standalone binaries** (no Node.js / `package.json`). The Tailwind theme tokens (brand purple `--color-brand`, `--color-paper/ink`, Funnel Display/Sans fonts, shadows) live in `assets/css/app.css`. Fonts (Funnel via Google Fonts) and icons (**Remix Icon** `ri-*`, via jsDelivr CDN) are linked in `root.html.heex`. `hero-*` utilities from `assets/vendor/heroicons.js` remain available but the UI uses Remix icons.

## Architecture

This is a **Phoenix 1.8 + LiveView app** (Bandit adapter) for "Quantotelarischi", a two-player Italian dare/bet game. The frontend is served directly from Phoenix as LiveViews — there is no separate frontend and no JSON API.

### Game state lives in supervised GenServers, not a database

Each game room is a `Quantomelarischio.Rooms.RoomServer` GenServer process. State is held in memory and lost on restart. The supervision tree (`application.ex`) wires three things together:

- **`Registry` (`Quantomelarischio.RoomRegistry`)** — maps `room_id` → pid. Processes register via `via_tuple/1`, so all callers address a room by its string id, never a pid.
- **`DynamicSupervisor` (`Quantomelarischio.RoomSupervisor`)** — starts/stops room processes on demand.
- Rooms auto-terminate: when both players leave, a `:shutdown_if_empty` message is scheduled (`Process.send_after`, 30s); the room stops only if still empty.

### Three-layer separation — keep logic in the right layer

1. **`Quantomelarischio.Rooms` (`rooms.ex`)** — the public context/API. Generates `room_id`s, starts rooms via the DynamicSupervisor, normalizes RoomServer replies, and exposes `subscribe/1` + `get_room/1` for LiveViews. Callers (LiveViews) only ever call this module.
2. **`Quantomelarischio.Rooms.RoomServer` (`room_server.ex`)** — the GenServer. It owns process concerns only: `call`/`cast` dispatch, registry naming, scheduling shutdown. **After every state transition it broadcasts `{:room_updated, room}`** on `Phoenix.PubSub` topic `"room:<id>"` (see `RoomServer.topic/1` and the private `broadcast/1`). It delegates all decisions to `Room`.
3. **`Quantomelarischio.Rooms.Room` (`room.ex`)** — a pure struct + functions. All game rules (join validation, bet validation, win/lose status resolution, reset) live here as side-effect-free functions returning `{:ok, state}` / `{:error, reason}`. **Put new game logic here**, not in the GenServer.

### Game model (maps the wireframe terms to struct fields)

`challenge_description` = the dare · `challenge_amount` = the pot ("posta", min 2) · `challenger_bet_amount`/`challenged_bet_amount` = the two **secret** numbers (1..pot−1). Verdict in `Room.place_bet/3`: when both numbers are in, `sum == pot` **or** numbers equal → status `"completed"` (**DEVI FARLO**); else `"not_completed"` (**TE LA SEI SCAMPATA**). Secret numbers are never rendered until status is set, so opponents can't see them mid-game.

### Web layer (LiveView)

- **Routes** (`router.ex`, `:browser` pipeline): `live "/"` → `HomeLive` (landing + come si gioca), `live "/new"` → `NewChallengeLive` (create a room), `live "/r/:room_id"` → `RoomLive` (the game).
- **`RoomLive`** is the stateful core: on connected mount it `subscribe`s + `join_room`s, then renders one of five phases derived purely from room state + the player's role — `lobby → set_amount → betting → verdict` (see `phase/1` and `role/2`). It reacts to `{:room_updated, room}` broadcasts and calls `leave_room` in `terminate/2`.
- **Identity:** the `:put_user_id` plug in `router.ex` assigns a stable anonymous `user_id` into the session (no real auth); LiveViews read it from `session["user_id"]` on mount.
- **Components:** `CoreComponents` (button/input/icon/flash, `@spec`'d, Gettext-backed), `Layouts` (root + app — the app layout holds the sticky top bar with logo + progress dots driven by each LiveView's `nav_step` assign), `ErrorHTML`. UI implements the final `Quantotelarischi.dc.html` design (purple/Funnel/Remix); copy is intentionally Italian. The losing verdict triggers a card shake + red flash (CSS) and a synthesized fart sound (the `Verdict` JS hook in `app.js`).

To add a new in-game action: add a context function in `Rooms`, the rule in `Room`, a `RoomServer` `handle_call` that broadcasts, and a `handle_event` + render branch in `RoomLive`.
