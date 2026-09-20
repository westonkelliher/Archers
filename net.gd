extends Node
# Online play. The first peer in a room is the host and runs the whole
# simulation; everyone else sends input and renders the host's snapshots.
# All traffic goes through the websocket relay in web/worker.js:
#   text frames   = control messages from the relay (welcome/join/leave)
#   binary frames = var_to_bytes game data. Host prefixes 2 bytes of target id
#                   (0 = everyone); the relay prefixes 2 bytes of sender id on
#                   anything it forwards to the host.

signal welcomed()
signal peer_joined(id, peer_name)
signal peer_left(id)
signal packet(from_id, data)
signal closed()

const DEFAULT_SERVER = "ws://localhost:8787"

var ws : WebSocketPeer = null
var my_id = 0
var my_name = ""
var room = "local"
var server = DEFAULT_SERVER
var is_host = false
var is_client = false
var offline = false
var bot = false # drive this player with tests/bot.gd
var dedicated = false # host a room without playing in it, see web/host.sh
var status = "Connecting..."
var peers = {}  # id -> name, everyone in the room including me

var _events = []


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func start():
	_read_config()
	if offline:
		_become_offline_host()
		return
	ws = WebSocketPeer.new()
	ws.inbound_buffer_size = 1 << 20
	ws.outbound_buffer_size = 1 << 20
	var url = "%s/archers/ws?room=%s&name=%s" % [server, room.uri_encode(), my_name.uri_encode()]
	var err = ws.connect_to_url(url)
	if err != OK:
		status = "Could not connect (error %d)" % err
		ws = null


func _read_config():
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("JSON.stringify(window.ARCHERS_CFG || {})", true)
		var cfg = JSON.parse_string(raw) if raw else {}
		if cfg == null:
			cfg = {}
		room = str(cfg.get("room", room))
		my_name = str(cfg.get("name", ""))
		bot = bool(cfg.get("bot", false))
		var proto = JavaScriptBridge.eval("location.protocol", true)
		var host = JavaScriptBridge.eval("location.host", true)
		server = ("wss://" if proto == "https:" else "ws://") + str(host)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			room = arg.trim_prefix("--room=")
		elif arg.begins_with("--name="):
			my_name = arg.trim_prefix("--name=")
		elif arg.begins_with("--server="):
			server = arg.trim_prefix("--server=")
		elif arg == "--offline":
			offline = true
		elif arg == "--bot":
			bot = true
		elif arg == "--dedicated":
			dedicated = true
			Engine.max_fps = 60 # headless has no vsync to hold it back


func _become_offline_host():
	offline = true
	is_host = true
	my_id = 1
	peers = {1: my_name}
	status = "Offline"
	emit_signal("welcomed")


func _process(_delta):
	if ws == null:
		return
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			var bytes = ws.get_packet()
			if ws.was_string_packet():
				_on_control(bytes.get_string_from_utf8())
			else:
				_on_data(bytes)
	elif state == WebSocketPeer.STATE_CLOSED:
		var reason = ws.get_close_reason()
		ws = null
		if my_id == 0:
			status = "Could not reach the game server"
		elif reason != "":
			status = reason
		else:
			status = "Connection lost"
		emit_signal("closed")
		if dedicated:
			print("dedicated host: ", status)
			get_tree().quit(1)


func _on_control(text):
	var msg = JSON.parse_string(text)
	if typeof(msg) != TYPE_DICTIONARY:
		return
	match msg.get("t"):
		"welcome":
			my_id = int(msg["id"])
			is_host = bool(msg["host"])
			is_client = not is_host
			peers = {}
			for p in msg["peers"]:
				peers[int(p["id"])] = str(p["name"])
			peers[my_id] = my_name
			status = "Connected"
			if dedicated and not is_host:
				print("dedicated host: room '%s' already has a host" % room)
				get_tree().quit(2)
				return
			if dedicated:
				print("dedicated host: serving room '%s'" % room)
			emit_signal("welcomed")
		"join":
			peers[int(msg["id"])] = str(msg["name"])
			emit_signal("peer_joined", int(msg["id"]), str(msg["name"]))
		"leave":
			peers.erase(int(msg["id"]))
			emit_signal("peer_left", int(msg["id"]))


func _on_data(bytes : PackedByteArray):
	var from = 0
	if is_host:
		if bytes.size() < 3:
			return
		from = bytes.decode_u16(0)
		bytes = bytes.slice(2)
	var data = bytes_to_var(bytes)
	if data != null:
		emit_signal("packet", from, data)


func _send(target, data):
	if ws == null or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var payload = var_to_bytes(data)
	if is_host:
		var framed = PackedByteArray([target & 0xff, (target >> 8) & 0xff])
		framed.append_array(payload)
		ws.send(framed)
	else:
		ws.send(payload)


func broadcast(data):
	_send(0, data)

func send_to(id, data):
	_send(id, data)

func send_host(data):
	_send(0, data)

func has_clients():
	return is_host and peers.size() > 1


################################################################################
# One-shot things the host wants every client to see. They ride along on
# the next snapshot (the websocket is ordered + reliable so none get lost).

func event(ev : Array):
	if has_clients():
		_events.append(ev)

func take_events():
	var out = _events
	_events = []
	return out
