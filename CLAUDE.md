# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
mix setup                       # install deps (alias for deps.get)
mix phx.server                  # run the server on localhost:4000
iex -S mix phx.server           # run with an interactive shell
mix test                        # run the full test suite
mix test path/to/file_test.exs            # run a single test file
mix test path/to/file_test.exs:42         # run the test at line 42
mix format                      # format code (.formatter.exs)
mix dialyzer                    # run dialyxir static analysis
```

There is no database — the project does not use Ecto. State lives entirely in memory (see below).

## Architecture

This is an **API-only Phoenix 1.7 backend** (Bandit adapter) for a two-player betting game. There is no HTML rendering beyond the dev LiveDashboard; clients interact over a single HTTP endpoint plus a WebSocket channel.

### Game state lives in supervised GenServers, not a database

Each game room is a `Quantomelarischio.Rooms.RoomServer` GenServer process. State is held in memory and lost on restart. The supervision tree (`application.ex`) wires three things together:

- **`Registry` (`Quantomelarischio.RoomRegistry`)** — maps `room_id` → pid. Processes register via `via_tuple/1`, so all callers address a room by its string id, never a pid.
- **`DynamicSupervisor` (`Quantomelarischio.RoomSupervisor`)** — starts/stops room processes on demand.
- Rooms auto-terminate: when both players leave, a `:shutdown_if_empty` message is scheduled (`Process.send_after`, 30s); the room stops only if still empty.

### Three-layer separation — keep logic in the right layer

1. **`Quantomelarischio.Rooms` (`rooms.ex`)** — the public context/API. Generates `room_id`s, starts rooms via the DynamicSupervisor, and normalizes RoomServer replies. Callers (controllers, channel handlers) only ever call this module.
2. **`Quantomelarischio.Rooms.RoomServer` (`room_server.ex`)** — the GenServer. It owns process concerns only: `call`/`cast` dispatch, registry naming, scheduling shutdown. It delegates all decisions to `Room`.
3. **`Quantomelarischio.Rooms.Room` (`room.ex`)** — a pure struct + functions. All game rules (join validation, bet validation, win/lose status resolution, reset) live here as side-effect-free functions returning `{:ok, state}` / `{:error, reason}`. **Put new game logic here**, not in the GenServer — this is the pattern established by the recent refactor (commit `24c6797` "move business logic from genserver to appropriate handler").

The `Room` struct uses `@derive Jason.Encoder` with an explicit `only:` allowlist — fields not in that list are never serialized to clients.

### Request/message entry points

- **HTTP:** `POST /api/rooms` (`RoomController.create`) is the only REST route — it creates a room and returns `{room_id}`. Everything else happens over the socket.
- **WebSocket:** `UserSocket` mounts at `/socket`. On connect it assigns a random `user_id` (no real auth — `auth_token: false`). `RoomChannel` joins topic `"room:<room_id>"`.
- **Channel events** are whitelisted in `RoomChannel.@possible_messages` and dispatched to **`BetHandler.handle/3`** (`channels/handlers/bet_handler.ex`). To add a new in-game action: add the event name to `@possible_messages`, add a `handle/3` clause in `BetHandler`, and add the corresponding context function in `Rooms` + business logic in `Room`. `BetHandler` is responsible for `Endpoint.broadcast`ing the resulting event to the room topic.

### Origin / CORS

WebSocket origin checking uses `config :quantomelarischio, :allowed_origins` (see `dev.exs` for the dev allowlist, `endpoint.ex` for how it's read at compile time). `cors_plug` is a dependency for HTTP CORS.
