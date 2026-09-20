extends Node
# Host: ~30 times a second, describe every moving thing under Main and send it
# to the clients. Client: keep a puppet per described thing and glide it
# between the two most recent descriptions.

const SCENES = {
	"player": preload("res://player.tscn"),
	"arrow": preload("res://arrow.tscn"),
	"barrel": preload("res://barrel.tscn"),
	"potion": preload("res://potion.tscn"),
	"wolf": preload("res://wolf.tscn"),
	"wolfbar": preload("res://wolf_healthbar.tscn"),
	"dummy": preload("res://dummy.tscn"),
}
const FX_SCENES = {
	"death": preload("res://death_explosion.tscn"),
	"barrel": preload("res://barrel_explosion.tscn"),
}
const SEND_EVERY = 2 # physics frames
const TELEPORT_DISTANCE = 250.0
# Clients draw everyone else this far in the past so there are always two
# snapshots to glide between, even when the network delivers them in clumps
const RENDER_DELAY_MS = 80.0
const MAX_EXTRAPOLATE_MS = 100.0
# My own player moves right away on my inputs and gets nudged to agree with the host
const CORRECTION_DEADZONE = 12.0
const CORRECTION_RATE = 0.15

var main = null
var kindOfScene = {}
var frame = 0

# client side
var puppets = {} # host instance id -> {node, kind, samples: [[hostMs, pos, rot]...]}
var clockOffset = INF # my clock minus the host's, as seen by the fastest snapshot so far
var myRecord = null
var predicting = false
var history = [] # [[input seq, where I predicted I was when I sent it]...]
var pingMs = 0.0


func _ready():
	main = get_parent()
	for kind in SCENES:
		kindOfScene[SCENES[kind].resource_path] = kind
	if Net.is_client:
		Net.packet.connect(_on_packet)


func _physics_process(_delta):
	if not Net.is_host:
		return
	frame += 1
	if frame % SEND_EVERY != 0:
		return
	if not Net.has_clients():
		Net.take_events()
		return
	var ents = {}
	for child in main.get_children():
		var kind = kindOfScene.get(child.scene_file_path)
		if kind != null and not child.is_queued_for_deletion():
			ents[child.get_instance_id()] = describe(kind, child)
	# stamped in simulation time, which advances evenly even when frames don't
	var hostMs = frame * 1000.0 / Engine.physics_ticks_per_second
	Net.broadcast(["snap", hostMs, ents, main.get_ui_state(), Net.take_events()])


################################################################################
# Host

func describe(kind, n):
	match kind:
		"player":
			return [kind, n.position, n.playerID, n.get_node("Nametag/Label").text,
				n.playerColor, n.get_node("Bow").rotation, n.get_node("Bow/Sprite2D").frame,
				n.get_node("Bow/Arrow").visible, n.get_node("Bow").charge_amount,
				n.get_node("Healthbar").value, n.get_node("Healthbar").max_value,
				n.get_node("Healthbar/Damagebar").value, n.get_node("Eyes").eye_direction,
				n.modulate.a, n.equipment['bow'], n.equipment['arrow'], n.equipment['armor'],
				n.lastInputSeq, n.controllable and not n.isDead, n.speedMultiplier]
		"arrow":
			return [kind, n.position, n.rotation, n.scale.x, n.get_node("Sprite2D").frame,
				n.get_node("Sprite2D").modulate, n.graphicName]
		"barrel":
			return [kind, n.position, n.modulate.a, n.get_node("BarrelTopHalf").visible,
				n.get_node("BarrelSprite").modulate]
		"potion":
			return [kind, n.position, n.scale.x]
		"wolf":
			return [kind, n.position, n.rotation, n.get_node("Sprite2D").modulate]
		"wolfbar":
			return [kind, n.position, n.value, n.max_value, n.get_node("Damagebar").value, n.visible]
	return [kind, n.position]


################################################################################
# Client

func _on_packet(_from, data):
	if typeof(data) != TYPE_ARRAY or data.size() != 5 or data[0] != "snap":
		return
	var hostMs = data[1]
	var lag = Time.get_ticks_msec() - hostMs
	# creep upward so a drifting clock can't pin us to a stale minimum
	clockOffset = min(clockOffset + 0.05, lag)

	var ents = data[2]
	for id in puppets.keys():
		if id not in ents:
			if puppets[id] == myRecord:
				myRecord = null
				predicting = false
			puppets[id].node.queue_free()
			puppets.erase(id)
	for id in ents:
		var d = ents[id]
		if id not in puppets:
			puppets[id] = spawn(d)
		update(puppets[id], d, hostMs)
	main.apply_ui_state(data[3])
	for ev in data[4]:
		play_event(ev)


func _process(_delta):
	if not Net.is_client or clockOffset == INF:
		return
	var renderMs = Time.get_ticks_msec() - clockOffset - RENDER_DELAY_MS
	for id in puppets:
		var p = puppets[id]
		if p == myRecord and predicting:
			continue
		var pose = sample(p.samples, renderMs)
		p.node.position = pose[0]
		if p.kind == "wolf":
			p.node.rotation = pose[1]


# Where was this thing at renderMs on the host's clock?
func sample(samples, renderMs):
	while samples.size() > 2 and samples[1][0] <= renderMs:
		samples.pop_front()
	var a = samples[0]
	if samples.size() == 1 or renderMs <= a[0]:
		return [a[1], a[2]]
	var b = samples[1]
	if a[1].distance_to(b[1]) > TELEPORT_DISTANCE:
		return [b[1], b[2]]
	var span = max(b[0] - a[0], 1.0)
	var t = min((renderMs - a[0]) / span, 1.0 + MAX_EXTRAPOLATE_MS / span)
	return [a[1].lerp(b[1], t), lerp_angle(a[2], b[2], min(t, 1.0))]


