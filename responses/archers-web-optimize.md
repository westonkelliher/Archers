# Archers → Browser Multiplayer: What to Optimize For

## Core factors
- **Join friction** — friends should go from "here's a link" (weston.pub) to in-game in seconds: no installs, accounts, or setup. This is the whole point of browser delivery.
- **Netcode feel under real latency** — dodging arrows is the game. Design must optimize for how fair/responsive hits and movement feel at 30–100ms between remote friends, not just LAN.
- **Bow-draw feel with mouse** — pull-*back* drag must read as power + aim with tactile clarity (draw distance ↔ power, release timing). The control scheme is the fun; it deserves first-class tuning priority.
- **Reuse of the existing Godot game** — maximize what carries over (scenes, combat, upgrades); the controlpad input layer is the main thing being replaced. Minimize rewrite surface.
- **Hosting simplicity on weston.pub** — one cheap, always-up or trivially-started server. Optimize for low ops burden over scalability; audience is a handful of friends.

## Secondary factors
- **Load time / export size** — Godot web exports are chunky; first-visit wait affects join friction.
- **Preserving game balance** — mouse aim is far more precise than controlpad; may shift what's fair.
- **Session ergonomics** — easy lobby/rejoin when someone drops or arrives late.

## Tensions to decide
- Authoritative-server fairness vs. responsiveness (and vs. hosting simplicity).
- Faithful port vs. rebalancing for keyboard+mouse precision.
