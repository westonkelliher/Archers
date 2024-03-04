extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var healthbar_scene = preload("res://wolf_healthbar.tscn")
var growl1 = preload("res://audio/sfx/wolf/growl1.ogg")
var growl2 = preload("res://audio/sfx/wolf/growl2.ogg")
var growl3 = preload("res://audio/sfx/wolf/growl3.ogg")
var hurt2 = preload("res://audio/sfx/wolf/hurt2.ogg")
var hurt3 = preload("res://audio/sfx/wolf/hurt3.ogg")
var sfxdeath = preload("res://audio/sfx/wolf/death.ogg")


@export var agro = false
var players = null
var hitsTaken = 0
var delta
var inCooldown = false
var hitpoints = 65
var healthbar

# Called when the node enters the scene tree for the first time.
func _ready():
	players = Autoloader.mainScene.players
	healthbar = healthbar_scene.instantiate()
	healthbar.global_position = global_position
	healthbar.wolf = self
	Autoloader.mainScene.add_child(healthbar)
	sfxManager(growl2)


var targetPlayer = null
var minDistance = INF
func _physics_process(delta):
	if agro:
		for player in players:
			var distance = global_position.distance_to(players[player].global_position)
			if distance < minDistance:
				minDistance = distance
				targetPlayer = players[player]
	if targetPlayer != null and !inCooldown:
		#agro = false
		look_at(targetPlayer.global_position)
		var direction = (targetPlayer.global_position - global_position).normalized()
		global_position += direction * SPEED * delta
		if targetPlayer.isDead:
			targetPlayer = null
			agro = true
			minDistance = INF
	move_and_slide()




func _on_bite_body_entered(body):
	if body is Player:
		var knockback_direction = (targetPlayer.global_position - global_position).normalized()
		body.set_knockback(knockback_direction*500)
		body.playerDamaged(40)
		body.hitstun(0.3)
		inCooldown = true
		await get_tree().create_timer(1.0).timeout
		inCooldown = false


func clean():
	queue_free()


func _on_hitbox_body_entered(body):
	if !(body is Arrow):
		return
	hitsTaken += 1
	body.hitEntity()
	gotHit(body.damage)
	pass # Replace with function body.
	
func gotHit(damage):
	healthbar.takeDamage(damage)
	

func hurt():
	sfxManager(hurt2)
	$Sprite2D.modulate = Color(1, 0.2, 0.2, 1)
	inCooldown = true
	await get_tree().create_timer(0.05).timeout
	$Sprite2D.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.45).timeout
	inCooldown = false

func death():
	$Sprite2D.modulate = Color(1, 0.2, 0.2, 1)
	inCooldown = true
	sfxManager(sfxdeath)
	await $SoundEffects.finished
	queue_free()

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()


func _on_timer_timeout():
	var randomIndex = randi() % 2
	if randomIndex == 0:
		sfxManager(growl1)
	else:
		sfxManager(growl3)
