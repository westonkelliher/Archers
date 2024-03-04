extends ProgressBar
var wolf = null
var loc = null

func _process(delta):
	if wolf:
		position = wolf.global_position
		position.y += 40 + 45 * abs(sin(wolf.rotation))
		pivot_offset = Vector2(size / 2)
		position -= pivot_offset
		#max_value += (Autoloader.mainScene.roundNumber - 1)*25
		#value = max_value
		#$Damagebar.value = value

func takeDamage(damage):
	visible = true
	value -= damage
	$Timer.start()
	if value <= 0:
		wolf.death()
		queue_free()
	else:
		wolf.hurt()

func _on_timer_timeout():
	$Damagebar.value = value
	pass # Replace with function body.

func clean():
	queue_free()
