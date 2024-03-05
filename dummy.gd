extends StaticBody2D
var temp = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_hitbox_body_entered(body):
	if !(body is Arrow):
		return
	else:
		body.hitEntity()
		Autoloader.damageNumbers(body.damage, $DamageNumberOrigin.global_position)

func clean():
	if temp:
		queue_free()
	pass
