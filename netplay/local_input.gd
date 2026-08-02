extends Node
# Keyboard + mouse -> GameNite controlpad protocol strings.
# Movement: WASD / arrow keys -> "move:x,y" (sent on change).
# Bow: hold LMB and drag AWAY from the shot direction (slingshot pull-back);
# release fires opposite the drag. While past the deadzone -> "bow:x,y",
# on mouse-up -> short vector, which the player script treats as release/fire.

signal message(msg)

const DEADZONE := 25.0 # px of drag before the bow starts drawing
const MOVE_MAG := 16.0 # protocol max joystick magnitude
const AIM_MAG := 16.0  # anything > 8 counts as pulling

var _last_move := Vector2.ZERO
var _pressed := false
var _press_pos := Vector2.ZERO
var _pulling := false
var _last_aim := Vector2.ZERO

func _physics_process(_delta):
	var mv := Vector2(
		_axis(KEY_D, KEY_RIGHT) - _axis(KEY_A, KEY_LEFT),
		_axis(KEY_S, KEY_DOWN) - _axis(KEY_W, KEY_UP)
	)
	if mv != _last_move:
		_last_move = mv
		var v := mv.normalized() * MOVE_MAG if mv != Vector2.ZERO else Vector2.ZERO
		message.emit("move:%f,%f" % [v.x, v.y])

func _axis(a: int, b: int) -> float:
	return 1.0 if (Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b)) else 0.0

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_press_pos = event.position
		else:
			_pressed = false
			if _pulling:
				_pulling = false
				message.emit("bow:0.1,0") # < 1 length -> release + fire
	elif event is InputEventMouseMotion and _pressed:
		var drag: Vector2 = event.position - _press_pos
		if drag.length() > DEADZONE:
			_pulling = true
			_last_aim = drag.normalized() * AIM_MAG
			message.emit("bow:%f,%f" % [_last_aim.x, _last_aim.y])

func release_all():
	if _last_move != Vector2.ZERO:
		_last_move = Vector2.ZERO
		message.emit("move:0,0")
	if _pulling:
		_pulling = false
		message.emit("bow:0.1,0")
