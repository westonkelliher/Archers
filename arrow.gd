extends RigidBody2D
class_name Arrow
var z = 2
var z_velo = 1
var arrowScale = 1
var originPlayer = null
var playerHit = false
var specialProperty = null #Can be used for special effects like poison later
var damage = 20
var drag = 0

signal hit()


func set_graphic(graphic_name):
	$Sprite2D.texture = load("res://images/equipment/" + graphic_name + ".png")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	z += z_velo*delta
	z_velo -= 40*delta
	arrowScale = 0.9+0.05*z
	self.scale = Vector2(arrowScale, arrowScale)
	
	var speed = self.linear_velocity.length()
	var speed_reduction = self.drag * (.00001 * speed**2 + .005 * speed)
	var damp = 1 - speed_reduction/speed
	self.linear_velocity *= damp
	
	if z < 0:
		z_velo = 0
		self.linear_velocity = Vector2(0, 0)
		self.angular_velocity = 0
		$Sprite2D.frame = 1
		$CollisionShape2D.disabled = true
		await get_tree().create_timer(2.0).timeout
		queue_free()
	if z > 6:
		$Sprite2D.modulate = Color(0.8, 0.8, 1, 0.7)
	if z < 6:
		$Sprite2D.modulate = Color(1, 1, 1, 1)



func hitPlayer(player):
	playerHit = true
	$CollisionShape2D.set_deferred("disabled", true)
	z = 0
	z_velo = 0
	self.linear_velocity = Vector2(0, 0)
	self.angular_velocity = 0
	$Sprite2D.frame = 1
	queue_free()


func hitButton(): 
	$CollisionShape2D.set_deferred("disabled", true)
	z = 0
	z_velo = 0
	self.linear_velocity = Vector2(0, 0)
	self.angular_velocity = 0
	$Sprite2D.frame = 1


func hitEntity():
	$CollisionShape2D.set_deferred("disabled", true)
	z = 0
	z_velo = 0
	self.linear_velocity = Vector2(0, 0)
	self.angular_velocity = 0
	$Sprite2D.frame = 1


func clean():
	queue_free()
