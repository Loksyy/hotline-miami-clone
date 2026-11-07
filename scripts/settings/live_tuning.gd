extends RefCounted
## Runtime overrides; source defaults remain in game_settings.gd.
const S = preload("res://scripts/settings/game_settings.gd")
const Importer = preload("res://scripts/maps/layout_importer.gd")
static var source: Script = S
static var defaults: Dictionary = {}
static var storage_path := "user://developer_tuning.cfg"

static func initialize() -> void:
	if not defaults.is_empty(): return
	for key in S.SETTING_NAMES:
		var value: Variant = source.get(key)
		defaults[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	var config := ConfigFile.new()
	if config.load(storage_path) == OK:
		for key in config.get_section_keys("tuning") if config.has_section("tuning") else []:
			change(key, config.get_value("tuning", key))

static func change(key: String, value: Variant) -> bool:
	if not defaults.has(key) or key in S.LOCKED_SETTINGS: return false
	if typeof(value) != typeof(defaults[key]): return false
	if value is float or value is int:
		if not is_finite(float(value)): return false
		if key not in ["SOUND_VOLUME_DB", "MELEE_ARC_DOT", "ENEMY_VISION_DOT", "ENEMY_START_ANGLE_DEGREES"] and value < 0: return false
		if (key.ends_with("TIME") or key.ends_with("INTERVAL") or key.ends_with("SCALE") or key.ends_with("THICKNESS") or key.ends_with("ZOOM") or key.ends_with("STEP")) and value <= 0: return false
	if key in ["MAX_AUDIO_VOICES", "DEFAULT_LAYOUT_FRAMES", "MAGAZINE_SIZE", "PLAYER_HEALTH", "ENEMY_HEALTH"] and value < 1: return false
	if key == "SHIFT_LOOK_TRANSITION_SPEED" and value <= 0: return false
	if key == "START_WEAPON" and value not in ["PISTOL", "BAT", "FISTS"]: return false
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
	if key == "PROP_SCALE_OVERRIDES":
		for entry in value.values():
			if not (entry is int or entry is float) or entry <= 0 or entry > 8: return false
	source.set(key, value)
	Importer.layout_cache.clear()
	return true

static func save() -> Error:
	var config := ConfigFile.new()
	for key in S.SETTING_NAMES:
		if key not in S.LOCKED_SETTINGS: config.set_value("tuning", key, source.get(key))
	return config.save(storage_path)

static func reset() -> void:
	for key in defaults:
		if key not in S.LOCKED_SETTINGS: source.set(key, defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key])
	Importer.layout_cache.clear()
