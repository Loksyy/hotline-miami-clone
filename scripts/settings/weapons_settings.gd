extends RefCounted
## Gun ammunition/damage/rates, melee, throwing, dropped weapons and Molotov.
## Edit defaults here; restart to reload source edits, or use Developer Lab live.
## Saved Developer Lab overrides take priority. Units: seconds and world pixels.


# PISTOL / RELOAD
static var MAGAZINE_SIZE := 8
static var START_RESERVE_AMMO := 24 # Legacy setting; reserves now use magazine count.
static var START_RESERVE_MAGAZINES := 3
static var FIRE_INTERVAL := 0.22 # Lower means faster firing.
static var RELOAD_TIME := 1.1
static var SHOT_DAMAGE := 1
static var SHOT_RANGE := 850.0
static var EMPTY_TRIGGER_INTERVAL := 0.3
static var GUNSHOT_HEARING_RANGE := 380.0
static var DROPPED_PISTOL_AMMO := 6

# MELEE / THROWN WEAPONS
static var MELEE_INTERVAL := 0.3
# Four-hit unarmed combo: fast swings, heavy hook, uppercut recovery.
static var PUNCH_COMBO_WINDOW := 1.2
static var PUNCH_JAB_INTERVAL := 0.22
static var PUNCH_HOOK_INTERVAL := 0.28
static var PUNCH_UPPERCUT_INTERVAL := 0.4
static var PUNCH_KNOCKBACK := 5.0
static var UPPERCUT_KNOCKBACK := 18.0
static var PUNCH_RANGE := 44.0
static var BAT_RANGE := 62.0
static var MELEE_ARC_DOT := 0.25 # -1 hits all directions; 1 requires exact aim.
static var BAT_DAMAGE := 1
static var FINISHER_DAMAGE := 1
static var STUN_DURATION := 2.5
static var THROW_SPEED := 650.0
static var THROW_LIFETIME := 0.65
static var THROW_HIT_RADIUS := 14.0

# FEEDBACK / ACCESSIBILITY
static var MELEE_FLASH_TIME := 0.16

# TEXTURES / ANIMATION (from HLM1 Files)
static var ATTACK_ANIMATION_TIME := 0.18
static var WEAPON_SPRITE_SCALE := 0.75

# EFFECT SIZES / TIMING
static var THROW_SPIN_SPEED := 20.0 # Radians per second; visual only.
static var PICKUP_GLOW_RADIUS := 12.0

# Optional per-weapon gun stats: magazine, damage, range, fire interval, reload, pellets, spread.
static var WEAPON_STAT_OVERRIDES := {
	"DOUBLE_BARREL": [2, 1, 380.0, 0.28, 1.5, 8, 30.0],
	"SILENCER": [12, 1, 600.0, 0.18, 1.1, 1, 0.0],
	"UZI": [24, 1, 550.0, 0.08, 1.4, 1, 10.0],
	"MP5": [30, 1, 750.0, 0.1, 1.5, 1, 4.0],
}
static var MELEE_WEAPON_INTERVALS := {
	"AXE": 0.45, "SLEDGEHAMMER": 0.55, "SWORD": 0.38,
	"MACHETE": 0.3, "POOL_CUE": 0.34, "CROWBAR": 0.34,
	"PAN": 0.36, "TROPHY": 0.4, "BRIEFCASE": 0.4,
	"CLEAVER": 0.28, "CLEAVER_DROP": 0.28, "HAMMER": 0.34,
}
static var THROW_WEAPON_DAMAGE := 1

# Player pickups: magazine, damage, range, firing interval, reload, pellets, spread degrees.
static var PLAYER_GUN_PROFILES := {
 "SHOTGUN": [6, 1, 420.0, 0.65, 1.6, 6, 24.0],
 "RIFLE": [20, 2, 1000.0, 0.12, 1.4, 1, 0.0],
 "MACHINE_GUN": [30, 1, 700.0, 0.09, 1.8, 1, 7.0],
}
static var DROP_BOB_HEIGHT := 2.0
static var DROP_BOB_SPEED := 3.5
static var DROP_SWAY_DEGREES := 5.0

# Dropped weapon motion (world pixels and seconds).
static var DROP_TOSS_SPEED := 85.0
static var DROP_FRICTION := 6.0
static var DROP_BOUNCE := 0.35
static var DROP_PICKUP_SCALE := 1.1
static var PLAYER_PIPE_RANGE := 58.0
static var PLAYER_KNIFE_RANGE := 35.0
static var PLAYER_KNIFE_INTERVAL := 0.22

# Molotov: radius in world pixels; durations in seconds.
static var MOLOTOV_THROW_SPEED := 420.0
static var MOLOTOV_FLIGHT_TIME := 0.6
static var MOLOTOV_FIRE_RADIUS := 60.0
static var MOLOTOV_BURN_TIME := 5.0
static var MOLOTOV_DAMAGE_INTERVAL := 0.4
static var MOLOTOV_DAMAGE := 1
static var MOLOTOV_HURTS_PLAYER := true
static var MOLOTOV_MAX_FIRES := 16

const SETTING_NAMES := [
	"START_RESERVE_MAGAZINES",
	"PUNCH_COMBO_WINDOW", "PUNCH_JAB_INTERVAL", "PUNCH_HOOK_INTERVAL", "PUNCH_UPPERCUT_INTERVAL", "PUNCH_KNOCKBACK", "UPPERCUT_KNOCKBACK",
	"MAGAZINE_SIZE",
	"START_RESERVE_AMMO",
	"FIRE_INTERVAL",
	"RELOAD_TIME",
	"SHOT_DAMAGE",
	"SHOT_RANGE",
	"EMPTY_TRIGGER_INTERVAL",
	"GUNSHOT_HEARING_RANGE",
	"DROPPED_PISTOL_AMMO",
	"MELEE_INTERVAL",
	"PUNCH_RANGE",
	"BAT_RANGE",
	"MELEE_ARC_DOT",
	"BAT_DAMAGE",
	"FINISHER_DAMAGE",
	"STUN_DURATION",
	"THROW_SPEED",
	"THROW_LIFETIME",
	"THROW_HIT_RADIUS",
	"MELEE_FLASH_TIME",
	"ATTACK_ANIMATION_TIME",
	"WEAPON_SPRITE_SCALE",
	"THROW_SPIN_SPEED",
	"PICKUP_GLOW_RADIUS",
	"WEAPON_STAT_OVERRIDES",
	"MELEE_WEAPON_INTERVALS",
	"THROW_WEAPON_DAMAGE",
	"PLAYER_GUN_PROFILES",
	"DROP_BOB_HEIGHT",
	"DROP_BOB_SPEED",
	"DROP_SWAY_DEGREES",
	"DROP_TOSS_SPEED",
	"DROP_FRICTION",
	"DROP_BOUNCE",
	"DROP_PICKUP_SCALE",
	"PLAYER_PIPE_RANGE",
	"PLAYER_KNIFE_RANGE",
	"PLAYER_KNIFE_INTERVAL",
	"MOLOTOV_THROW_SPEED",
	"MOLOTOV_FLIGHT_TIME",
	"MOLOTOV_FIRE_RADIUS",
	"MOLOTOV_BURN_TIME",
	"MOLOTOV_DAMAGE_INTERVAL",
	"MOLOTOV_DAMAGE",
	"MOLOTOV_HURTS_PLAYER",
	"MOLOTOV_MAX_FIRES",
]
