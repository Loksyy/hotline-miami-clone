extends SceneTree
const Game = preload("res://scripts/game/main.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	print("Configured cap: ", Engine.max_fps, " / VSync: ", game.preferences.vsync)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game.sound.muted = true
	for mode in ["editor", "playtest"]:
		if mode == "playtest": game.toggle_mode(); game.enemies.clear()
		for i in 120: await process_frame
		var started := Time.get_ticks_usec()
		var draw_total := 0.0
		for i in 360:
			await process_frame
			draw_total += game.draw_cpu_us
		print(mode, " average FPS=", snappedf(360000000.0 / (Time.get_ticks_usec() - started), 0.1), " draw script ms=", snappedf(draw_total / 360000.0, 0.001))
	game.queue_free()
	await process_frame
	quit()
