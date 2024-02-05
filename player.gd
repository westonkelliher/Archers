extends CharacterBody2D

var isCharged = false
var chargeLevel = 0
@export var maxCharge = 4

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var arrow_scene = preload("res://arrow.tscn")
var bow_angle = null

signal bow_shot(player, chargeLevel)
signal bow_charge()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(delta):
	if isCharged and chargeLevel < maxCharge:
		chargeLevel += delta


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
			notTaught()
			return
		bow_angle = in_aim.angle() - PI
		$Bow.rotation = bow_angle
		# Pullback
		var threshhold = 8.0;
		if in_aim.length() > threshhold:
			if !isCharged:
				isCharged = true
				$Bow.pull_back()
			#emit_signal("bow_charge")
		else:
			notTaught()

func notTaught():
	if isCharged:
		$Bow.release()
		print("emit")
		emit_signal("bow_shot", self, chargeLevel)
		isCharged = false
		chargeLevel = 0
