extends RefCounted
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
## Player preferences, saved separately from the grouped developer settings.
const SAVE_PATH := "user://preferences.cfg"
var storage_path := SAVE_PATH
var volume := EditorVisualsSettings.DEFAULT_VOLUME
var show_fps := EditorVisualsSettings.DEFAULT_SHOW_FPS
var screen_shake := EditorVisualsSettings.DEFAULT_SCREEN_SHAKE
var vsync := EditorVisualsSettings.DEFAULT_VSYNC
var frame_limit := EditorVisualsSettings.DEFAULT_FRAME_LIMIT
var editor_grid := true
var grid_opacity := 1.0
var zoom_sensitivity := 1.0
var snap_objects := true
var highlight_cell := true
const EDITOR_KEYS := ["editor_grid", "grid_opacity", "zoom_sensitivity", "snap_objects", "highlight_cell"]
var fullscreen := EditorVisualsSettings.DEFAULT_FULLSCREEN

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(storage_path) == OK:
		volume = clampf(float(config.get_value("preferences", "volume", volume)), 0, 1)
		show_fps = bool(config.get_value("preferences", "show_fps", show_fps))
		screen_shake = bool(config.get_value("preferences", "screen_shake", screen_shake))
		vsync = bool(config.get_value("preferences", "vsync", vsync))
		frame_limit = int(config.get_value("preferences", "frame_limit", frame_limit))
		for key in EDITOR_KEYS:
			var value: Variant = config.get_value("editor", key, get(key))
			if get(key) is bool: set(key, bool(value))
			elif value is float or value is int: set(key, clampf(float(value), 0.1 if key == "grid_opacity" else 0.5, 1.0 if key == "grid_opacity" else 2.0))
	# Start in the configured default mode each launch, even after a windowed session.
	fullscreen = EditorVisualsSettings.DEFAULT_FULLSCREEN
	if frame_limit not in EditorVisualsSettings.FRAME_LIMIT_OPTIONS: frame_limit = EditorVisualsSettings.DEFAULT_FRAME_LIMIT
	apply()

func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0)
	Engine.max_fps = frame_limit
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> void:
	var config := ConfigFile.new()
	for key in ["volume", "show_fps", "screen_shake", "vsync", "frame_limit"]:
		config.set_value("preferences", key, get(key))
	for key in EDITOR_KEYS: config.set_value("editor", key, get(key))
	config.save(storage_path)
