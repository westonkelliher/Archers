extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var healthbar_scene = preload("res://wolf_healthbar.tscn")

@export var agro = false
var players = null
var hitsTaken = 0
var delta
var inCooldown = false
var hitpoints = 65

# Called when the node enters the scene tree for the first time.
func _ready():
	players = Autoloader.mainScene.players
	var healthbar = healthbar_scene.instantiate()
	healthbar.global_position = global_position
	healthbar.wolf = self
	Autoloader.mainScene.add_child(healthbar)


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
		body.knockback = knockback_direction*50
		body.playerDamaged(40)
		body.hitstun(1.0)
		inCooldown = true
		await get_tree().create_timer(2.0).timeout
		inCooldown = false
		pass # Replace with function body.


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
	hitpoints -= damage
	$Sprite2D.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.05).timeout
	$Sprite2D.modulate = Color(1, 1, 1, 1)
	if hitpoints <= 0:
		queue_free()
