extends Area2D
var target
var playerRef

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target:  # If the target position is set (not null)
		position = position.lerp(target, 7 * delta)  # Adjust the 0.1 factor to control the speed of lerp
		target = playerRef.global_position
		var distance_to_target = position.distance_to(target)
		scale = scale.lerp(Vector2(.2,.2), 7 * delta)
		if distance_to_target < 10:  # Consider as reached if within 1 unit to the target
			clean()

func clean():
	queue_free()


func _on_body_entered(body):
	if !(body is Player):
		return
	body.playerGainHealth(30)
	get_parent().numBarrels -= 1
	target = body.global_position
	playerRef = body
	$CollisionShape2D.disabled = true
	#queue_free()
	pass # Replace with function body.