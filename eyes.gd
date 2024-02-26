extends Node2D


@export var eyes_radius: float = 18.0
@export var eyes_distance: float = 0.6
var eye_direction: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	if Autoloader.mainScene != null:
		$ref.visible = false
		return
	self.position = Vector2(200, 200)
	self.scale = Vector2(3, 3)
	set_direction(PI/7)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Autoloader.mainScene != null:
		return
	eye_direction += 0.04
	set_direction(eye_direction)


func set_single_eye_direction(eye, theta):
	if theta < 0:
		theta += PI*2
	print(theta)
	if theta > PI and theta < PI*2:
		print("a")
		eye.visible = false
		return
	print("b")
	eye.visible = true
	eye.position = Vector2(eyes_radius, 0).rotated(theta)
	eye.position.y *= .3

func set_direction(theta):
	eye_direction = theta
	var thetaL = theta - eyes_distance/2.0
	var thetaR = theta + eyes_distance/2.0
	set_single_eye_direction($L, thetaL)
	set_single_eye_direction($R, thetaR)
