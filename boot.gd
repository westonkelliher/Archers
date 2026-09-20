extends Control
# Find out from the relay whether we're the host or a client, then load the game

var label = Label.new()

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg = ColorRect.new()
	bg.color = UITheme.BOOT_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	UITheme.style_label(label, 48)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	Net.welcomed.connect(func(): get_tree().change_scene_to_file.call_deferred("res://main.tscn"))
	Net.start()

func _process(_delta):
	label.text = Net.status
