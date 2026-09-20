# Archers online

* Play: https://weston.pub/archers/ — share the `?room=` link; first one in hosts.
* `./host.sh [room]` hosts a room headless from this machine (steadier than a browser tab host; start it before anyone joins).
* Otherwise the first browser in a room runs the game; `worker.js` (Durable Object per room) relays websockets.
* `./build.sh` exports the game (Godot 4.4.1 + web templates), `npx wrangler deploy` ships it.
* Local: `npx wrangler dev`, then http://localhost:8787/archers/
* Headless test player: `godot --headless --audio-driver Dummy -- --bot --room=x --server=ws://localhost:8787`
