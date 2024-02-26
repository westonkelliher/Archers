extends StaticBody2D
var hitsTaken = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	if !(body is Arrow):
		return
	hitsTaken += 1
	body.hitEntity()
	gotHit()
	pass # Replace with function body.
	
func gotHit():
	$Sprite2D.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.05).timeout
	$Sprite2D.modulate = Color(1, 1, 1, 1)
	if hitsTaken > 0:
		randomSpawn()
		global_position = Vector2(-500,-500)
		Autoloader.mainScene.numBarrels -= 1
		$BreakNoise.play()
		await $BreakNoise.finished
		queue_free()
	else:
		pass


var items = [
	#{'name': 'nothing', 'weight': 50, 'scene': null},
	#{'name': 'potion', 'weight': 30, 'scene': "res://potion.tscn"},
	{'name': 'wolf', 'weight': 10, 'scene': "res://wolf.tscn"},  # Common item
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
			spawn_item(item.scene)  # Replace this with your actual spawn function
			break

func spawn_item(item_scene):
	if item_scene == null:
		return
	var prize_scene = load(item_scene)
	var prize = prize_scene.instantiate()
	prize.global_position = global_position
	Autoloader.mainScene.add_child(prize)
	# Here, you would add your logic to instantiate and position the spawned item in the game world.

func clean():
	queue_free()

