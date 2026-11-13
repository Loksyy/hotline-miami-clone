extends SceneTree
const S = preload("res://scripts/settings/game_settings.gd")
func _initialize() -> void:
	var snapshot := ConfigFile.new()
	if "--capture" in OS.get_cmdline_user_args():
		for key in S.setting_names(): snapshot.set_value("defaults", key, S.read_value(key))
		snapshot.save("res://.godot/settings-before.cfg")
		quit()
		return
	var failures := 0
	if snapshot.load("res://.godot/settings-before.cfg") == OK:
		for key in S.setting_names():
			var actual: Variant = S.read_value(key)
			var expected: Variant = snapshot.get_value("defaults", key)
			var equal: bool = actual.is_equal_approx(expected) if actual is Color else actual == expected
			if not equal:
				push_error("Default changed: " + key)
				failures += 1
	for group in S.GROUPS:
		for key in group.SETTING_NAMES:
			if S.read_value(key) != group.get(key):
				push_error("Forwarding mismatch: " + key)
				failures += 1
			if key in S.LOCKED_SETTINGS: continue
			var old: Variant = group.get(key)
			if old is float or old is int:
				S.write_value(key, old + 1)
				if group.get(key) != old + 1: failures += 1
				group.set(key, old)
				if S.read_value(key) != old: failures += 1
	print("Settings preservation: %d settings, %d failures" % [S.setting_names().size(), failures])
	quit(1 if failures else 0)
