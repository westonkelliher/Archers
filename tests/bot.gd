extends Node
# Headless test player: walks in circles, aims at the start button, shoots
# every couple of seconds, takes the first upgrade offered, and logs what it sees.

var move = Vector2.ZERO
var aim = 0.0
var draw = false
var t = 0.0
var logT = 0.0

func _process(delta):
	t += delta
	var main = Autoloader.mainScene
	move = Vector2.RIGHT.rotated(t)
	var me = main.get_my_player() if Net.is_host else main.get_node("Replicator").get_my_puppet()
	if me != null:
		aim = (Vector2(960, 576) - me.position).angle()
	# in a match: stand still and shoot at somebody
	if me != null and main.get_node("MenuElements").position != Vector2.ZERO:
		move = Vector2.ZERO
		for child in main.get_children():
			if child is Player and child != me and child.position.x > -1000:
				aim = (child.position - me.position).angle()
				if child.position.distance_to(me.position) > 300:
					move = Vector2.RIGHT.rotated(aim)
	draw = fmod(t, 2.0) < 1.5
	if main.upgradeMenu.is_open():
		main.upgradeMenu.pick('bow')
	logT += delta
	if logT > 3.0:
		logT = 0.0
		var kinds = {}
		for child in main.get_children():
			var k = child.scene_file_path.get_file()
			if k != "":
				kinds[k] = kinds.get(k, 0) + 1
		print("[%s id=%d] hp=%s me=%s started=%s text='%s' btn='%s' music=%s %s" % [
			"host" if Net.is_host else "client", Net.my_id,
			me.get_node("Healthbar").value if me != null else null,
			me.position if me != null else null, main.multiplayerStarted,
			(main.textBoxLabel.text if main.textBox.visible else "") + (main.richTextLabel.text if main.richTextBox.visible else "") + str(main.richTextBox.scoreRows.size()),
			main.bttnLabel.text.replace("\n", " "), main.musicPath.get_file(), kinds])
