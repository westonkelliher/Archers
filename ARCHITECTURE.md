# Architecture (web multiplayer port)

## Now (v1): host-authoritative browser + relay
- **Game core** (existing Godot scenes/scripts) is untouched where possible. Its input boundary is the GameNite controlpad string protocol (`move:x,y`, `bow:x,y`, `upgrade:*`, `ready`, `name:*`) — we reuse it verbatim as the network protocol.
- **`netplay/local_input.gd`** — keyboard/mouse → protocol strings (LMB drag-*back* to draw; release fires opposite the drag). Any input source is just a `(client_id, msg)` emitter.
- **`netplay/relay.gd`** — WebSocket to a Cloudflare Durable Object room. Host mode: receives clients' input strings, broadcasts state snapshots. Client mode: sends inputs, applies snapshots.
- **Snapshots**: host serializes entity state to JSON @ ~20Hz; clients render *puppet-mode* instances of the real scenes (physics/collision off, `apply_state()`), so visuals never fork from the game.
- **`web/`** — Cloudflare worker: static Godot web export + `ArchersRoom` DO (dumb relay, room-per-code). Self-contained; deploys independently of weston.pub.

## Why
Zero-install join (URL → playing), one cheap serverless host, and ~90% reuse of the existing game.

## Evolution path (commercial fork)
1. **Dedicated authoritative server**: relay DO already isolates transport; swap "host browser" for headless Godot on a VM — game core unchanged.
2. **Client prediction + interpolation** for the local player (snapshot layer already isolates rendering from simulation).
3. **Binary snapshots** (delta-compressed) replacing JSON — only `relay.gd` serialize/deserialize changes.
4. **Extract game rules from main.gd** (round/lobby state machine) into a sim module with no rendering, enabling server builds without assets.
