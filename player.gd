extends CharacterBody2D

var maxHealth = 100
var currentHealth = maxHealth
var playerID = null
var playerColor = null
var isDead = false

var isCharged = false
var chargeLevel = 0
var maxCharge = 4
var chargeMultiplier = 2

var arrowDamage = 20

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var arrow_scene = preload("res://arrow.tscn")
var death_explosion = preload("res://death_explosion.tscn")
var bow_angle = null

signal bow_shot(player, chargeLevel)
signal bow_charge()
signal hit()

var lastPos

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$Body.modulate = playerColor
	pass # Replace with function body.

func _process(delta):
	if isCharged and chargeLevel < maxCharge:
		chargeLevel += delta*chargeMultiplier
		$Chargebar.value = chargeLevel
	#Arrow stick test
	#posDif = self.global_position - lastPos
	#for child in self.get_children():
		#child.global_position = self.global_position


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
		
		#Test
		
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
	
	elif parts[0] == "upgrade":
		upgradeHandler(parts[1])

func upgradeHandler(upgrade):
	if upgrade == "bow":
		print("Bow upgraded")
		chargeMultiplier += chargeMultiplier*.5
	elif upgrade == "arrow":
		print("Arrows Upgraded")
		arrowDamage += arrowDamage*.5
	elif upgrade == "ability":
		print("Ability Upgraded")

func notTaught():
	if isCharged:
		$Bow.release()
		emit_signal("bow_shot", self, chargeLevel)
		isCharged = false
		chargeLevel = 0
		$Chargebar.value = 0




func _on_area_2d_body_entered(body):
	#print("Player got hit")
	if !(body is Arrow):
		return
	if body.originPlayer != self.playerID:
		#var damage = body.linear_velocity.length()
		playerDamaged(body.damage)
		print("OUCH!")
		
		#tested to see if I could make arrows stick out of people, todo ig
		body.hitPlayer(self)

func playerDamaged(damage):
	$HurtSound.play()
	$Healthbar.value -= damage
	$Healthbar/Timer.start()
	if $Healthbar.value <= 0:
		playerDeath()
	pass
	

func playerDeath():
	isDead = true
	deathExplosion()
	var pos = self.global_position
	self.global_position = Vector2(-100, -100)
	await get_tree().create_timer(5.0).timeout
	$Healthbar.value = 100
	$Healthbar/Damagebar.value = 100
	self.global_position = pos
	pass


func deathExplosion():
	var explosion = death_explosion.instantiate()
	explosion.global_position = self.global_position
	explosion.emitting = true
	get_tree().get_root().add_child(explosion)
	pass

func _on_timer_timeout():
	$Healthbar/Damagebar.value = $Healthbar.value
	pass # Replace with function body.
