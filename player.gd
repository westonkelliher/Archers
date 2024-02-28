extends CharacterBody2D
class_name Player

var maxHealth = 100
var currentHealth = maxHealth
var playerID = null
var playerColor = null
var playerName = null
var isDead = false
var gameScore = 0
var controllable = true
var readyUp = false

var speedMultiplier = 15

var arrowDamage = 20

var knockback = Vector2.ZERO

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var arrow_scene = preload("res://arrow.tscn")
var death_explosion = preload("res://death_explosion.tscn")
var bow_angle = null

var sfx_shootBow = preload("res://audio/shootBow.mp3")

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
	if $Bow.charge_amount > 0:
		$Chargebar.visible = true
		$Chargebar.value = $Bow.charge_amount*100
	else:
		$Chargebar.visible = false
		



func _physics_process(delta):
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = knockback*.5
	move_and_slide()

func handle_controlpad_input(message: String):
	var parts = message.split(":")
	if parts[0] == "move" and controllable:
		var xy = parts[1].split(",")
		var in_vel = Vector2(float(xy[0]), float(xy[1]))
		var threshhold = 16.0;
		if in_vel.length() > threshhold:
			in_vel *= threshhold/in_vel.length()
		#var mult = 15.0;
		self.velocity = in_vel * speedMultiplier;
		if in_vel.length() > 0 and !$Bow.is_pulling:
			var in_angle = in_vel.angle()
			$Eyes.set_direction(in_angle)
		
		#Test
		
	elif parts[0] == "bow": #and controllable:
		# Rotation
		var xy = parts[1].split(",")
		var in_aim = Vector2(float(xy[0]), float(xy[1]))
		if in_aim.length() < 1:
			notTaught()
			return
		bow_angle = in_aim.angle() - PI
		$Bow.rotation = bow_angle
		$Eyes.set_direction(bow_angle)
		# Pullback
		var threshhold = 8.0;
		if in_aim.length() > threshhold:
			if !$Bow.is_pulling:
				$Bow.pull_back()
			#emit_signal("bow_charge")
		else:
			notTaught()
	
	elif parts[0] == "upgrade":
		upgradeHandler(parts[1])
	
	elif parts[0] == "ready":
		readyUp = true

func upgradeHandler(upgrade):
	if upgrade == "bow":
		$Bow.draw_time *= 0.5
		$Bow.charge_time *= 0.75
	elif upgrade == "arrow":
		arrowDamage += arrowDamage*.1 + 5
	elif upgrade == "ability":
		speedMultiplier += speedMultiplier*.15

func notTaught():
	if $Bow.charge_amount > 0 and controllable:
		emit_signal("bow_shot", self, $Bow.get_power())
	$Bow.release()




func _on_area_2d_body_entered(body):
	if !(body is Arrow):
		return
	if body.originPlayer != self.playerID:
		playerDamaged(body.damage)
		body.hitPlayer(self)

func playerDamaged(damage):
	$HurtSound.play()
	if Autoloader.mainScene.pvpOn:
		$Healthbar.visible = true
		$Healthbar.value -= damage
		$Healthbar/Timer.start()
		if $Healthbar.value <= 0:
			playerDeath()

func playerGainHealth(health):
	$Healthbar.value += health
	$Healthbar/Damagebar.value += health
	if $Healthbar.value > 100:
		$Healthbar.value = 100
		$Healthbar/Damagebar.value = 100


func hitstun(stun):
	controllable = false
	await get_tree().create_timer(stun).timeout
	controllable = true


func playerDeath():
	isDead = true
	controllable = false
	readyUp = false
	deathExplosion()
	self.global_position = Vector2(-100, -100)
	Autoloader.mainScene.winCheck()
	pass

func refresh():
	$Healthbar.value = 100
	$Healthbar/Damagebar.value = 100
	$RoyalCrown.visible = false
	isDead = false


func deathExplosion():
	var explosion = death_explosion.instantiate()
	explosion.global_position = self.global_position
	explosion.emitting = true
	explosion.modulate = playerColor
	#get_tree().get_root().add_child(explosion)
	Autoloader.mainScene.add_child(explosion)
	pass
	
func restoreAll():
	$Healthbar.value = 100
	$Healthbar/Damagebar.value = 100
	isDead = false
	readyUp = false
	gameScore = 0
	arrowDamage = 20
	speedMultiplier = 15

func winner():
	$RoyalCrown.visible = true

func _on_timer_timeout():
	$Healthbar/Damagebar.value = $Healthbar.value

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()

