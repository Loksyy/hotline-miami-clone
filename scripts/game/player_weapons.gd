extends RefCounted
const WeaponsSettings = preload("res://scripts/settings/weapons_settings.gd")
## Each entry preserves its own source frame through placement, pickup and throwing.
const PICKUPS := ["RIFLE", "SHOTGUN", "PIPE", "CLUB", "BAT", "KNIFE", "DOUBLE_BARREL", "SILENCER", "SWORD", "UZI", "PISTOL", "MACHINE_GUN", "MP5", "POOL_CUE", "AXE", "NIGHTSTICK", "CROWBAR", "MACHETE", "SLEDGEHAMMER", "TROPHY", "DRILL", "PAN", "SCISSORS", "BOTTLE", "CAN", "BRICK", "SHURIKEN", "HAMMER", "DART", "BIKER_KNIFE", "BRIEFCASE", "CLEAVER", "CLEAVER_DROP", "RED_BAR", "MOLOTOV"]
static func is_gun(kind: String) -> bool:
	return family(kind) in ["PISTOL", "SHOTGUN", "RIFLE", "MACHINE_GUN"]
static func stats(kind: String) -> Array:
	if WeaponsSettings.WEAPON_STAT_OVERRIDES.has(kind): return WeaponsSettings.WEAPON_STAT_OVERRIDES[kind]
	if WeaponsSettings.WEAPON_STAT_OVERRIDES.has(kind.trim_prefix("TEST_")): return WeaponsSettings.WEAPON_STAT_OVERRIDES[kind.trim_prefix("TEST_")]
	return WeaponsSettings.PLAYER_GUN_PROFILES.get(family(kind), [WeaponsSettings.MAGAZINE_SIZE, WeaponsSettings.SHOT_DAMAGE, WeaponsSettings.SHOT_RANGE, WeaponsSettings.FIRE_INTERVAL, WeaponsSettings.RELOAD_TIME, 1, 0.0])

const SOURCES := {
	"RIFLE": ["Weapons/sprWeapons_strip35.png", 0],
	"SHOTGUN": ["Weapons/sprWeapons_strip35.png", 1],
	"PIPE": ["Weapons/sprWeapons_strip35.png", 2],
	"CLUB": ["Weapons/sprWeapons_strip35.png", 3],
	"BAT": ["Weapons/sprWeapons_strip35.png", 4],
	"KNIFE": ["Weapons/sprWeapons_strip35.png", 5],
	"DOUBLE_BARREL": ["Weapons/sprWeapons_strip35.png", 6],
	"SILENCER": ["Weapons/sprWeapons_strip35.png", 7],
	"SWORD": ["Weapons/sprWeapons_strip35.png", 8],
	"UZI": ["Weapons/sprWeapons_strip35.png", 9],
	"PISTOL": ["Weapons/sprWeapons_strip35.png", 10],
	"MACHINE_GUN": ["Weapons/sprWeapons_strip35.png", 11],
	"MP5": ["Weapons/sprWeapons_strip35.png", 12],
	"POOL_CUE": ["Weapons/sprWeapons_strip35.png", 13],
	"BROKEN_CUE": ["Weapons/sprWeapons_strip35.png", 14],
	"AXE": ["Weapons/sprWeapons_strip35.png", 15],
	"NIGHTSTICK": ["Weapons/sprWeapons_strip35.png", 16],
	"CROWBAR": ["Weapons/sprWeapons_strip35.png", 17],
	"MACHETE": ["Weapons/sprWeapons_strip35.png", 18],
	"SLEDGEHAMMER": ["Weapons/sprWeapons_strip35.png", 19],
	"TROPHY": ["Weapons/sprWeapons_strip35.png", 20],
	"DRILL": ["Weapons/sprWeapons_strip35.png", 21],
	"PAN": ["Weapons/sprWeapons_strip35.png", 22],
	"BLUE_KEY": ["Weapons/sprWeapons_strip35.png", 23],
	"KEY": ["Weapons/sprWeapons_strip35.png", 24],
	"SCORPION": ["Weapons/sprWeapons_strip35.png", 25],
	"GREEN_GUN": ["Weapons/sprWeapons_strip35.png", 26],
	"SCISSORS": ["Weapons/sprThrowWeapons_strip8.png", 0],
	"BOTTLE": ["Weapons/sprThrowWeapons_strip8.png", 1],
	"CAN": ["Weapons/sprThrowWeapons_strip8.png", 2],
	"BRICK": ["Weapons/sprThrowWeapons_strip8.png", 3],
	"SHURIKEN": ["Weapons/sprThrowWeapons_strip8.png", 4],
	"HAMMER": ["Weapons/sprThrowWeapons_strip8.png", 5],
	"DART": ["Weapons/sprThrowWeapons_strip8.png", 6],
	"NINJA_KNIFE": ["Weapons/sprThrowWeapons_strip8.png", 7],
	"BODYGUARD_SWORD": ["Weapons/sprBGSword.png", 0],
	"BIKER_KNIFE": ["Weapons/sprBikerKnife.png", 0],
	"BOSS_PISTOL": ["Weapons/sprBossgun.png", 0],
	"BRIEFCASE": ["Weapons/sprBriefcase.png", 0],
	"CLEAVER": ["Weapons/sprCleaver.png", 0],
	"CLEAVER_DROP": ["Weapons/sprCleaverDrop.png", 0],
	"RED_BAR": ["Weapons/sprite1413.png", 0],
	"NINJA_BLADE": ["Weapons/sprNinjaKnife.png", 0],
	"GOLD_TROPHY": ["Weapons/sprTrophy.png", 0],
	"MOLOTOV": ["Weapons/sprMolotov_strip4.png", 0],
	"TEST_RIFLE": ["Weapons/sprWeaponsTest_strip12.png", 1],
	"TEST_UZI": ["Weapons/sprWeaponsTest_strip12.png", 2],
	"TEST_SHOTGUN": ["Weapons/sprWeaponsTest_strip12.png", 3],
	"TEST_SWORD": ["Weapons/sprWeaponsTest_strip12.png", 4],
	"TEST_PIPE": ["Weapons/sprWeaponsTest_strip12.png", 5],
	"TEST_CLUB": ["Weapons/sprWeaponsTest_strip12.png", 6],
	"TEST_BAT": ["Weapons/sprWeaponsTest_strip12.png", 7],
	"TEST_KNIFE": ["Weapons/sprWeaponsTest_strip12.png", 8],
	"TEST_BOTTLE": ["Weapons/sprWeaponsTest_strip12.png", 9],
	"TEST_CAN": ["Weapons/sprWeaponsTest_strip12.png", 10],
	"TEST_BRICK": ["Weapons/sprWeaponsTest_strip12.png", 11],
}
static func drop_frame(kind: String) -> int:
	return SOURCES.get(kind, SOURCES.BAT)[1]

