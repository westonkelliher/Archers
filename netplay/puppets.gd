extends Node
# Client-side: renders host snapshots using the real game scenes in "puppet"
# mode (no physics, no collisions, no local sim). Sounds/explosions/damage
# numbers are derived from state transitions so game scripts need no hooks.

const SMOOTH := 12.0 # exponential position smoothing rate

var main: Node
var players := {}  # playerID -> puppet Player
var ents := {"arrows": {}, "barrels": {}, "dummies": {}, "potions": {}, "wolves": {}}
var scenes := {
	"arrows": preload("res://arrow.tscn"),
	"barrels": preload("res://barrel.tscn"),
	"dummies": preload("res://dummy.tscn"),
	"potions": preload("res://potion.tscn"),
	"wolves": preload("res://wolf.tscn"),
}
var player_scene := preload("res://player.tscn")
var death_explosion := preload("res://death_explosion.tscn")
var barrel_explosion := preload("res://barrel_explosion.tscn")
var barrel_break_sfx := preload("res://audio/barrelBreak.mp3")
var wolf_death_sfx := preload("res://audio/sfx/wolf/death.ogg")
var _applied_scores := []
var _music_path := ""
var _sfx_path := ""

func _process(delta):
	var k := 1.0 - exp(-SMOOTH * delta)
	for node in _all_puppets():
		if not is_instance_valid(node):
			continue
		if node.has_meta("tpos"):
			node.global_position = node.global_position.lerp(node.get_meta("tpos"), k)
		if node.has_meta("trot"):
			node.rotation = lerp_angle(node.rotation, node.get_meta("trot"), k)

func _all_puppets() -> Array:
	var out := players.values()
	for cat in ents:
		out.append_array(ents[cat].values())
	return out

func apply(snap: Dictionary):
	if main == null:
		main = Autoloader.mainScene # set after our own _ready; resolve lazily
	if main == null or not is_instance_valid(main):
		return
	_apply_players(snap.get("players", {}))
	for cat in ents:
		_apply_entities(cat, snap.get(cat, {}))
	_apply_ui(snap.get("ui", {}))

################################################################################
# players

func _apply_players(data: Dictionary):
	for id in data:
		if not players.has(id):
			players[id] = _spawn_player(id, data[id])
		_update_player(players[id], data[id])
	for id in players.keys():
		if not data.has(id):
			if is_instance_valid(players[id]):
				players[id].queue_free()
			players.erase(id)

func _spawn_player(id, d) -> Node:
	var p = player_scene.instantiate()
	p.playerID = id
	p.playerName = d.nm
	p.playerColor = Color.from_string("#" + d.col, Color.WHITE)
	p.global_position = Vector2(d.x, d.y)
	_neuter(p, ["Area2D"])
	main.add_child(p)
	p.set_physics_process(false)
	return p

func _update_player(p, d: Dictionary):
	if not is_instance_valid(p):
		return
	var was := Vector2(p.get_meta("tpos", p.global_position))
	p.set_meta("tpos", Vector2(d.x, d.y))
	if Vector2(d.x, d.y).distance_to(was) > 300: # teleport (spawn/death), don't glide
		p.global_position = Vector2(d.x, d.y)
	var bow = p.get_node("Bow")
	bow.set_meta("trot", d.br)
	if d.pl and not bow.is_pulling:
		bow.pull_back(d.dead)
	elif not d.pl and bow.is_pulling:
		bow.release(d.dead)
	p.get_node("Eyes").set_direction(d.ey)
	p.get_node("Nametag/Label").text = d.nm
	p.get_node("RoyalCrown").visible = d.cr
	p.modulate.a = d.ma
	# equipment
	if p.equipment["bow"] != d.bw:
		p.setBow(d.bw)
	if p.equipment["arrow"] != d.ar:
		p.setArrow(d.ar)
	if p.equipment["armor"] != d.am:
		p.setArmor(d.am)
	# health (+ derived hurt/heal feedback)
	var hb = p.get_node("Healthbar")
	hb.max_value = d.mhp
	p.get_node("Healthbar/Damagebar").max_value = d.mhp
	var prev = hb.value
	if d.hp < prev:
		p.get_node("HurtSound").play()
		Autoloader.damageNumbers(int(prev - d.hp), p.get_node("DamageNumberOrigin").global_position)
	elif d.hp > prev and d.hp < d.mhp:
		Autoloader.damageNumbers(int(d.hp - prev), p.get_node("DamageNumberOrigin").global_position, "health")
	hb.value = d.hp
	p.get_node("Healthbar/Damagebar").value = d.hp
	# death explosion at last on-screen position
	if d.dead and not p.isDead:
		var expl = death_explosion.instantiate()
		expl.global_position = was
		expl.emitting = true
		expl.modulate = p.playerColor
		main.add_child(expl)
	p.isDead = d.dead

################################################################################
# other entities

