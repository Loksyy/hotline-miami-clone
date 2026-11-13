extends RefCounted
## Developer Lab registry. Gameplay imports grouped settings directly.
const GROUPS := [
	preload("res://scripts/settings/player_settings.gd"),
	preload("res://scripts/settings/weapons_settings.gd"),
	preload("res://scripts/settings/enemies_settings.gd"),
	preload("res://scripts/settings/world_settings.gd"),
	preload("res://scripts/settings/editor_visuals_settings.gd"),
]
const LOCKED_SETTINGS := ["MAP_WIDTH_CELLS", "MAP_HEIGHT_CELLS", "CELL_SIZE"]
static var owners: Dictionary = {}

static func setting_names() -> Array:
	if owners.is_empty():
		for group in GROUPS:
			for key in group.SETTING_NAMES:
				assert(not owners.has(key), "Duplicate setting: " + key)
				owners[key] = group
	return owners.keys()

static func read_value(key: String) -> Variant:
	setting_names()
	return owners[key].get(key) if owners.has(key) else null

static func write_value(key: String, value: Variant) -> bool:
	setting_names()
	if not owners.has(key) or key in LOCKED_SETTINGS: return false
	owners[key].set(key, value)
	return true
