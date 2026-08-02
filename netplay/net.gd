extends Node
# Drop-in replacement for the GameNiteControlpads GDExtension node (which has
# no web binaries). Exposes the same surface main.gd uses:
#   signal message_received(client, message)
#   func send_message(client, message)
# Modes (Autoloader.net_mode):
#   local  - keyboard/mouse feeds the local sim directly
#   host   - local sim + relay: remote inputs in, snapshots out (20Hz)
#   client - no sim; inputs go to the relay, snapshots drive puppets

signal message_received(client, message)

const KBM_ID := "kbm"
const SNAP_INTERVAL := 0.05

var mode := "local"
var hud: CanvasLayer
var local_input: Node
var relay: Node = null
var puppets: Node = null
var _snap_accum := 0.0

func _ready():
	mode = Autoloader.net_mode
	local_input = preload("res://netplay/local_input.gd").new()
	local_input.name = "LocalInput"
	add_child(local_input)
	local_input.message.connect(_on_local_message)

	hud = preload("res://netplay/net_hud.gd").new()
	hud.name = "NetHud"
	add_child(hud)
	hud.send.connect(_on_local_message)

	if mode != "local":
		relay = preload("res://netplay/relay.gd").new()
		relay.name = "Relay"
		add_child(relay)
		relay.status_changed.connect(hud.set_status)
	if mode == "host":
		relay.input_received.connect(func(cid, msg): message_received.emit(cid, msg))
		relay.start("host", Autoloader.net_room)
		hud.show_invite(Autoloader.net_room)
	elif mode == "client":
		puppets = preload("res://netplay/puppets.gd").new()
		puppets.name = "Puppets"
		add_child(puppets)
		relay.snap_received.connect(func(snap): puppets.apply(snap))
		relay.state_received.connect(hud.receive_state)
		relay.start("join", Autoloader.net_room)

func _process(delta):
	if mode != "host":
		return
	_snap_accum += delta
	if _snap_accum >= SNAP_INTERVAL:
		_snap_accum = 0.0
		relay.broadcast_snap(NetSnapshot.capture(Autoloader.mainScene))

func _on_local_message(msg: String):
	if mode == "client":
		relay.send_input(msg)
	else:
		message_received.emit(KBM_ID, msg)

func send_message(client: String, msg: String):
	if client == KBM_ID:
		hud.receive_state(msg)
	elif client.begins_with("ws-") and relay != null:
		relay.send_to(client, msg)
