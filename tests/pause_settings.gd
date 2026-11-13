extends SceneTree
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
const PlayerSettings = preload("res://scripts/settings/player_settings.gd")
const Game = preload("res://scripts/game/main.gd")
const Preferences = preload("res://scripts/settings/runtime_settings.gd")
const Maps = preload("res://scripts/maps/map_data.gd")
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
	var gear = game.workshop.find_child("SettingsButton", true, false)
	check(gear != null, "Toolbar has settings gear")
	gear.pressed.emit()
	check(paused and game.pause_menu.settings_page.visible and not game.pause_menu.home.visible, "Gear opens settings directly and pauses")
	if "--preview" in OS.get_cmdline_user_args():
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/settings-menu.png")
	game.pause_menu.close_menu()
	game.preferences.editor_grid = false
	game.preferences.zoom_sensitivity = 1.5
	game.preferences.snap_objects = false
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
	game.workshop.snap_input.button_pressed = not game.workshop.snap_input.button_pressed
	check(game.preferences.snap_objects == game.workshop.snap_input.button_pressed, "Inspector snap updates preference")
	game.pause_menu.open_settings()
	check(game.pause_menu.preference_toggles.snap_objects.button_pressed == game.preferences.snap_objects, "Settings refresh snapping on reopen")
	game.pause_menu.close_menu()
	game.preferences.snap_objects = false
	game.preferences.volume = 0.35
	game.preferences.show_fps = false
	game.preferences.frame_limit = 60
	game.preferences.save()
	var restored := Preferences.new()
	restored.storage_path = game.preferences.storage_path
	restored.load_settings()
	check(is_equal_approx(restored.volume, 0.35) and not restored.show_fps and restored.frame_limit == 60, "Settings persist and reload")
	check(not restored.editor_grid and not restored.snap_objects and restored.zoom_sensitivity == 1.5, "Editor preferences persist")
	DirAccess.remove_absolute(game.preferences.storage_path)
	var cached := Maps.starter()
	var original: int = cached.cells[0]
	cached.cells[0] = 6
	check(Maps.starter().cells[0] == original, "Editing a cached layout result cannot corrupt its template")
	game.sound.muted = false
	for i in 24: game.sound.play("shot")
	check(game.sound.get_child_count() == EditorVisualsSettings.MAX_AUDIO_VOICES, "Rapid sounds reuse bounded voices")
	game.toggle_mode()
	check(game.workshop.play_lab_panel.visible and not game.workshop.window.visible, "Playtest replaces editor sidebar with Developer Lab")
	check(not paused, "Sidebar tuning does not pause the game")
	game.toggle_mode()
	check(not game.workshop.play_lab_panel.visible and game.workshop.window.visible, "Returning to editor restores its sidebar")
	game.toggle_mode()
	var old_width := game.MAP_VIEW.size.x
	var old_zoom := game.camera_zoom()
	game.workshop.sidebar_button.pressed.emit()
	check(game.MAP_VIEW.size.x > old_width and game.MAP_VIEW.end.x == 1888, "Hiding sidebar expands playable viewport")
	check(game.screen_to_world(game.MAP_VIEW.get_center()).is_equal_approx(game.camera_center()), "Expanded viewport mouse coordinates stay centered on camera")
	check(game.camera_zoom() == old_zoom, "Wider viewport keeps world proportions")
	game.workshop.sidebar_button.pressed.emit()
	check(game.MAP_VIEW.size.x == old_width, "Showing sidebar restores viewport")
	var normal_zoom := game.camera_zoom()
	var cursor := game.MAP_VIEW.get_center() + Vector2(game.MAP_VIEW.size.x * 0.4, 0)
	game.update_look_ahead(0.1, true, cursor)
	check(game.look_offset.x > 0 and is_zero_approx(game.look_offset.y), "Shift pans toward the cursor")
	check(is_equal_approx(game.camera_zoom(), normal_zoom), "Shift keeps zoom unchanged")
	var previous_offset := game.look_offset.length()
	game.update_look_ahead(0.1, false, cursor)
	check(game.look_offset.length() < previous_offset, "Release returns camera toward player")
	game.update_look_ahead(10.0, true, cursor)
	check(game.look_offset.length() <= PlayerSettings.SHIFT_LOOK_DISTANCE, "Look-ahead stays bounded")
	game.update_look_ahead(10.0, true, Vector2(1500, 500))
	check(game.look_offset.length() < 0.01, "Sidebar interaction recenters look-ahead")
	game.reset_game()
	check(game.look_offset == Vector2.ZERO, "Restart clears look-ahead")
	game.queue_free()
	await process_frame
	# Let the audio thread release the eight just-started playback voices.
	await create_timer(0.1).timeout
	print("Pause/settings checks: %d failures" % failures)
	quit(1 if failures else 0)