# Client-side prediction for my own player. local_input.gd calls this every
# physics frame with the input it is about to send.
func predict(move, seq, sentNow):
	if myRecord == null or not predicting:
		history.clear()
		return
	var me = myRecord.node
	me.velocity = move.limit_length(1.0) * me.MOVE_SCALE * myRecord.speed
	me.move_and_slide()
	if sentNow:
		history.append([seq, me.position, Time.get_ticks_msec()])
		if history.size() > 120:
			history.pop_front()


# The host says: "after your input #ack you were at hostPos"
func reconcile(ack, hostPos):
	while history.size() > 0 and history[0][0] < ack:
		history.pop_front()
	if history.size() == 0 or history[0][0] != ack:
		return
	pingMs = lerp(pingMs, float(Time.get_ticks_msec() - history[0][2]), 0.1)
	var err = hostPos - history[0][1]
	if err.length() > TELEPORT_DISTANCE:
		myRecord.node.position = hostPos
		history.clear()
		return
	# small disagreements are normal while running; settle them once I stop
	if err.length() < CORRECTION_DEADZONE and myRecord.node.velocity != Vector2.ZERO:
		return
	var fix = err * CORRECTION_RATE
	myRecord.node.position += fix
	for h in history:
		h[1] += fix


func spawn(d):
	var kind = d[0]
	var node = SCENES[kind].instantiate()
	if kind == "player":
		node.playerID = d[2]
		node.playerName = d[3]
		node.playerColor = d[4]
	if node is RigidBody2D:
		node.freeze = true
	node.position = d[1]
	main.add_child(node)
	make_puppet(node)
	# players keep _process: it drives their charge/health bar visibility
	if kind != "player":
		node.set_process(false)
	node.set_physics_process(false)
	var record = {"node": node, "kind": kind, "samples": [], "speed": 0.0}
	if kind == "player" and d[2] == Net.my_id:
		myRecord = record
		# my own body needs to bump into walls while predicting
		node.get_node("CollisionShape2D").set_deferred("disabled", false)
	return record


# Nothing on a client should collide, tick or time out by itself
func make_puppet(node):
	for child in node.get_children():
		make_puppet(child)
	if node is CollisionShape2D or node is CollisionPolygon2D:
		# barrels and dummies stay solid so my predicted player can't walk through them
		if not node.get_parent() is StaticBody2D:
			node.set_deferred("disabled", true)
	elif node is Area2D:
		node.set_deferred("monitoring", false)
	elif node is Timer:
		node.stop()


func update(p, d, hostMs):
	var n = p.node
	p.samples.append([hostMs, d[1], d[2] if p.kind == "wolf" else 0.0])
	if p.samples.size() > 30:
		p.samples.pop_front()
	if p == myRecord:
		p.speed = d[19]
		if d[18] and not predicting:
			n.position = d[1]
			history.clear()
		predicting = d[18]
		if predicting:
			reconcile(d[17], d[1])
	match p.kind:
		"player":
			n.get_node("Nametag/Label").text = d[3]
			var bow = n.get_node("Bow")
			# my own bow and eyes follow my mouse right away; see local_input.gd
			if d[2] != Net.my_id:
				bow.rotation = d[5]
				n.get_node("Eyes").set_direction(d[12])
			bow.get_node("Sprite2D").frame = d[6]
			bow.get_node("Arrow").visible = d[7]
			bow.charge_amount = d[8]
			n.get_node("Healthbar").max_value = d[10]
			n.get_node("Healthbar").value = d[9]
			n.get_node("Healthbar/Damagebar").max_value = d[10]
			n.get_node("Healthbar/Damagebar").value = d[11]
			n.get_node("Healthbar/Damagebar").visible = true
			n.modulate.a = d[13]
			if n.equipment['bow'] != d[14]:
				n.setBow(d[14])
			if n.equipment['arrow'] != d[15]:
				n.setArrow(d[15])
			if n.equipment['armor'] != d[16]:
				n.setArmor(d[16])
		"arrow":
			n.rotation = d[2]
			n.scale = Vector2(d[3], d[3])
			n.get_node("Sprite2D").frame = d[4]
			n.get_node("Sprite2D").modulate = d[5]
			n.set_graphic(d[6])
		"barrel":
			n.modulate.a = d[2]
			n.get_node("BarrelTopHalf").visible = d[3]
			n.get_node("BarrelSprite").modulate = d[4]
		"potion":
			n.scale = Vector2(d[2], d[2])
		"wolf":
			n.get_node("Sprite2D").modulate = d[3]
		"wolfbar":
			n.max_value = d[3]
			n.value = d[2]
			n.get_node("Damagebar").value = d[4]
			n.visible = d[5]


func play_event(ev):
	match ev[0]:
		"dmg":
			Autoloader.damageNumbers(ev[1], ev[2], ev[3])
		"fx":
			var fx = FX_SCENES[ev[1]].instantiate()
			fx.position = ev[2]
			fx.emitting = true
			if ev.size() > 3:
				fx.modulate = ev[3]
			main.add_child(fx)
			get_tree().create_timer(fx.lifetime + 1.0).timeout.connect(fx.queue_free)


func get_my_puppet():
	return myRecord.node if myRecord != null else null
