extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	move_and_slide()


func handle_controlpad_input(message: String):
	var parts = message.split(":")
	if parts[0] == "move":
		var xy = parts[1].split(",")
		var in_vel = Vector2(float(xy[0]), float(xy[1]))
		var threshhold = 16.0;
		if in_vel.length() > threshhold:
			in_vel *= threshhold/in_vel.length()
		var mult = 15.0;
		self.velocity = in_vel * mult;
	elif parts[0] == "bow":
		# Rotation
		var xy = parts[1].split(",")
		var in_aim = Vector2(float(xy[0]), float(xy[1]))
		if in_aim.length() < 1:
			$Bow.release()
			return
		$Bow.rotation = in_aim.angle() - PI
		# Pullback
		var threshhold = 8.0;
		if in_aim.length() > threshhold:
			$Bow.pull_back()
		else:
			$Bow.release()