func _apply_entities(cat: String, data: Dictionary):
	var pool: Dictionary = ents[cat]
	for iid in data:
		if not pool.has(iid):
			pool[iid] = _spawn_entity(cat, data[iid])
		_update_entity(cat, pool[iid], data[iid])
	for iid in pool.keys():
		if not data.has(iid):
			_despawn_entity(cat, pool[iid])
			pool.erase(iid)

func _spawn_entity(cat: String, d: Dictionary) -> Node:
	var n = scenes[cat].instantiate()
	n.global_position = Vector2(d.x, d.y)
	match cat:
		"arrows":
			n.freeze = true
			n.set_physics_process(false)
			n.get_node("Sprite2D").texture = load(d.tex)
		"barrels":
			n.debugBarrel = true # skips LifespanTimer; lifetime is host-driven
			_neuter(n, ["Area2D"])
		"dummies":
			_neuter(n, ["Hitbox"])
		"potions":
			n.monitoring = false
			n.set_process(false)
		"wolves":
			n.set_physics_process(false)
			_neuter(n, ["Bite", "Hitbox"])
	if n is CollisionObject2D:
		n.collision_layer = 0
		n.collision_mask = 0
	main.add_child(n)
	if cat == "arrows":
		n.get_node("CollisionShape2D").disabled = true
	return n

func _update_entity(cat: String, n, d: Dictionary):
	if not is_instance_valid(n):
		return
	if typeof(d.get("x")) not in [TYPE_FLOAT, TYPE_INT]:
		return # malformed entry; skip rather than crash the apply loop
	var prev: Vector2 = n.get_meta("tpos", n.global_position)
	n.set_meta("tpos", Vector2(d.x, d.y))
	match cat:
		"arrows":
			n.set_meta("trot", d.r)
			n.scale = Vector2(d.sc, d.sc)
			n.get_node("Sprite2D").frame = d.fr
		"potions":
			n.scale = Vector2(d.sc, d.sc)
		"barrels":
			# Host parks broken barrels offscreen while the break noise plays.
			if d.x < -400 and not n.get_meta("broken", false):
				n.set_meta("broken", true)
				_explode_barrel(prev)
				n.visible = false
				n.global_position = Vector2(d.x, d.y)
		"wolves":
			n.set_meta("trot", d.r)
			if d.hp < n.hitpoints and is_instance_valid(n.healthbar):
				n.healthbar.visible = true
				n.healthbar.value = d.hp
				n.hurt()
			n.hitpoints = d.hp

func _despawn_entity(cat: String, n):
	if not is_instance_valid(n):
		return
	if cat == "barrels" and not n.get_meta("broken", false):
		_explode_barrel(n.global_position)
	elif cat == "wolves":
		_play_at(wolf_death_sfx, n.global_position)
		if is_instance_valid(n.healthbar):
			n.healthbar.queue_free()
	n.queue_free()

func _explode_barrel(pos: Vector2):
	var expl = barrel_explosion.instantiate()
	expl.global_position = pos
	expl.emitting = true
	main.add_child(expl)
	_play_at(barrel_break_sfx, pos)

func _play_at(stream: AudioStream, pos: Vector2):
	var sp := AudioStreamPlayer2D.new()
	sp.stream = stream
	sp.global_position = pos
	main.add_child(sp)
	sp.play()
	sp.finished.connect(sp.queue_free)

# Disable Area2D children so puppet scenes never run their hit logic.
func _neuter(n: Node, areas: Array):
	for a in areas:
		var area = n.get_node_or_null(a)
		if area != null:
			area.monitoring = false
			area.monitorable = false

################################################################################
# UI / audio

func _apply_ui(ui: Dictionary):
	if ui.is_empty():
		return
	main.textBox.visible = ui.tb[0]
	main.textBoxLabel.text = ui.tb[1]
	main.richTextBox.visible = ui.rt[0]
	main.richTextLabel.text = ui.rt[1]
	main.get_node("MenuElements").position = Vector2(ui.mp[0], ui.mp[1])
	main.bttnLabel.text = ui.bt
	main.get_node("Dummies").position = Vector2(ui.dp[0], ui.dp[1])
	if str(ui.sc) != str(_applied_scores):
		_applied_scores = ui.sc
		main.richTextBox.clearScores()
		for s in ui.sc:
			main.richTextBox.newScoreLabel(s[0], Color.from_string("#" + s[1], Color.WHITE), int(s[2]), s[3])
	var music = main.get_node("MusicPlayer")
	if ui.mu != _music_path:
		_music_path = ui.mu
		if ui.mu == "":
			music.stop()
		else:
			music.stream = load(ui.mu)
			music.play()
	var sfx = main.get_node("SoundEffects")
	if ui.sfx != _sfx_path:
		_sfx_path = ui.sfx
		if ui.sfx != "":
			sfx.stream = load(ui.sfx)
			sfx.play()
