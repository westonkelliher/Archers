extends CanvasLayer
# HUD for the local keyboard/mouse player: controls hint + upgrade-phase
# overlay. Driven by the same "state:*" strings GameNite sends to phones.

signal send(msg)

var _panel: PanelContainer
var _label: RichTextLabel
var _choices := {} # "1" -> "arrow", etc.

func _ready():
	layer = 50
	var hint := Label.new()
	hint.text = "WASD: move    hold LMB + drag back: draw bow    release: fire"
	hint.position = Vector2(16, 8)
	hint.add_theme_color_override("font_color", NetTheme.TEXT_DIM)
	add_child(hint)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = NetTheme.PANEL_BG
	style.border_color = NetTheme.PANEL_BORDER
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(660, 780)
	_panel.custom_minimum_size = Vector2(600, 0)
	_panel.visible = false
	add_child(_panel)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.custom_minimum_size = Vector2(560, 0)
	_label.add_theme_color_override("default_color", NetTheme.TEXT_MAIN)
	_panel.add_child(_label)

func receive_state(msg: String):
	var parts := msg.split(":")
	if parts.size() < 2 or parts[0] != "state":
		return
	if parts[1] == "upgrading" and parts.size() >= 6:
		_show_upgrades(parts[3], parts[4].split(","), parts[5].split(","))
	else:
		_panel.visible = false

func _show_upgrades(points: String, current: PackedStringArray, upgrades: PackedStringArray):
	_choices = {"1": "arrow", "2": "bow", "3": "armor"}
	var accent := NetTheme.TEXT_ACCENT.to_html(false)
	var text := "[center]Upgrade points: [color=#%s]%s[/color]\n\n" % [accent, points]
	var kinds := ["Arrow", "Bow", "Armor"]
	for i in range(3):
		var cur := current[i].replace("_", " ") if i < current.size() else "?"
		var upg := upgrades[i].replace("_", " ") if i < upgrades.size() else "?"
		text += "[color=#%s]%d[/color] — %s:  %s  ➜  %s\n" % [accent, i + 1, kinds[i], cur, upg]
	text += "[/center]"
	_label.text = text
	_panel.visible = true

func _input(event):
	if not _panel.visible or not (event is InputEventKey) or not event.pressed:
		return
	var key := OS.get_keycode_string(event.keycode)
	if key in _choices:
		send.emit("upgrade:" + _choices[key])
