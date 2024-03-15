extends Area2D
var target
var playerRef
var isDrank
var speed = 300
@export var healAmount : int = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target:  # If the target position is set (not null)
		position = position.move_toward(target, speed * delta)  # Adjust the 0.1 factor to control the speed of lerp
		speed += 300*delta
		target = playerRef.global_position
		var distance_to_target = position.distance_to(target)
		scale = scale.lerp(Vector2(.2,.2), 7 * delta)
		if distance_to_target < 5 and not isDrank:  # Consider as reached if within 1 unit to the target
			drank()

func clean():
	queue_free()


func _on_body_entered(body):
	if !(body is Player):
		return
	target = body.global_position
	playerRef = body
	$CollisionShape2D.set_deferred("disabled", true)


func drank():
	isDrank = true
	playerRef.playerGainHealth(healAmount, true)
	clean()
