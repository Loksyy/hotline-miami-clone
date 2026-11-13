extends RefCounted
const EnemiesSettings = preload("res://scripts/settings/enemies_settings.gd")
static func identify(asset: String) -> String:
	var name := asset.to_lower()
	if "doublebarrel" in name: return "DOUBLE_BARREL"
	if "shotgun" in name: return "SHOTGUN"
	if "uzi" in name or "machinegun" in name: return "MACHINE_GUN"
	if "m16" in name or "rifle" in name: return "RIFLE"
	if "silencer" in name: return "SILENCER"
	if "gun" in name or "inspector" in name: return "PISTOL"
	if "knife" in name: return "KNIFE"
	if "pipe" in name: return "PIPE"
	if "nightstick" in name: return "NIGHTSTICK"
	if "club" in name: return "CLUB"
	for token in ["bat", "chain"]:
		if token in name: return "BAT"
	return "FISTS"

static func profile(kind: String) -> Dictionary:
	kind = preload("res://scripts/game/player_weapons.gd").family(kind)
	var data := {"ranged": false, "damage": EnemiesSettings.ENEMY_PUNCH_DAMAGE, "range": EnemiesSettings.ENEMY_PUNCH_RANGE, "interval": EnemiesSettings.ENEMY_PUNCH_INTERVAL, "pellets": 1, "spread": 0.0, "speed": EnemiesSettings.ENEMY_BULLET_SPEED}
	match kind:
		"MELEE", "BAT", "PIPE", "KNIFE":
			data.damage = EnemiesSettings.ENEMY_WEAPON_MELEE_DAMAGE
			data.range = EnemiesSettings.ENEMY_KNIFE_RANGE if kind == "KNIFE" else EnemiesSettings.ENEMY_WEAPON_MELEE_RANGE
			data.interval = EnemiesSettings.ENEMY_KNIFE_INTERVAL if kind == "KNIFE" else EnemiesSettings.ENEMY_WEAPON_MELEE_INTERVAL
		"PISTOL", "SHOTGUN", "RIFLE", "MACHINE_GUN":
			data.ranged = true
			data.damage = EnemiesSettings.ENEMY_BULLET_DAMAGE
			data.range = EnemiesSettings.ENEMY_BULLET_SPEED * EnemiesSettings.ENEMY_BULLET_LIFETIME
			data.interval = EnemiesSettings.ENEMY_FIRE_INTERVAL
			if kind == "SHOTGUN":
				data.merge({"damage": EnemiesSettings.ENEMY_SHOTGUN_DAMAGE, "range": EnemiesSettings.ENEMY_SHOTGUN_RANGE, "interval": EnemiesSettings.ENEMY_SHOTGUN_INTERVAL, "pellets": clampi(EnemiesSettings.ENEMY_SHOTGUN_PELLETS, 1, 32), "spread": EnemiesSettings.ENEMY_SHOTGUN_SPREAD_DEGREES}, true)
			elif kind == "RIFLE":
				data.merge({"damage": EnemiesSettings.ENEMY_RIFLE_DAMAGE, "range": EnemiesSettings.ENEMY_RIFLE_RANGE, "interval": EnemiesSettings.ENEMY_RIFLE_INTERVAL, "speed": EnemiesSettings.ENEMY_RIFLE_BULLET_SPEED}, true)
			elif kind == "MACHINE_GUN":
				data.merge({"damage": EnemiesSettings.ENEMY_MACHINE_GUN_DAMAGE, "range": EnemiesSettings.ENEMY_MACHINE_GUN_RANGE, "interval": EnemiesSettings.ENEMY_MACHINE_GUN_INTERVAL, "spread": EnemiesSettings.ENEMY_MACHINE_GUN_SPREAD_DEGREES}, true)
	return data
