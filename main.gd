extends Node
#@export var arrow_scene = PackedScene
var arrow_scene = preload("res://arrow.tscn")
var player_scene = preload("res://player.tscn")
var barrel_scene = preload("res://barrel.tscn")
var text_box_scene = preload("res://text_box.tscn")
var dummy_scene = preload("res://dummy.tscn")
var button_scene = preload("res://shootable_button.tscn")

var players = {}
var playersAll = {}
var readiedPlayers = []
var barrels = []

var power = 0
var max_power = 1000
var power_increase_rate = 10
var delta = 0

@export var gamesNeeded4Win = 3
@export var maxBarrelCount = 10
@export var debugEquipment = false

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
var jaunt = preload("res://audio/VictoryJaunt.ogg")

#OnReady
@onready var textBoxLabel = $CenterContainer/TextBox/MarginContainer/Label
@onready var textBox = $CenterContainer/TextBox
@onready var richTextLabel = $CenterContainer/RichTextBox/MarginContainer/VBoxContainer/RichLabel
@onready var richTextBox = $CenterContainer/RichTextBox





# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	vpSize = get_viewport().size
	Autoloader.mainScene = self
	musicManager(mainTheme)
	$BarrelTimer.wait_time = barrelWaitTime
	#createButton("Free for All", settingsButtonHandler)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.delta = delta
	if Input.is_action_pressed("multiplayer") and not multiplayerStarted:
		multiplayerSetup()
	#if not $MusicPlayer.is_playing():
		#$MusicPlayer.play()


func send_state_message(player):
	var msg = player.get_state_string()
	$Controlpads.send_message(player.playerID, msg)


func send_all_states():
	for player in players:
		send_state_message(players[player])


func _on_game_nite_controlpads_message_received(client, message):
	if message == "state-request":
		if client in playersAll:
			send_state_message(playersAll[client])
		else:
			$Controlpads.send_message(client, "state:joining")
		return
	if client in playersAll:
		if multiplayerStarted and client not in players:
			return
		playersAll[client].handle_controlpad_input(message)
		if playersAll[client].unspawned:
			playersAll[client].unspawned = false
			players[client] = playersAll[client]
			players[client].global_position = Vector2(400, 400)
			buttonTextHandler()
	elif not multiplayerStarted:
		new_player(client)
		if debugEquipment:
			setDebugEquipment(client)
		players[client].handle_controlpad_input(client)

func setDebugEquipment(client):
	if client == "0x1-1":
		players[client].set_equipment('Shortbow_V', 'Arrow_I', 'Armor_I')
	if client == "0x1-2":
		players[client].set_equipment('Shortbow_V', 'Heavy_Arrow_I', 'Armor_II')
	if client == "0x1-3":
		players[client].set_equipment('Shortbow_V', 'Heavy_Arrow_II', 'Armor_III')
	if client == "0x1-4":
		players[client].set_equipment('Shortbow_V', 'Heavy_Arrow_IV', 'Armor_IV')
	#this guy has custom equipment, wow
	if client == "0x1-5":
		players[client].setBow('Bow_I', {'chargeTime': 0.5})
		players[client].setArmor('Armor_I', {'healthBonus': 240, 'speedBonus': 0.45})
		players[client].equipment['bow_tier'] = 5


func new_player(client):
	var new_player = player_scene.instantiate()
	new_player.global_position = Vector2(400, 400)
	new_player.connect("bow_shot", _on_player_bow_shot)
	new_player.playerID = client
	var player_color = Color(randf()*0.7 + 0.2, randf()*0.7 + 0.2, randf()*0.7 + 0.2, 1)
	new_player.playerColor = player_color
	new_player.playerName = namePlayer()
	add_child(new_player)
	players[client] = new_player
	playersAll[client] = new_player
	send_state_message(players[client])
	randomize()
	buttonTextHandler()

var names = [
	"Theon", "Sansa", "Jon", "Reek", "Arya", "Tyrion",
	"Daenerys", "Cersei", "Jaime", "Bran", "Jorah",
	"Samwell", "Brienne", "Davos", "Sandor", "Gregor",
	"Varys", "Bronn", "Missandei", "Gendry", "Rickon",
	"Catelyn", "Eddard", "Robert", "Rhaeger", "Lyanna",
	"Tywin", "Frodo", "Podrick", "Petyr", "Joffrey",
	"Melisandre", "Ygritte", "Hot Pie", "Margaery",
	"Stannis", "Ramsay", "Myrcella", "Shae", "Yara",
	"Gilly", "Olenna", "Oberyn", "HODOR"
]

