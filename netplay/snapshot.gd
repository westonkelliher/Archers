class_name NetSnapshot
extends RefCounted
# Host-side: serialize the live game into a Dictionary broadcast to clients.
# Clients render it via netplay/puppets.gd. JSON-friendly (v1; see
# ARCHITECTURE.md for the binary-delta evolution path).

static func _script_is(node: Node, filename: String) -> bool:
	var s = node.get_script()
	return s != null and s.resource_path.ends_with(filename)

static func capture(main) -> Dictionary:
	var snap := {
		"players": {}, "arrows": {}, "barrels": {},
		"dummies": {}, "potions": {}, "wolves": {}, "ui": {},
	}
	for id in main.players:
		var p = main.players[id]
		var bow = p.get_node("Bow")
		snap.players[id] = {
			"x": snappedf(p.global_position.x, 0.1), "y": snappedf(p.global_position.y, 0.1),
			"nm": p.get_node("Nametag/Label").text,
			"col": p.playerColor.to_html(false),
			"hp": p.get_node("Healthbar").value, "mhp": p.get_node("Healthbar").max_value,
			"br": snappedf(bow.rotation, 0.01), "pl": bow.is_pulling,
			"ey": snappedf(p.get_node("Eyes").eye_direction, 0.01),
			"dead": p.isDead, "ma": snappedf(p.modulate.a, 0.01),
			"cr": p.get_node("RoyalCrown").visible,
			"bw": p.equipment["bow"], "ar": p.equipment["arrow"], "am": p.equipment["armor"],
		}
	for c in main.get_children():
		var iid := str(c.get_instance_id())
		if c is Arrow:
			var spr = c.get_node("Sprite2D")
			snap.arrows[iid] = {
				"x": snappedf(c.global_position.x, 0.1), "y": snappedf(c.global_position.y, 0.1),
				"r": snappedf(c.rotation, 0.01), "sc": snappedf(c.arrowScale, 0.01),
				"fr": spr.frame, "tex": spr.texture.resource_path,
			}
		elif _script_is(c, "Barrel.gd"):
			snap.barrels[iid] = {"x": c.global_position.x, "y": c.global_position.y}
		elif _script_is(c, "dummy.gd"):
			snap.dummies[iid] = {"x": c.global_position.x, "y": c.global_position.y}
		elif _script_is(c, "potion.gd"):
			snap.potions[iid] = {
				"x": snappedf(c.global_position.x, 0.1), "y": snappedf(c.global_position.y, 0.1),
				"sc": snappedf(c.scale.x, 0.01),
			}
		elif _script_is(c, "wolf.gd"):
			snap.wolves[iid] = {
				"x": snappedf(c.global_position.x, 0.1), "y": snappedf(c.global_position.y, 0.1),
				"r": snappedf(c.rotation, 0.01), "hp": c.hitpoints,
			}

	var scores := []
	for l in main.richTextBox.get_node("MarginContainer/VBoxContainer").get_children():
		if l is PlayerScoreLabel:
			scores.append([l.playerName, l.playerColor.to_html(false), l.playerScore, l.won])
	var music = main.get_node("MusicPlayer")
	var sfx = main.get_node("SoundEffects")
	snap.ui = {
		"tb": [main.textBox.visible, main.textBoxLabel.text],
		"rt": [main.richTextBox.visible, main.richTextLabel.text],
		"sc": scores,
		"mp": [main.get_node("MenuElements").position.x, main.get_node("MenuElements").position.y],
		"bt": main.bttnLabel.text,
		"dp": [main.get_node("Dummies").position.x, main.get_node("Dummies").position.y],
		"mu": music.stream.resource_path if music.stream != null and music.playing else "",
		"sfx": sfx.stream.resource_path if sfx.stream != null and sfx.playing else "",
	}
	return snap
