extends CharacterBody2D
class_name Player

var maxHealth = 100
var currentHealth = maxHealth
var playerID = null
var playerColor = null
var playerName = "Player"
var isDead = false
var gameScore = 0
var controllable = true
var readyUp = false
var savedPosition = null
var invulnerable = false
var unspawned : bool = false

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
var velocity_move : Vector2 = Vector2.ZERO
var velocity_knock : Vector2 = Vector2.ZERO

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
	velocity = velocity_move + velocity_knock
	velocity_knock *= .97
	if velocity_knock.length() < 5:
		velocity_knock = Vector2.ZERO
	move_and_slide()

func set_knockback(kb):
	velocity_knock = kb

func handle_controlpad_input(message: String):
	var parts = message.split(":")
	if parts[0] == "move" and controllable:
		var xy = parts[1].split(",")
		var in_vel = Vector2(float(xy[0]), float(xy[1]))
		var threshhold = 16.0;
		if in_vel.length() > threshhold:
			in_vel *= threshhold/in_vel.length()
		#var mult = 15.0;
		self.velocity_move = in_vel * speedMultiplier;
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
				$Bow.pull_back(isDead)
			#emit_signal("bow_charge")
		else:
			notTaught()
	
	elif parts[0] == "upgrade":
		upgradeHandler(parts[1])
	
	elif parts[0] == "ready":
		readyUp = true
		controllable = true
		if isDead:
			self.global_position = savedPosition
	
	elif parts[0] == "name":
		playerName = parts[1]

func upgradeHandler(upgrade):
	if upgrade == "bow":
		$Bow.draw_time *= 0.5
		$Bow.charge_time *= 0.75
	elif upgrade == "arrow":
		arrowDamage += arrowDamage*.2 + 10
	elif upgrade == "ability":
		speedMultiplier += speedMultiplier*.15

func notTaught():
	if $Bow.charge_amount > 0 and controllable:
		emit_signal("bow_shot", self, $Bow.get_power())
	$Bow.release(isDead)




func _on_area_2d_body_entered(body):
	if !(body is Arrow):
		return
	if body.originPlayer != self.playerID and not invulnerable:
		playerDamaged(body.damage)
		body.hitPlayer(self)

func playerDamaged(damage):
	$HurtSound.play()
	$Healthbar/Damagebar.visible = true
	$Healthbar.visible = true
	$Healthbar.value -= damage
	Autoloader.damageNumbers(damage, $DamageNumberOrigin.global_position)
	$Healthbar/Timer.start()
	if $Healthbar.value <= 0:
		playerDeath()

func playerGainHealth(health, potion = false):
	$Healthbar.value += health
	$Healthbar/Damagebar.value += health
	if $Healthbar.value > 100:
		$Healthbar.value = 100
		$Healthbar/Damagebar.value = 100
	if potion:
		$DrinkSound.play()


func hitstun(stun):
	controllable = false
	await get_tree().create_timer(stun).timeout
	controllable = true


func playerDeath():
	deathExplosion()
	savedPosition = self.global_position
	self.global_position = Vector2(-5000, -5000)
	if Autoloader.mainScene.multiplayerStarted:
		isDead = true
		controllable = false
		readyUp = false
		Autoloader.mainScene.winCheck()
	else:
		respawn()


func respawn():
	invulnerable = true
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 0.5)
	restoreAll()
	global_position = savedPosition
	await get_tree().create_timer(5.0).timeout
	modulate = Color(1, 1, 1, 1)
	invulnerable = false

func refresh():
	$Healthbar.value = 100
	$Healthbar/Damagebar.value = 100
	$RoyalCrown.visible = false
	isDead = false
	readyUp = false
	invulnerable = false
	knockback = Vector2.ZERO
	velocity_knock = Vector2.ZERO
	velocity_move = Vector2.ZERO


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

func resetUpgrades():
	arrowDamage = 20
	speedMultiplier = 15
	$Bow.draw_time = .5
	$Bow.charge_time = 4

func winner():
	$RoyalCrown.visible = true

func _on_timer_timeout():
	$Healthbar/Damagebar.value = $Healthbar.value
	pass

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()

