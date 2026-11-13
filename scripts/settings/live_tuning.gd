extends RefCounted
## Runtime overrides; source defaults live in the grouped *_settings.gd files.
const S = preload("res://scripts/settings/game_settings.gd")
const Importer = preload("res://scripts/maps/layout_importer.gd")
static var defaults: Dictionary = {}
static var saved_values: Dictionary = {}
static var storage_path := "user://developer_tuning.cfg"

static func initialize() -> void:
	if not defaults.is_empty(): return
	for key in S.setting_names():
		var value: Variant = S.read_value(key)
		defaults[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	var config := ConfigFile.new()
	if config.load(storage_path) == OK:
		for key in config.get_section_keys("tuning") if config.has_section("tuning") else []:
			change(key, config.get_value("tuning", key))
	remember_saved()

static func remember_saved() -> void:
	saved_values.clear()
	for key in S.setting_names():
		var value: Variant = S.read_value(key)
		saved_values[key] = value.duplicate(true) if value is Array or value is Dictionary else value

static func has_unsaved_changes() -> bool:
	for key in saved_values:
		if S.read_value(key) != saved_values[key]: return true
	return false

static func change(key: String, value: Variant) -> bool:
	if not defaults.has(key) or key in S.LOCKED_SETTINGS: return false
	if typeof(value) != typeof(defaults[key]): return false
	if value is float or value is int:
		if not is_finite(float(value)): return false
		if key not in ["SOUND_VOLUME_DB", "MELEE_ARC_DOT", "ENEMY_VISION_DOT", "ENEMY_START_ANGLE_DEGREES"] and value < 0: return false
		if (key.ends_with("TIME") or key.ends_with("INTERVAL") or key.ends_with("SCALE") or key.ends_with("THICKNESS") or key.ends_with("ZOOM") or key.ends_with("STEP")) and value <= 0: return false
	if key in ["MAX_AUDIO_VOICES", "DEFAULT_LAYOUT_FRAMES", "MAGAZINE_SIZE", "PLAYER_HEALTH", "ENEMY_HEALTH"] and value < 1: return false
	if key == "SHIFT_LOOK_TRANSITION_SPEED" and value <= 0: return false
	if key == "START_WEAPON" and value not in preload("res://scripts/game/player_weapons.gd").PICKUPS + ["FISTS"]: return false
	if key == "ENEMY_WEAPON_PATTERN":
		for entry in value:
			if not entry is bool: return false
	if key == "LAYOUT_ENEMY_POSITIONS":
		for entry in value:
			if not (entry is float or entry is int) or entry < 0 or entry > 1: return false
	if key == "FRAME_LIMIT_OPTIONS":
		if value.is_empty(): return false
		for entry in value:
			if not entry is int or entry < 0: return false
	if key in ["PLAYER_GUN_PROFILES", "WEAPON_STAT_OVERRIDES"]:
		for kind in value:
			if key == "PLAYER_GUN_PROFILES" and kind not in ["SHOTGUN", "RIFLE", "MACHINE_GUN"]: return false
			if key == "WEAPON_STAT_OVERRIDES" and (kind not in preload("res://scripts/game/player_weapons.gd").PICKUPS or not preload("res://scripts/game/player_weapons.gd").is_gun(kind)): return false
			var stats: Variant = value[kind]
			if not stats is Array or stats.size() != 7: return false
			for n in stats:
				if not (n is int or n is float) or not is_finite(float(n)) or n < 0: return false
			if stats[0] < 1 or stats[0] != int(stats[0]) or stats[1] != int(stats[1]) or stats[2] <= 0 or stats[3] <= 0 or stats[4] <= 0 or stats[5] < 1 or stats[5] > 32 or stats[5] != int(stats[5]): return false
	if key == "MELEE_WEAPON_INTERVALS":
		for kind in value:
			if kind not in preload("res://scripts/game/player_weapons.gd").PICKUPS: return false
			if not (value[kind] is float or value[kind] is int) or not is_finite(float(value[kind])) or value[kind] <= 0: return false
	if key == "PROP_SCALE_OVERRIDES":
		for entry in value.values():
			if not (entry is int or entry is float) or entry <= 0 or entry > 8: return false
	S.write_value(key, value)
	Importer.layout_cache.clear()
	return true

static func save() -> Error:
	var config := ConfigFile.new()
	for key in S.setting_names():
		if key not in S.LOCKED_SETTINGS: config.set_value("tuning", key, S.read_value(key))
	var error := config.save(storage_path)
	if error == OK: remember_saved()
	return error

static func reset() -> void:
	for key in defaults:
		if key not in S.LOCKED_SETTINGS: S.write_value(key, defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key])
	Importer.layout_cache.clear()
