extends Node
var mainScene = null

func damageNumbers(damageNum : int, position : Vector2):
	var number = Label.new()
	number.global_position = position
	number.text = str(damageNum)
	
	number.label_settings = LabelSettings.new()
	number.label_settings.font_color = Color.DARK_RED
	number.label_settings.font_size = 18
	number.label_settings.outline_color = Color.BLACK
	number.label_settings.outline_size = 1
	
	call_deferred("add_child", number)
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var tween = get_tree().create_tween() 
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.25
	).set_ease (Tween.EASE_OUT)
	tween.tween_property(
		number, "position:y", number.position.y, 0.5
	).set_ease (Tween. EASE_IN).set_delay (0.25)
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween. EASE_IN).set_delay (0.5)
	
	
	print("ex")
	await tween.finished
	number.queue_free()
