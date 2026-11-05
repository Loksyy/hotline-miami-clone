extends RefCounted
## Player preferences, saved separately from developer tuning in game_settings.gd.
const SAVE_PATH := "user://preferences.cfg"
var storage_path := SAVE_PATH
var volume := 0.8
var show_fps := true
var screen_shake := true
var vsync := true
var frame_limit := 120
var fullscreen := true

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(storage_path) == OK:
		volume = clampf(float(config.get_value("preferences", "volume", volume)), 0, 1)
		show_fps = bool(config.get_value("preferences", "show_fps", show_fps))
		screen_shake = bool(config.get_value("preferences", "screen_shake", screen_shake))
		vsync = bool(config.get_value("preferences", "vsync", vsync))
		frame_limit = int(config.get_value("preferences", "frame_limit", frame_limit))
		fullscreen = bool(config.get_value("preferences", "fullscreen", fullscreen))
	if frame_limit not in [0, 60, 120, 144, 240]: frame_limit = 120
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
	for key in ["volume", "show_fps", "screen_shake", "vsync", "frame_limit", "fullscreen"]:
		config.set_value("preferences", key, get(key))
	config.save(storage_path)
