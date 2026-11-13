extends SceneTree
const PlayerSettings = preload("res://scripts/settings/player_settings.gd")
const T = preload("res://scripts/settings/live_tuning.gd")
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok: failures += 1; push_error(text)
func _initialize() -> void:
	T.storage_path = "user://test_live_tuning.cfg"
	T.initialize()
	var speed := PlayerSettings.PLAYER_SPEED
	check(T.change("PLAYER_SPEED", speed + 50.0), "Accept live speed")
	check(PlayerSettings.PLAYER_SPEED == speed + 50.0, "Gameplay reads changed static speed")
	check(not T.change("RELOAD_TIME", -1.0), "Reject negative reload")
	check(not T.change("MAX_AUDIO_VOICES", 0), "Reject empty audio pool")
	check(not T.change("CELL_SIZE", 56), "Protect map format")
	check(T.save() == OK, "Save overrides")
	T.reset()
	check(PlayerSettings.PLAYER_SPEED == speed, "Reset source defaults")
	T.defaults.clear()
	T.initialize()
	check(PlayerSettings.PLAYER_SPEED == speed + 50.0, "Reload overrides")
	T.reset()
	DirAccess.remove_absolute(T.storage_path)
	print("Live tuning: %d failures" % failures)
	quit(1 if failures else 0)
