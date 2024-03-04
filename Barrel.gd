extends StaticBody2D
var hitsTaken = 0
@export var hitLimit = 0
@export var chaosDebug : bool = false
var barrel_explosion = preload("res://barrel_explosion.tscn")

func _ready():
	#var offset = 20
	#$BarrelSprite.position.y = position.y - offset
	#
	#modulate = Color(0.5,0.5,0.8,0)
	#var tween = get_tree().create_tween() 
	#tween.set_parallel(true)
	#tween.tween_property(
		#$BarrelSprite, "position.y", self.position.y, 3
	#).set_ease(Tween.EASE_OUT)
	#tween.tween_property(
		#self, "modulate", Color(1,1,1,1), 3
	#).set_ease(Tween.EASE_IN)
	if chaosDebug:
		hitLimit = 0
		hitsTaken += 1
		gotHit()
	pass


func _on_area_2d_body_entered(body):
	if !(body is Arrow):
		return
	hitsTaken += 1
	body.hitEntity()
	gotHit()
	pass # Replace with function body.
	
func gotHit():
	$BarrelSprite.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.05).timeout
	$BarrelSprite.modulate = Color(1, 1, 1, 1)
	if hitsTaken > hitLimit:
		randomSpawn()
		explode()
		global_position = Vector2(-500,-500)
		Autoloader.mainScene.numBarrels -= 1
		$BreakNoise.play()
		await $BreakNoise.finished
		queue_free()
	else:
		pass


var items = [
	{'name': 'nothing', 'weight': 35, 'scene': null},
	{'name': 'potion', 'weight': 20, 'scene': "res://potion.tscn"},
	{'name': 'wolf', 'weight': 35, 'scene': "res://wolf.tscn"},  # Common item
]


func calculate_total_weight(items):
	var total_weight = 0
	for item in items:
		total_weight += item.weight
	return total_weight

func randomSpawn():
	var total_weight = calculate_total_weight(items)
	var rand = randi() % total_weight + 1  # Generate a random number within the total weight
	var cumulative_weight = 0
	for item in items:
		cumulative_weight += item.weight
		if rand <= cumulative_weight:
			spawn_item(item.scene)
			break

func spawn_item(item_scene):
	if not item_scene:
		return
	var prize_scene = load(item_scene)
	var prize = prize_scene.instantiate()
	prize.global_position = global_position
	Autoloader.mainScene.add_child(prize)
	# Here, you would add your logic to instantiate and position the spawned item in the game world.

func clean():
	queue_free()

func explode():
	var explosion = barrel_explosion.instantiate()
	explosion.global_position = self.global_position
	explosion.emitting = true
	Autoloader.mainScene.add_child(explosion)
