extends Node
# WebSocket link to the ArchersRoom Durable Object (web/src/index.js).
# Wire format is JSON objects:
#   client -> DO:   {"msg": "<protocol string>"}
#   DO -> host:     {"from": "ws-3", "msg": "..."} | {"joined": id} | {"left": id}
#   host -> DO:     {"to": "ws-3", "msg": "..."} | {"snap": {...}} (broadcast)
#   DO -> client:   {"msg": "state:..."} | {"snap": {...}} | {"hostGone": true}

signal input_received(cid, msg) # host mode
signal snap_received(snap)      # client mode
signal state_received(msg)      # client mode
signal status_changed(status)   # "connecting" | "open" | "closed" | "hostGone"

const PROD_URL := "wss://archers.weston.pub"

var ws := WebSocketPeer.new()
var role := "join"
var _was_open := false

func start(p_role: String, room: String):
	role = p_role
	var base := OS.get_environment("ARCHERS_WS")
	if base == "":
		if OS.has_feature("web"):
			var loc = JavaScriptBridge.eval("(location.protocol=='https:'?'wss://':'ws://')+location.host")
			base = str(loc)
		else:
			base = PROD_URL
	ws.connect_to_url("%s/ws?room=%s&role=%s" % [base, room.uri_encode(), role])
	status_changed.emit("connecting")

func _process(_delta):
	ws.poll()
	var state := ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not _was_open:
		_was_open = true
		status_changed.emit("open")
	elif state == WebSocketPeer.STATE_CLOSED and _was_open:
		_was_open = false
		status_changed.emit("closed")
	while state == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count() > 0:
		var data = JSON.parse_string(ws.get_packet().get_string_from_utf8())
		if data == null:
			continue
		if data.has("snap"):
			snap_received.emit(data.snap)
		elif data.has("from"):
			input_received.emit(data.from, data.msg)
		elif data.has("msg"):
			state_received.emit(data.msg)
		elif data.has("hostGone"):
			status_changed.emit("hostGone")

func _send(obj: Dictionary):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(obj))

func send_input(msg: String): # client -> host
	_send({"msg": msg})

func send_to(cid: String, msg: String): # host -> one client
	_send({"to": cid, "msg": msg})

func broadcast_snap(snap: Dictionary): # host -> all clients
	_send({"snap": snap})
