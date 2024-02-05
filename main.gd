extends Node
#@export var arrow_scene = PackedScene
var arrow_scene = preload("res://arrow.tscn")
var player_scene = preload("res://player.tscn")

var players = {}

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
	if client in players:
		players[client].handle_controlpad_input(message)
	else:
		var new_player = player_scene.instantiate()
		new_player.global_position = Vector2(400, 400)
		new_player.connect("bow_shot", _on_player_bow_shot)
		add_child(new_player)
		print('abc')
		players[client] = new_player
		players[client].handle_controlpad_input(message)


func _on_player_bow_charge():
	power = 0
	power += power_increase_rate * delta
	if power > max_power:
		power = max_power
	print("Bow Charged")
	pass # Replace with function body.


func _on_player_bow_shot(player, chargeLevel):
	print("Bow Shot")
	var velocity = Vector2(300+300*chargeLevel, 0)
	var bow = player.get_node('Bow')
	velocity = velocity.rotated(bow.rotation)
	velocity += player.velocity
	var arrow = arrow_scene.instantiate()
	arrow.global_position = bow.global_position
	arrow.linear_velocity = velocity
	arrow.rotation = bow.rotation
	arrow.z_velo = 4+4*chargeLevel
	add_child(arrow)
	pass # Replace with function body.
