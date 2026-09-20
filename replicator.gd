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

var main = null
var kindOfScene = {}
var frame = 0

# client side
var puppets = {} # host instance id -> {node, kind, from, to, rotFrom, rotTo}
var lastArrival = 0.0
var interval = SEND_EVERY / 60.0


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
	Net.broadcast(["snap", ents, main.get_ui_state(), Net.take_events()])


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
				n.modulate.a, n.equipment['bow'], n.equipment['arrow'], n.equipment['armor']]
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
	if typeof(data) != TYPE_ARRAY or data.size() != 4 or data[0] != "snap":
		return
	var now = Time.get_ticks_msec() / 1000.0
	if lastArrival > 0:
		interval = lerp(interval, clamp(now - lastArrival, 0.01, 0.2), 0.1)
	lastArrival = now

	var ents = data[1]
	for id in puppets.keys():
		if id not in ents:
			puppets[id].node.queue_free()
			puppets.erase(id)
	for id in ents:
		var d = ents[id]
		if id not in puppets:
			puppets[id] = spawn(d)
		update(puppets[id], d)
	main.apply_ui_state(data[2])
	for ev in data[3]:
		play_event(ev)


func _process(_delta):
	if not Net.is_client:
		return
	var t = clamp((Time.get_ticks_msec() / 1000.0 - lastArrival) / interval, 0.0, 1.25)
	for id in puppets:
		var p = puppets[id]
		p.node.position = p.from.lerp(p.to, t)
		if p.kind == "wolf":
			p.node.rotation = lerp_angle(p.rotFrom, p.rotTo, min(t, 1.0))


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
	return {"node": node, "kind": kind, "from": d[1], "to": d[1], "rotFrom": 0.0, "rotTo": 0.0}


# Nothing on a client should collide, tick or time out by itself
func make_puppet(node):
	for child in node.get_children():
		make_puppet(child)
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", true)
	elif node is Area2D:
		node.set_deferred("monitoring", false)
	elif node is Timer:
		node.stop()


func update(p, d):
	var n = p.node
	p.from = n.position
	p.to = d[1]
	if p.from.distance_to(p.to) > TELEPORT_DISTANCE:
		p.from = p.to
		n.position = p.to
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
			p.rotFrom = n.rotation
			p.rotTo = d[2]
			n.get_node("Sprite2D").modulate = d[3]
		"wolfbar":
			n.max_value = d[3]
			n.value = d[2]
			n.get_node("Damagebar").value = d[4]
			n.visible = d[5]


func play_event(ev):
	match ev[0]:
		"snd":
			Net.play_remote(ev[1], ev[2])
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
	for id in puppets:
		if puppets[id].kind == "player" and puppets[id].node.playerID == Net.my_id:
			return puppets[id].node
	return null
