extends Node
#@export var arrow_scene = PackedScene
var arrow_scene = preload("res://arrow.tscn")
var player_scene = preload("res://player.tscn")
var barrel_scene = preload("res://barrel.tscn")
var text_box_scene = preload("res://text_box.tscn")

var players = {}
var readiedPlayers = []
var barrels = []

var power = 0
var max_power = 1000
var power_increase_rate = 10
var delta = 0

var multiplayerStarted = false
var pvpOn =false
var roundNumber = 1

var menuElemPos = null
var vpSize

#Music
var mainTheme = preload("res://audio/Scape Main.ogg")
var battleTheme = preload("res://audio/Mage Arena.ogg")
var battleStart = preload("res://audio/battleHorn.mp3")
var fanfare = preload("res://audio/fanfare.mp3")
var wardrums = preload("res://audio/warDrums.wav")
var jaunt = preload("res://audio/dumbassFlute.mp3")

#OnReady
@onready var textBoxLabel = $CenterContainer/TextBox/MarginContainer/Label
@onready var textBox = $CenterContainer/TextBox
@onready var richTextLabel = $CenterContainer/RichTextBox/MarginContainer/RichLabel
@onready var richTextBox = $CenterContainer/RichTextBox


# Called when the node enters the scene tree for the first time.
func _ready():
	vpSize = get_viewport().size
	Autoloader.mainScene = self
	musicManager(mainTheme)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.delta = delta
	if Input.is_action_pressed("multiplayer") and not multiplayerStarted:
		multiplayerSetup()
	#if not $MusicPlayer.is_playing():
		#$MusicPlayer.play()
	pass


func _on_game_nite_controlpads_message_received(client, message):
	if client in players:
		players[client].handle_controlpad_input(message)
	elif not multiplayerStarted:
		var new_player = player_scene.instantiate()
		new_player.global_position = Vector2(400, 400)
		new_player.connect("bow_shot", _on_player_bow_shot)
		new_player.playerID = client
		var player_color = Color(randf()*0.8 + 0.1, randf()*0.8 + 0.1, randf()*0.8 + 0.1, 1)
		new_player.playerColor = player_color
		new_player.playerName = "Player " + str(len(players.values()))
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


func _on_player_bow_shot(player, power):
	#print("Bow Shot")
	var velocity = Vector2(300+24*power, 0)
	var bow = player.get_node('Bow')
	velocity = velocity.rotated(bow.rotation)
	velocity += player.velocity
	var arrow = arrow_scene.instantiate()
	arrow.global_position = bow.global_position + Vector2(29,0).rotated(bow.rotation)
	arrow.linear_velocity = velocity
	arrow.rotation = bow.rotation
	arrow.z_velo = 4+0.1*power
	arrow.originPlayer = player.playerID
	arrow.damage = player.arrowDamage
	add_child(arrow)
	pass # Replace with function body.

func multiplayerSetup():
	print(players)
	multiplayerStarted = true
	pvpOn = true
	menuElemPos = $MenuElements.position
	$MenuElements.position = Vector2(-5000,-5000)
	for player in players:
		players[player].resetUpgrades()
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
	$MusicPlayer.stop()
	clearJunk()
	universalControl(false)
	pvpOn = true
	placeEvenly()
	sfxManager(wardrums)
	textBoxLabel.text = "Round "+str(roundNumber)
	textBox.visible = true
	await get_tree().create_timer(1.5).timeout
	textBoxLabel.text = "Ready?"
	#await get_tree().create_timer(2.5).timeout
	await $SoundEffects.finished
	textBoxLabel.text = "GO!"
	sfxManager(battleStart)
	await get_tree().create_timer(1.0).timeout
	musicManager(battleTheme)
	textBox.visible = false
	universalControl(true)
	$BarrelTimer.start()
	numBarrels = 0
	pass

func roundOver(winner):
	pvpOn = false
	clearJunk()
	$BarrelTimer.stop()
	$MusicPlayer.stop()
	sfxManager(fanfare)
	var tempC = winner.playerColor
	var hex_color = tempC.to_html(false)
	if winner.gameScore == 3:
		winner.winner()
		richTextLabel.text = "[center][color=#" + hex_color + "]Player[/color] Wins the Game!"
		#$InformationLabel.text = "[color=#" + hex_color + "][center]This Color Wins the Game!"
		#$InformationLabel.visible = true
		richTextBox.visible = true
		await get_tree().create_timer(3.0).timeout
		#$InformationLabel.visible = false
		richTextBox.visible = false
		gameOver()
	else:
		richTextLabel.text = "[center][color=#" + hex_color + "]Player[/color] has won the Round!"
		richTextBox.visible = true
		await get_tree().create_timer(2.0).timeout
		#$InformationLabel.text = "[color=#" + hex_color + "]This Color Wins the Round!"
		richTextLabel.text = "[center]Scores[/center]"
		for player in players:
			if players[player] == winner:
				$Controlpads.send_message(winner.playerID, "upgrade:2")
			else:
				$Controlpads.send_message(players[player].playerID, "upgrade:1")
			tempC = players[player].playerColor
			hex_color = tempC.to_html(false)
			richTextLabel.text += "\n[color=#" + hex_color + "]Player				"+str(players[player].gameScore)
		$InformationLabel.visible = true
		#await get_tree().create_timer(10.0).timeout
		roundNumber += 1
		await $SoundEffects.finished
		musicManager(jaunt)
		await readyUpGamepad()
		richTextBox.visible = false
		msgToAll("clear:")
		roundInit()
	pass

func readyUpGamepad():
	var allReady = false
	while not allReady:
		allReady = true
		for player in players:
			if not players[player].readyUp:
				allReady = false
				break
		if not $MusicPlayer.is_playing():
			allReady = true
		else:
			await get_tree().create_timer(0.5).timeout
	if allReady:
		return allReady


func gameOver():
	pvpOn = false
	multiplayerStarted = false
	roundNumber = 1
	universalControl(true)
	musicManager(mainTheme)
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

func clearJunk():
	for child in get_children():
		if child.has_method("clean"):
			child.clean()


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

var numBarrels = 0
func _on_barrel_timer_timeout():
	if numBarrels < 3:
		barrelLogic()


func barrelLogic():
	var avgPos = Vector2(0,0)
	var numAlivePlayers = 0
	for player in players:
		if !(players[player].isDead):
			avgPos += players[player].global_position
			numAlivePlayers += 1
	avgPos /= numAlivePlayers
	var barrelPos = Vector2()
	barrelPos.x = avgPos.x + vpSize.x*randf_range(.1,-.1)
	barrelPos.y = avgPos.y + vpSize.y*randf_range(.1,-.1)
	var barrel = barrel_scene.instantiate()
	barrel.global_position = barrelPos
	add_child(barrel)
	numBarrels += 1
	pass

func musicManager(song):
	$MusicPlayer.stream = song
	$MusicPlayer.play()

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()
