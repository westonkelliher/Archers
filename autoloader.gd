extends Node
var mainScene = null
var font = preload("res://fonts/m6x11plus.ttf")

func damageNumbers(value : int, position : Vector2):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	number.label_settings.font_color = Color.DARK_RED
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
