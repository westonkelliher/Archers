extends Node
#@export var arrow_scene = PackedScene
var arrow_scene = preload("res://arrow.tscn")

var power = 0
var max_power = 1000
var power_increase_rate = 10
var delta = 0



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.delta = delta
	pass


func _on_game_nite_controlpads_message_received(client, message):
	#print(message)
	$Player.handle_controlpad_input(message)


func _on_player_bow_charge():
	power = 0
	power += power_increase_rate * delta
	if power > max_power:
		power = max_power
	print("Bow Charged")
	pass # Replace with function body.


func _on_player_bow_shot(chargeLevel):
	print("Bow Shot")
	var velocity = Vector2(300+300*chargeLevel, 0)
	velocity = velocity.rotated($Player/Bow.rotation)
	velocity += $Player.velocity
	var arrow = arrow_scene.instantiate()
	arrow.global_position = $Player/Bow.global_position
	arrow.linear_velocity = velocity
	arrow.rotation = $Player/Bow.rotation
	arrow.z_velo = 4+4*chargeLevel
	add_child(arrow)
	pass # Replace with function body.
