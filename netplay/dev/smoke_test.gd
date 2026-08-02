extends SceneTree
# Headless smoke test: godot --headless -s netplay/dev/smoke_test.gd
# Drives the controlpad protocol through the Net shim and asserts a player
# joins, moves, and fires an arrow.

var fails := 0

func _initialize():
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()

func _check(cond: bool, what: String):
	if cond:
		print("PASS: " + what)
	else:
		fails += 1
		print("FAIL: " + what)

func _run():
	for i in 5: await process_frame
	var main = root.get_node("Main")
	var cp = main.get_node("Controlpads")

	cp.message_received.emit("kbm", "move:16,0")
	_check(main.players.has("kbm"), "player joins on first message")
	var p = main.players["kbm"]
	var x0 = p.global_position.x
	for i in 30: await process_frame
	_check(p.global_position.x > x0 + 20, "player moves right (dx=%.0f)" % (p.global_position.x - x0))

	cp.message_received.emit("kbm", "move:0,0")
	cp.message_received.emit("kbm", "bow:16,0")
	await process_frame
	_check(p.get_node("Bow").is_pulling, "bow starts pulling")
	for i in 70: await process_frame
	_check(p.get_node("Bow").charge_amount > 0, "bow charges over time")

	cp.message_received.emit("kbm", "bow:0.1,0")
	await process_frame
	var arrows := 0
	for c in main.get_children():
		if c is Arrow:
			arrows += 1
	_check(arrows == 1, "arrow fired on release (n=%d)" % arrows)
	_check(not p.get_node("Bow").is_pulling, "bow released")

	print("RESULT: " + ("OK" if fails == 0 else "%d FAILURES" % fails))
	quit(fails)
