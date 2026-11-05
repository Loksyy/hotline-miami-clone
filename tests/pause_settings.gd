extends SceneTree
const Game = preload("res://scripts/main.gd")
const Preferences = preload("res://scripts/runtime_settings.gd")
const Maps = preload("res://scripts/map_data.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.preferences.storage_path = "user://pause_settings_test.cfg"
	game.sound.muted = true
	game.toggle_mode()
	check(not game.editing, "Playtest starts before pause")
	game.weapon = "PISTOL"
	game.ammo = 0
	game.reserve_ammo = 8
	game.start_reload()
	var time_before: float = game.elapsed
	var reload_before: float = game.reload_remaining
	var player_before: Vector2 = game.player
	var map_before: Dictionary = game.map.duplicate(true)
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	game.pause_menu._input(escape)
	check(paused and game.pause_menu.overlay.visible, "Escape opens pause menu")
	check(not game.can_process() and game.pause_menu.can_process(), "Only menu processes during pause")
	await process_frame
	await process_frame
	check(game.elapsed == time_before and game.reload_remaining == reload_before and game.player == player_before, "Pause freezes time, reload and movement")
	game.pause_menu.home.hide()
	game.pause_menu.settings_page.show()
	game.pause_menu._input(escape)
	check(paused and game.pause_menu.home.visible, "Escape from settings returns to paused menu")
	game.pause_menu._input(escape)
	check(not paused and not game.pause_menu.overlay.visible, "Escape resumes gameplay")
	await process_frame
	await process_frame
	check(game.elapsed > time_before, "Simulation resumes after unpausing")
	game.pause_menu.open_menu()
	game.pause_menu.return_to_editor()
	check(game.editing and not paused and game.map == map_before, "Menu returns to original editable map")
	game.painting = true
	game.workshop.mode = "insert_layout"
	game.pause_menu.open_menu()
	check(not game.painting and game.workshop.mode == "select", "Opening menu cancels pending editor gestures")
	game.pause_menu.close_menu()
	game.preferences.volume = 0.35
	game.preferences.show_fps = false
	game.preferences.frame_limit = 60
	game.preferences.save()
	var restored := Preferences.new()
	restored.storage_path = game.preferences.storage_path
	restored.load_settings()
	check(is_equal_approx(restored.volume, 0.35) and not restored.show_fps and restored.frame_limit == 60, "Settings persist and reload")
	DirAccess.remove_absolute(game.preferences.storage_path)
	var cached := Maps.starter()
	var original: int = cached.cells[0]
	cached.cells[0] = 6
	check(Maps.starter().cells[0] == original, "Editing a cached layout result cannot corrupt its template")
	game.sound.muted = false
	for i in 24: game.sound.play("shot")
	check(game.sound.get_child_count() == game.S.MAX_AUDIO_VOICES, "Rapid sounds reuse bounded voices")
	game.queue_free()
	await process_frame
	await process_frame
	print("Pause/settings checks: %d failures" % failures)
	quit(1 if failures else 0)
