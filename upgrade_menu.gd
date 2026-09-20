extends PanelContainer
# Between rounds: spend upgrade points. Replaces the phone controller's
# upgrade screen. Click a choice or press 1 / 2 / 3.

const KINDS = ['bow', 'arrow', 'armor']
const HINTS = {
	'Shortbow': "quick draw, less power", 'Longbow': "slow draw, long range", 'Bow': "balanced",
	'Heavy_Arrow': "big damage, slows fast", 'Ice_Arrow': "chills", 'Arrow': "more damage",
	'Heavy_Armor': "lots of health, slower", 'Light_Armor': "some health, faster", 'Armor': "more health",
}

var title = Label.new()
var buttons = {}


func _ready():
	visible = false
	add_theme_stylebox_override("panel", UITheme.panel_style())
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -30

	var rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	add_child(rows)
	UITheme.style_label(title, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(title)

	var choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	rows.add_child(choices)
	for kind in KINDS:
		var button = Button.new()
		button.custom_minimum_size = Vector2(330, 150)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.focus_mode = Control.FOCUS_NONE
		UITheme.style_label(button, 24)
		button.pressed.connect(pick.bind(kind))
		choices.add_child(button)
		buttons[kind] = button

	var skip = Button.new()
	skip.text = "Skip (0)"
	skip.focus_mode = Control.FOCUS_NONE
	skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.style_label(skip, 20, UITheme.TEXT_MUTED)
	skip.pressed.connect(pick.bind("skip"))
	rows.add_child(skip)


func is_open():
	return visible


# st comes from Player.get_state_dict()
func apply_state(st):
	visible = st['state'] == "upgrading" and st['points'] > 0
	if not visible:
		return
	title.text = "Choose an upgrade  (%d left)" % st['points']
	var number = 1
	for kind in KINDS:
		var button = buttons[kind]
		var upgrade = st['upgrades'][kind]
		button.disabled = upgrade == "nothing"
		if button.disabled:
			button.text = "%s\nmaxed out" % pretty(st['current'][kind])
			button.icon = null
		else:
			button.text = "[%d]  %s\n%s" % [number, pretty(upgrade), hint(upgrade)]
			button.icon = load("res://images/equipment/" + upgrade + ".png")
		number += 1
	reset_size()


func pick(kind):
	if visible and (kind == "skip" or not buttons[kind].disabled):
		visible = false # until the host answers with my new state
		Autoloader.mainScene.request_upgrade(kind)


func _unhandled_key_input(event):
	if not visible or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: pick('bow')
		KEY_2: pick('arrow')
		KEY_3: pick('armor')
		KEY_0: pick('skip')


func pretty(equipment_name):
	return equipment_name.replace("_", " ")

func hint(equipment_name):
	for prefix in HINTS:
		if equipment_name.begins_with(prefix):
			return HINTS[prefix]
	return ""
