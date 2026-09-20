extends Node
# Keyboard + mouse for the player at this computer.
#   WASD / arrow keys: move.  Mouse: aim.  Hold left mouse (or space) to draw
#   the bow, let go to shoot.

const SEND_EVERY = 2 # physics frames, unless draw changes

var main = null
var frame = 0
var lastAim = 0.0
var lastDraw = false
var seq = 0


var bot = null # tests/bot.gd, only when Net.bot

func _ready():
	main = get_parent()
	if Net.bot:
		bot = load("res://tests/bot.gd").new()
		add_child(bot)


func _physics_process(_delta):
	if Net.dedicated:
		return
	var move = Vector2(
		int(key(KEY_D) or key(KEY_RIGHT)) - int(key(KEY_A) or key(KEY_LEFT)),
		int(key(KEY_S) or key(KEY_DOWN)) - int(key(KEY_W) or key(KEY_UP))
	).normalized()

	var me = main.get_my_player() if Net.is_host else main.get_node("Replicator").get_my_puppet()
	var mouse = main.get_viewport().get_mouse_position()
	if me != null and mouse.distance_to(me.position) > 1:
		lastAim = (mouse - me.position).angle()

	var draw = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or key(KEY_SPACE)
	if main.upgradeMenu.is_open():
		draw = false
	if bot != null:
		move = bot.move
		lastAim = bot.aim
		draw = bot.draw

	if Net.is_host:
		main.handle_input(Net.my_id, move, lastAim, draw)
		return

	# don't wait on the round trip to see my own aim
	if me != null:
		me.get_node("Bow").rotation = lastAim
		me.get_node("Eyes").set_direction(lastAim if draw or move == Vector2.ZERO else move.angle())

	# always send, even when nothing changed: the host echoes the seq back
	# and that is what keeps my predicted position honest
	frame += 1
	var sendNow = frame % SEND_EVERY == 0 or draw != lastDraw
	if sendNow:
		seq += 1
		Net.send_host(["in", move, lastAim, draw, seq])
		lastDraw = draw
	main.get_node("Replicator").predict(move, seq, sendNow)


func key(code):
	return Input.is_physical_key_pressed(code)