var bastardNames = [
	"Snow", "Rivers", "Sand", "Hill", "Pyke", "Waters", "Stone"
]

func namePlayer():
	if names.size() > 0:
		var index = randi() % names.size()
		var player_name = names[index]
		names.erase(names[index])
		return player_name
	else:
		var index = randi() % bastardNames.size()
		var player_name = bastardNames[index]
		return player_name


func _on_player_bow_charge():
	power = 0
	power += power_increase_rate * delta
	if power > max_power:
		power = max_power


func _on_player_bow_shot(player, power, lift):
	var velocity = Vector2(30*power, 0)
	var bow = player.get_node('Bow')
	velocity = velocity.rotated(bow.rotation)
	velocity += player.velocity
	var arrow = arrow_scene.instantiate()
	arrow.set_graphic(bow.arrow_graphic_name)
	arrow.global_position = bow.global_position + Vector2(29,0).rotated(bow.rotation)
	arrow.linear_velocity = velocity
	arrow.rotation = bow.rotation
	arrow.z_velo = lift #4+0.1*power
	arrow.originPlayer = player.playerID
	arrow.damage = player.arrowDamage
	arrow.drag = player.arrowDrag
	add_child(arrow)


func multiplayerSetup():
	multiplayerStarted = true
	pvpOn = true
	menuElemPos = $MenuElements.position
	$MenuElements.position = Vector2(-5000,-5000)
	for player in players:
		players[player].resetUpgrades()
	roundInit()


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
		players[player].refresh()
		players[player].global_position = spawn_position
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

@export var numDummy = 2
func roundInit():
	$Dummies.position = Vector2(-5000,-5000)
	$MusicPlayer.stop()
	clearJunk()
	spawnDummy(numDummy)
	universalControl(false)
	pvpOn = true
	placeEvenly()
	sfxManager(wardrums)
	textBoxLabel.text = "Round "+str(roundNumber)
	textBox.visible = true
	await get_tree().create_timer(1.5).timeout
	textBoxLabel.text = "Ready?"
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
	$Dummies.position = Vector2(0,0)
	pvpOn = false
	clearJunk()
	$BarrelTimer.stop()
	$MusicPlayer.stop()
	sfxManager(fanfare)
	var tempC = winner.playerColor
	var hex_color = tempC.to_html(false)
	if winner.gameScore == gamesNeeded4Win:
		winner.winner()
		richTextLabel.text = "[center][color=#" + hex_color + "]"+winner.playerName+"[/color] Wins the Game!"
		richTextBox.visible = true
		await get_tree().create_timer(4.0).timeout
		scoreboard(true)
		await get_tree().create_timer(4.0).timeout
		richTextBox.visible = false
		gameOver()
	else:
		richTextBox.clearScores()
		richTextLabel.text = "[center][color=#" + hex_color + "]"+winner.playerName+"[/color] has won the Round!"
		richTextBox.visible = true
		await get_tree().create_timer(2.0).timeout
		for player in players:
			players[player].randomizeUpgradeOptions()
			players[player].state = "upgrading"
			if players[player] == winner:
				winner.upgradePoints = 2
			else:
				players[player].upgradePoints = 1
			send_state_message(players[player])
		scoreboard()
		roundNumber += 1
		await $SoundEffects.finished
		musicManager(jaunt)
		await readyUpGamepad()
		richTextBox.visible = false
		richTextBox.clearScores()
		for player in players:
			players[player].state = "playing"
			players[player].upgradePoints = 0
		send_all_states()
		roundInit()
	pass

func scoreboard(won = false):
	richTextBox.clearScores()
	sortByWins()
	richTextLabel.text = "[center]Scores[/center]"
	if len(players.values()) > 5:
		richTextLabel.text = "[center]Top 5 Scores[/center]"
	if won:
		richTextLabel.text = "[center]Final Scores[/center]"
	var count = 0
	for player in playersByWins:
		richTextBox.newScoreLabel(player.playerName, player.playerColor, player.gameScore, won)
		if won:
			won = false
		count += 1
		if count == 5:
			break


