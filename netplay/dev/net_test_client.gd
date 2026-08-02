extends SceneTree
# Integration test, client side. Start after net_test_host.gd.
#   ARCHERS_WS=ws://127.0.0.1:8787 godot --headless -s netplay/dev/net_test_client.gd
# Joins room "t1", asserts snapshots arrive, puppets spawn/move, arrows appear.

var fails := 0

func _check(cond: bool, what: String):
	if cond:
		print("PASS: " + what)
	else:
		fails += 1
		print("FAIL: " + what)

func _initialize():
	_run.call_deferred()

func _run():
	await process_frame
	var al = root.get_node("Autoloader")
	al.net_mode = "client"
	al.net_room = "t1"
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	var cp = main.get_node("Controlpads")
	var got_snap := [false]
	cp.get_node("Relay").snap_received.connect(func(_s): got_snap[0] = true)

	var waited := 0.0
	while not got_snap[0] and waited < 10.0:
		await create_timer(0.2).timeout
		waited += 0.2
	_check(got_snap[0], "snapshot received")
	if not got_snap[0]:
		quit(1)
		return

	cp._on_local_message("move:16,0") # our input -> relay -> host sim
	await create_timer(2.0).timeout
	var n: int = cp.puppets.players.size()
	_check(n >= 2, "host + own player puppets present (n=%d)" % n)

	var host_puppet = cp.puppets.players.values()[0]
	var x0: float = host_puppet.global_position.x
	var saw_arrow := false
	for i in 40:
		await create_timer(0.2).timeout
		if cp.puppets.ents.arrows.size() > 0:
			saw_arrow = true
	_check(saw_arrow, "arrow puppets appeared")
	_check(cp.puppets.ents.barrels.size() >= 1, "menu barrel puppet present")
	_check(abs(host_puppet.global_position.x - x0) > 10, "puppets interpolate movement")

	print("RESULT: " + ("OK" if fails == 0 else "%d FAILURES" % fails))
	quit(fails)
