extends Node
var mainScene = null
var buttonRef = null
var font = preload("res://fonts/mainFont.ttf")
var barrelDespawning = false

func damageNumbers(value : int, position : Vector2, type : String = "general"):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	number.label_settings.font_color = Color.DARK_RED
	if type == "health":
		number.label_settings.font_color = Color.LIME_GREEN
		number.text = "+" + number.text
	if type == "fire":
		number.label_settings.font_color = Color.ORANGE
	if type == "poison":
		number.label_settings.font_color = Color.LAWN_GREEN
	number.label_settings.font_size = 32
	number.label_settings.outline_color = Color.BLACK
	number.label_settings.outline_size = 3
	number.label_settings.font = font
	
	call_deferred("add_child", number)
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	number.position -= number.pivot_offset
	
	var tween = get_tree().create_tween() 
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.5
	).set_ease(Tween.EASE_OUT)
	#tween.tween_property(
		#number, "position:y", number.position.y, 0.5
	#).set_ease(Tween. EASE_IN).set_delay(0.25)
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	tween.tween_property(
		number, "modulate", Color(1,1,1,0), 0.3
	).set_ease(Tween.EASE_IN).set_delay(1)
	
	
	await tween.finished
	number.queue_free()
