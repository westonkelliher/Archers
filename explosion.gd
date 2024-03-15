extends GPUParticles2D
var victims = []

# Called when the node enters the scene tree for the first time.
func _ready():
	emitting = true
	print($Area2D.get_overlapping_bodies())
	for body in $Area2D.get_overlapping_bodies():
		print(body)
		victims.append(body)
	knockback()
	pass # Replace with function body.

func knockback():
	for body in victims:
		print(body)
		if body is Player:
			var knockback_direction = (body.global_position - global_position).normalized()
			body.set_knockback(knockback_direction*800)
			body.playerDamaged(60)
			body.hitstun(0.5)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
