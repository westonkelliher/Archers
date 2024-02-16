extends Node
#@export var arrow_scene = PackedScene
var arrow_scene = preload("res://arrow.tscn")
var player_scene = preload("res://player.tscn")

var players = {}
var readiedPlayers = []

var power = 0
var max_power = 1000
var power_increase_rate = 10
var delta = 0

var multiplayerStarted = false
var pvpOn =false
var roundNumber = 1

var menuElemPos = null



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.delta = delta
	if Input.is_action_pressed("multiplayer") and not multiplayerStarted:
		multiplayerSetup()
	pass


func _on_game_nite_controlpads_message_received(client, message):
	if client in players:
		players[client].handle_controlpad_input(message)
	elif not multiplayerStarted:
		var new_player = player_scene.instantiate()
		new_player.global_position = Vector2(400, 400)
		new_player.connect("bow_shot", _on_player_bow_shot)
		new_player.playerID = client
		var player_color = Color(randf(), randf(), randf(), 1)
		new_player.playerColor = player_color
		add_child(new_player)
		players[client] = new_player
		players[client].handle_controlpad_input(message)
		var colorString = "#%x%x%xff" % [player_color.r*255, player_color.g*255, player_color.b*255]
		#print(colorString)
		$Controlpads.send_message(client, colorString)
		


func _on_player_bow_charge():
	power = 0
	power += power_increase_rate * delta
	if power > max_power:
		power = max_power
	#print("Bow Charged")
	pass # Replace with function body.


func _on_player_bow_shot(player, chargeLevel):
	#print("Bow Shot")
	var velocity = Vector2(300+300*chargeLevel, 0)
	var bow = player.get_node('Bow')
	velocity = velocity.rotated(bow.rotation)
	velocity += player.velocity
	var arrow = arrow_scene.instantiate()
	arrow.global_position = bow.global_position
	arrow.linear_velocity = velocity
	arrow.rotation = bow.rotation
	arrow.z_velo = 4+4*chargeLevel
	arrow.originPlayer = player.playerID
	arrow.damage = player.arrowDamage
	add_child(arrow)
	pass # Replace with function body.

func multiplayerSetup():
	multiplayerStarted = true
	pvpOn = true
	#$MenuElements.visible = false
	menuElemPos = $MenuElements.position
	$MenuElements.position = Vector2(-5000,-5000)
	roundInit()
	pass

func placeEvenly():
	var angle_increment = 360 / len(players.values())
	var viewport_size = get_viewport().size
	var level_radius = min(viewport_size.x, viewport_size.y) * 0.4  # Choose a suitable radius based on viewport size
	var center = Vector2(viewport_size / 2)
	
	# Generate a random rotation offset between 0 and 3
	var rotation_offset = randi_range(0, 3) * 90
	
	var i = 0
	for player in players:
		var angle_degrees = (i * angle_increment - 90 + rotation_offset) % 360
		var angle_radians = deg_to_rad(angle_degrees)
		var spawn_offset = Vector2(cos(angle_radians), sin(angle_radians)) * level_radius
		var spawn_position = center + spawn_offset
		players[player].velocity = Vector2(0, 0)
		players[player].global_position = spawn_position
		players[player].refresh()
		#print(players[player].global_position)
		i += 1

#This is almost certainly bad code
func winCheck():
	if pvpOn:
		var aliveCount = 0
		var winningPlayer = null
		for player in players:
			if players[player].isDead == false:
				winningPlayer = players[player]
				aliveCount += 1
		if aliveCount == 1:
			winningPlayer.gameScore += 1
			roundOver(winningPlayer)
			#$Controlpads.send_message(winningPlayer.playerID, "upgrade:2")

func roundInit():
	universalControl(false)
	placeEvenly()
	$InformationLabel.text = "[center]Round "+str(roundNumber)
	$InformationLabel.visible = true
	await get_tree().create_timer(1.0).timeout
	$InformationLabel.text = "[center]Ready?"
	await get_tree().create_timer(2.5).timeout
	$InformationLabel.text = "[center]GO!"
	await get_tree().create_timer(0.5).timeout
	$InformationLabel.visible = false
	universalControl(true)
	pass

func roundOver(winner):
	var tempC = winner.playerColor
	var hex_color = tempC.to_html(false)
	if winner.gameScore == 3:
		winner.winner()
		$InformationLabel.text = "[color=#" + hex_color + "][center]This Color Wins the Game!"
		$InformationLabel.visible = true
		await get_tree().create_timer(3.0).timeout
		$InformationLabel.visible = false
		gameOver()
	else:
		$InformationLabel.text = "[color=#" + hex_color + "]This Color Wins the Round!"
		for player in players:
			if players[player] == winner:
				$Controlpads.send_message(winner.playerID, "upgrade:2")
			else:
				$Controlpads.send_message(players[player].playerID, "upgrade:1")
			tempC = players[player].playerColor
			hex_color = tempC.to_html(false)
			$InformationLabel.text += "\n[color=#" + hex_color + "]This player has "+str(players[player].gameScore)+" wins"
		$InformationLabel.visible = true
		await get_tree().create_timer(10.0).timeout
		roundNumber += 1
		#readyUpGamepad()
		msgToAll("clear:")
		roundInit()
	pass

func readyUpGamepad():
	var allReady = false
	while not allReady:
		print("I'm looping")
		allReady = true  # Assume all players are ready until proven otherwise
		for player in players:
			print(players[player].readyUp)
			if not players[player].readyUp:
				allReady = false  # At least one player is not ready
				break  # Exit the loop to avoid unnecessary checks
		await get_tree().create_timer(1.0).timeout
	print("Somehow broke out of loop")
	print(allReady)


func gameOver():
	pvpOn = false
	multiplayerStarted = false
	roundNumber = 1
	universalControl(true)
	readiedPlayers = []
	$MenuElements.position = Vector2(0,0)
	for player in players:
		players[player].restoreAll()
		#Bad code, should fetch viewport size but I'm LAZY
		players[player].global_position = Vector2(randf_range(100,1000), randf_range(100,1000))
	pass

#Turns controls off or on for all players
func universalControl(state):
	for player in players:
		players[player].controllable = state

func msgToAll(msg):
	for player in players:
		$Controlpads.send_message(players[player].playerID, msg)


@onready var buttonLabel = $MenuElements/MultiplayerButton/MultiplayerButtonLabel
func _on_multiplayer_button_body_entered(body):
	if !(body is Arrow):
		return
	var numPlayers = len(players.values())
	body.hitButton()
	if body.originPlayer not in readiedPlayers:
		readiedPlayers.append(body.originPlayer)
		buttonLabel.text = "[center] Players Ready:"
		buttonLabel.text += "[center]("+str(readiedPlayers.size())+"/"+str(numPlayers)+")"
		await get_tree().create_timer(0.5).timeout
	if readiedPlayers.size() == numPlayers and numPlayers > 1:
		body.queue_free()
		multiplayerSetup()






















#This shit was me tryna big-brain and failing terribly, but it might be worth coming back to in the future
func placeEvenlyFail(): 
	var x = get_viewport().size.x
	var y = get_viewport().size.y
	var left = x*.1
	var right = x*.9
	var center = x/2
	
	
	var numPlayers = len(players.values())
	numPlayers = 3
	
	var divisions = ceil(numPlayers / 2)+1


	var index = 1
	var playerX
	var playerY
	for player in players:
		if index%2 == 0:
			playerX = right
		else:
			playerX = left
		
		players[player].global_position = Vector2(playerX, y/2)
		
		index += 1
	
	#print(players)
	#print(len(players.values()))
	#for player in players