var playersByWins = []
func sortByWins():
	playersByWins.clear()
	for player in players:
		playersByWins.append(players[player])
	
	# Directly sort the playersByWins array based on gameScore in descending order
	playersByWins.sort_custom(func(a, b):
		if a.gameScore > b.gameScore:
			return true
		return false
	)
#This code just print the scoreboard in console. Might be useful for debugging one day.
	#for player in playersByWins:
		#print(player.playerName + " " + str(player.gameScore))
	#print("----------")


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
	bttnLabel.text = "Shoot to Start Game"
	$MenuElements.position = Vector2(0,0)
	$Dummies.position = Vector2(0,0)
	for player in players:
		players[player].restoreAll()
		players[player].unspawned = true
		players[player].global_position = Vector2(-5000, -5000)
	players = {}
	pass

#Turns controls off or on for all players
func universalControl(state):
	for player in players:
		players[player].controllable = state

func clearJunk():
	for child in get_children():
		if child.has_method("clean"):
			child.clean()


@onready var buttonLabel = $MenuElements/MultiplayerButton/MultiplayerButtonLabel
@onready var bttnLabel = $MenuElements/MultiplayerButton/CenterContainer/MultiPLabel
func _on_multiplayer_button_body_entered(body):
	if !(body is Arrow):
		return
	var numPlayers = len(players.values())
	body.hitButton()
	if body.originPlayer not in readiedPlayers:
		readiedPlayers.append(body.originPlayer)
		if len(players.values()) == 1:
			bttnLabel.text = "More Players Must Join to Start!"
		else:
			bttnLabel.text = "Players Ready"
			bttnLabel.text += "\n("+str(readiedPlayers.size())+"/"+str(numPlayers)+")"
		await get_tree().create_timer(0.5).timeout
	if readiedPlayers.size() == numPlayers and numPlayers > 1:
		multiplayerSetup()

func buttonTextHandler():
	var numPlayers = len(players.values())
	if bttnLabel.text == "More Players Must Join to Start!" and numPlayers > 1:
		bttnLabel.text = "Players Ready"
		bttnLabel.text += "\n("+str(readiedPlayers.size())+"/"+str(numPlayers)+")"
	if bttnLabel.text.contains("Ready"):
		bttnLabel.text = "Players Ready"
		bttnLabel.text += "\n("+str(readiedPlayers.size())+"/"+str(numPlayers)+")"
	pass


var numBarrels = 0
@export var barrelWaitTime = 5
func _on_barrel_timer_timeout():
	if numBarrels < maxBarrelCount:
		barrelLogic()

var activeBarrels = []
func barrelLogic():
	if numBarrels == 0:
		activeBarrels.clear()
	var barrelPos = Vector2()
	randomize()
	barrelPos.x = vpSize.x*randf_range(.9,.1)
	barrelPos.y = vpSize.y*randf_range(.9,.1)
	# Checks if barrel is close to other barrels and trys again
	for barrels in activeBarrels:
		if barrels.global_position.distance_to(barrelPos) < 100:
			barrelLogic()
			return
	var barrel = barrel_scene.instantiate()
	barrel.global_position = barrelPos
	add_child(barrel)
	numBarrels += 1
	activeBarrels.append(barrel)
	pass

func spawnDummy(amount):
	for i in range(amount):
		randomize()
		var dummyPos = Vector2()
		dummyPos.x = vpSize.x*randf_range(.8,.2)
		dummyPos.y = vpSize.y*randf_range(.8,.2)
		var dummy = dummy_scene.instantiate()
		dummy.global_position = dummyPos
		dummy.temp = true
		add_child(dummy)

func settingsButtonHandler():
	var button = Autoloader.buttonRef
	Autoloader.buttonRef = null
	if button.getText() == "Free for All":
		button.setText("Survival")
		return
	if button.getText() == "Survival":
		button.setText("Story")
		return
	if button.getText() == "Story":
		button.setText("Free for All")
		return

func createButton(text : String, function : Callable):
	var new_button = button_scene.instantiate()
	new_button.buttonText = text
	new_button.connect("buttonFunction", function)
	$MenuElements/VBoxContainer.add_child(new_button)
	pass

func musicManager(song):
	$MusicPlayer.stream = song
	$MusicPlayer.play()

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()


