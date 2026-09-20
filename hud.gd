extends Control
# Room info + controls while in the lobby, and a notice if the connection dies

var info = Label.new()
var notice = Label.new()
var ping = Label.new()
var main = null


func _ready():
	main = Autoloader.mainScene
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	UITheme.style_label(info, 26)
	info.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	info.grow_horizontal = Control.GROW_DIRECTION_BOTH
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info.offset_bottom = -110
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info)

	UITheme.style_label(notice, 44, UITheme.ALERT)
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notice.grow_vertical = Control.GROW_DIRECTION_BOTH
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.visible = false
	add_child(notice)
	UITheme.style_label(ping, 18, UITheme.TEXT_MUTED)
	ping.position = Vector2(12, 8)
	ping.visible = Net.is_client
	add_child(ping)
	Net.closed.connect(_on_closed)


func _process(_delta):
	if ping.visible:
		ping.text = "ping %d ms" % main.get_node("Replicator").pingMs
	var inLobby = main.get_node("MenuElements").position == Vector2.ZERO
	info.visible = inLobby and not notice.visible
	if not info.visible:
		return
	info.text = "WASD to move  -  hold left mouse to draw, release to shoot\n"
	if Net.offline:
		info.text += "Offline"
	else:
		info.text += "Room \"%s\"%s  -  share this page's link to invite friends" % [
			Net.room, "  (you are the host, keep this tab visible)" if Net.is_host else ""]


func _on_closed():
	notice.text = Net.status
	notice.visible = true
