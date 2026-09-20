# Archers online

* Play: https://weston.pub/archers/ — share the `?room=` link; first one in hosts.
* Host's browser runs the game; `worker.js` (Durable Object per room) relays websockets.
* `./build.sh` exports the game (Godot 4.4.1 + web templates), `npx wrangler deploy` ships it.
* Local: `npx wrangler dev`, then http://localhost:8787/archers/
* Headless test player: `godot --headless --audio-driver Dummy -- --bot --room=x --server=ws://localhost:8787`
