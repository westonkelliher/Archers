extends Node
# Drop-in replacement for the GameNiteControlpads GDExtension node (which has
# no web binaries). Exposes the same surface main.gd uses:
#   signal message_received(client, message)
#   func send_message(client, message)
# Routes between input sources:
#   - "kbm"   : local keyboard/mouse player (state replies go to the HUD)
#   - "ws-*"  : remote browser players via the relay (added in netplay/relay.gd)

signal message_received(client, message)

const KBM_ID := "kbm"

var hud: CanvasLayer
var local_input: Node
var relay: Node = null # set when hosting a network game

func _ready():
	local_input = preload("res://netplay/local_input.gd").new()
	local_input.name = "LocalInput"
	add_child(local_input)
	local_input.message.connect(_on_local_message)

	hud = preload("res://netplay/net_hud.gd").new()
	hud.name = "NetHud"
	add_child(hud)
	hud.send.connect(_on_local_message)

func _on_local_message(msg: String):
	message_received.emit(KBM_ID, msg)

func send_message(client: String, msg: String):
	if client == KBM_ID:
		hud.receive_state(msg)
	elif client.begins_with("ws-") and relay != null:
		relay.send_to(client, msg)
