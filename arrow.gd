extends RigidBody2D
var z = 2
var z_velo = 1
var arrowScale = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	z += z_velo*delta
	z_velo -= 40*delta
	
	arrowScale = 0.9+0.05*z
	self.scale = Vector2(arrowScale, arrowScale)
	
	if z < 0:
		queue_free()
	if z > 6:
		$Sprite2D.modulate = Color(0.8, 0.8, 1, 0.7)
	if z < 6:
		$Sprite2D.modulate = Color(1, 1, 1, 1)
	
	
