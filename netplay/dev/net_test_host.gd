extends SceneTree
# Integration test, host side. Run with ARCHERS_WS=ws://127.0.0.1:8787
#   godot --headless -s netplay/dev/net_test_host.gd
# Joins room "t1" as host, moves the local player, and fires arrows for ~20s.

func _initialize():
	_run.call_deferred()

func _run():
	await process_frame
	var al = root.get_node("Autoloader")
	al.net_mode = "host"
	al.net_room = "t1"
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	var cp = main.get_node("Controlpads")
	var relay = cp.get_node("Relay")
	var waited := 0.0
	while relay.ws.get_ready_state() != WebSocketPeer.STATE_OPEN and waited < 10.0:
		await create_timer(0.2).timeout
		waited += 0.2
	if relay.ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("HOST FAIL: relay never opened")
		quit(1)
		return
	print("HOST: relay open")
	cp.message_received.emit("kbm", "move:8,3")
	for i in 8:
		cp.message_received.emit("kbm", "bow:16,0")
		await create_timer(1.2).timeout
		cp.message_received.emit("kbm", "bow:0.1,0")
		await create_timer(1.2).timeout
	print("HOST: done")
	quit(0)