const ANIMATIONS := {
	"AXE": "Axe",
	"SWORD": "Sword",
	"POOL_CUE": "Pool",
	"CROWBAR": "Crowbar",
	"MACHETE": "Machete",
	"SLEDGEHAMMER": "SledgeHammer",
	"TROPHY": "Trophy",
	"DRILL": "Drill",
	"PAN": "Pan",
	"BRIEFCASE": "Bag",
	"UZI": "Uzi",
	"MP5": "MP5",
}
static func held_sprite(kind: String, attacking: bool = false) -> String:
	if custom_held(kind) and is_melee(kind): return "player_fists"
	if ANIMATIONS.has(kind): return "weapon_" + kind + ("_attack" if attacking else "_walk")
	var keys := {
		"SILENCER": ["player_silencer", "player_silencer_attack"],
		"DOUBLE_BARREL": ["player_double_barrel", "player_double_barrel_attack"],
		"CLUB": ["player_club", "player_club_attack"],
		"NIGHTSTICK": ["player_nightstick", "player_nightstick_attack"],
		"MOLOTOV": ["player_fists", "player_punch"],
		"FISTS": ["player_fists", "player_punch"],
		"BAT": ["player_bat", "player_swing"],
		"MELEE": ["player_bat", "player_swing"],
		"PIPE": ["player_pipe", "player_pipe_attack"],
		"KNIFE": ["player_knife", "player_knife_attack"],
		"SHOTGUN": ["player_shotgun", "player_shotgun_attack"],
		"RIFLE": ["player_rifle", "player_rifle_attack"],
		"MACHINE_GUN": ["player_machine_gun", "player_machine_gun_attack"],
	}
	return keys.get(kind, ["player_fists", "player_punch"] if custom_held(kind) else ["player_gun", "player_shoot"])[1 if attacking else 0]

static func family(kind: String) -> String:
	kind = kind.trim_prefix("TEST_")
	if kind in ["SILENCER", "BOSS_PISTOL"]: return "PISTOL"
	if kind == "DOUBLE_BARREL": return "SHOTGUN"
	if kind in ["UZI", "MP5", "SCORPION", "GREEN_GUN"]: return "MACHINE_GUN"
	if kind in ["SCISSORS", "BOTTLE", "CAN", "BRICK", "SHURIKEN", "DART", "NINJA_KNIFE", "NINJA_BLADE"]: return "THROW"
	if kind in ["KNIFE", "BIKER_KNIFE", "CLEAVER", "CLEAVER_DROP"]: return "KNIFE"
	if kind in ["FISTS", "MOLOTOV", "PISTOL", "RIFLE", "SHOTGUN", "MACHINE_GUN", "PIPE"]: return kind
	return "BAT"

static func pickup_asset(kind: String) -> String:
	return SOURCES.get(kind, SOURCES.BAT)[0]

static func custom_held(kind: String) -> bool:
	return not ANIMATIONS.has(kind) and kind not in ["FISTS", "MELEE", "PISTOL", "SILENCER", "SHOTGUN", "DOUBLE_BARREL", "RIFLE", "MACHINE_GUN", "BAT", "PIPE", "KNIFE", "CLUB", "NIGHTSTICK"]

static func is_melee(kind: String) -> bool:
	return family(kind) in ["BAT", "PIPE", "KNIFE"]

# Larger versions are used only for thumbnails, keeping world sizes consistent.
const BIG_FRAMES := {"PIPE": 0, "CLUB": 1, "BAT": 2, "KNIFE": 3, "RIFLE": 4, "SHOTGUN": 5, "DOUBLE_BARREL": 6, "SWORD": 7, "BOTTLE": 8, "PISTOL": 9, "MACHETE": 10, "CAN": 11, "MACHINE_GUN": 12, "CROWBAR": 13, "BRICK": 14, "UZI": 15, "SLEDGEHAMMER": 16, "SHURIKEN": 17, "DART": 18, "MP5": 19, "AXE": 20, "SCISSORS": 21, "SILENCER": 22}

static func animation_duration(kind: String, melee_attack: bool = false) -> float:
	if melee_attack or is_melee(kind):
		return WeaponsSettings.MELEE_WEAPON_INTERVALS.get(kind, WeaponsSettings.PLAYER_KNIFE_INTERVAL if family(kind) == "KNIFE" else WeaponsSettings.MELEE_INTERVAL)
	return minf(WeaponsSettings.ATTACK_ANIMATION_TIME, float(stats(kind)[3]))
