extends Control
# Landing screen: pick Play Local / Host Online / Join Online.
# On web, ?room=CODE prefills the room so an invite link is one click to join.

var room_edit: LineEdit

func _ready():
	var bg := ColorRect.new()
	bg.color = NetTheme.PANEL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(420, 0)
	box.position = Vector2(750, 340)
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	var title := Label.new()
	title.text = "ARCHERS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", NetTheme.TEXT_ACCENT)
	box.add_child(title)

	var local_btn := _button(box, "Play Local")
	local_btn.pressed.connect(func(): _start("local"))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var room_label := Label.new()
	room_label.text = "Room:"
	room_label.add_theme_color_override("font_color", NetTheme.TEXT_MAIN)
	row.add_child(room_label)
	room_edit = LineEdit.new()
	room_edit.text = _random_room()
	room_edit.custom_minimum_size = Vector2(200, 0)
	room_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(room_edit)

	var host_btn := _button(box, "Host Online")
	host_btn.pressed.connect(func(): _start("host"))
	var join_btn := _button(box, "Join Online")
	join_btn.pressed.connect(func(): _start("client"))

	var params := _url_params()
	if params.has("room"):
		room_edit.text = params["room"]
		join_btn.grab_focus()

func _button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 28)
	parent.add_child(b)
	return b

func _start(mode: String):
	Autoloader.net_mode = mode
	var room := room_edit.text.strip_edges().to_lower()
	Autoloader.net_room = room if room != "" else "arena"
	get_tree().change_scene_to_file("res://main.tscn")

func _random_room() -> String:
	var letters := "abcdefghjkmnpqrstuvwxyz"
	var out := ""
	for i in 4:
		out += letters[randi() % letters.length()]
	return out

func _url_params() -> Dictionary:
	var out := {}
	if not OS.has_feature("web"):
		return out
	var search := str(JavaScriptBridge.eval("location.search"))
	for pair in search.trim_prefix("?").split("&"):
		var kv := pair.split("=")
		if kv.size() == 2 and kv[1] != "":
			out[kv[0]] = kv[1].uri_decode()
	return out
