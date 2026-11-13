extends RefCounted
## Editor tools, artwork, effects, audio and display defaults.
## Edit defaults here; restart to reload source edits, or use Developer Lab live.
## Saved Developer Lab overrides take priority. Units: seconds and world pixels.


# EDITOR APPEARANCE
static var EDITOR_CANVAS_COLOR := Color("10222a")
static var EDITOR_GRID_COLOR := Color("26414b")
static var EDITOR_PANEL_COLOR := Color("35213e")
static var EDITOR_NEON_COLOR := Color("e4489c")

# FEEDBACK / ACCESSIBILITY
static var SOUND_ENABLED := true # M toggles sound during play.
static var SOUND_VOLUME_DB := -8.0
static var SCREEN_SHAKE_SCALE := 1.0 # Set 0 to disable.
static var SHOT_SHAKE := 3.0
static var HIT_SHAKE := 5.0
static var DEATH_SHAKE := 8.0
static var DOOR_SHAKE := 4.0
static var SHAKE_DECAY := 24.0
static var SHOT_TRACE_TIME := 0.09
static var GUN_RECOIL_PIXELS := 2.5
static var MUZZLE_FLASH_TIME := 0.055
static var IMPACT_FLASH_TIME := 0.14
static var BLOOD_ENABLED := true
static var HIT_PARTICLE_COUNT := 12
static var PARTICLE_MIN_SPEED := 40.0
static var PARTICLE_MAX_SPEED := 200.0
static var PARTICLE_MIN_LIFE := 0.15
static var PARTICLE_MAX_LIFE := 0.4

# EDITOR
static var UNDO_LIMIT := 100
static var MAX_ENEMIES := 200
static var MAX_MAP_FILE_BYTES := 1000000

# TEXTURES / ANIMATION (from HLM1 Files)
static var ACTOR_SPRITE_SCALE := 0.85
static var WALK_ANIMATION_FPS := 12.0
static var BLOOD_SPRITE_SCALE := 0.55
static var FLOOR_TEXTURE_SCALE := 1.5 # World pixels per source pixel; independent of grid size.
static var EDITOR_DEFAULT_ZOOM := 1.5
static var EDITOR_MIN_ZOOM := 0.65
static var EDITOR_MAX_ZOOM := 4.0
static var EDITOR_ZOOM_STEP := 1.15
static var EDITOR_GRID_VISIBLE := false

# ASSET WORKSHOP
static var MAX_MAP_OBJECTS := 2000
static var OBJECT_SNAP_SIZE := 7.0
static var OBJECT_ROTATION_STEP := 15.0
static var OBJECT_ANIMATION_FPS := 12.0
static var PLACEMENT_PREVIEW_COLOR := Color(0.45, 1.0, 0.55, 0.6)
static var PLACEMENT_OUTLINE_COLOR := Color(0.35, 1.0, 0.45, 0.95)
static var FLOOR_STAMP_SCALE_STEP := 0.25 # Mouse wheel size increment for tiles/layouts.
static var FLOOR_PLAN_DEFAULT_SCALE := 4.0 # Enlarge miniature map-section artwork.
static var FLOOR_PLAN_TARGET_SIZE := 448.0 # Keep already-large floor-plan images at native size.

# Native art proportions: couch 48px, bed 50x60px, table 50x30px.
static var PROP_SCALE_OVERRIDES := {
 "Furniture/sprSofaH48_strip2.png": 1.0,
 "Furniture/sprAndersTable.png": 1.0,
 "Furniture/sprAndersBed.png": 1.0,
 "Furniture/sprAndersDesk_strip6.png": 1.0,
 "Furniture/sprAndersDrawer.png": 0.4,
}

# Performance budgets (developer defaults; user preferences are separate).
static var MAX_AUDIO_VOICES := 8
static var EDITOR_UI_REFRESH_INTERVAL := 0.1
static var FPS_COUNTER_REFRESH_INTERVAL := 0.25

# EFFECT SIZES / TIMING
static var PARTICLE_DRAG := 9.75 # Exponential damping per second; independent of FPS.
static var BLOOD_MIN_OFFSET := 2.0
static var BLOOD_MAX_OFFSET := 22.0
static var BLOOD_MIN_SIZE := 2.0
static var BLOOD_MAX_SIZE := 7.0
static var EXIT_SPRITE_SCALE := 0.65
static var EXIT_ANIMATION_FPS := 6.0

# FIRST-RUN PREFERENCES (saved pause-menu choices override these).
static var DEFAULT_VOLUME := 0.8 # 0..1
static var DEFAULT_SHOW_FPS := true
static var DEFAULT_SCREEN_SHAKE := true
static var DEFAULT_VSYNC := true
static var DEFAULT_FULLSCREEN := true
static var DEFAULT_FRAME_LIMIT := 240
static var FRAME_LIMIT_OPTIONS := [60, 120, 144, 240, 0] # 0 = unlimited.

# Player pickups: magazine, damage, range, firing interval, reload, pellets, spread degrees.
static var MAX_BLOOD_STAINS := 400

const SETTING_NAMES := [
	"GUN_RECOIL_PIXELS", "MUZZLE_FLASH_TIME", "IMPACT_FLASH_TIME",
	"EDITOR_CANVAS_COLOR",
	"EDITOR_GRID_COLOR",
	"EDITOR_PANEL_COLOR",
	"EDITOR_NEON_COLOR",
	"SOUND_ENABLED",
	"SOUND_VOLUME_DB",
	"SCREEN_SHAKE_SCALE",
	"SHOT_SHAKE",
	"HIT_SHAKE",
	"DEATH_SHAKE",
	"DOOR_SHAKE",
	"SHAKE_DECAY",
	"SHOT_TRACE_TIME",
	"BLOOD_ENABLED",
	"HIT_PARTICLE_COUNT",
	"PARTICLE_MIN_SPEED",
	"PARTICLE_MAX_SPEED",
	"PARTICLE_MIN_LIFE",
	"PARTICLE_MAX_LIFE",
	"UNDO_LIMIT",
	"MAX_ENEMIES",
	"MAX_MAP_FILE_BYTES",
	"ACTOR_SPRITE_SCALE",
	"WALK_ANIMATION_FPS",
	"BLOOD_SPRITE_SCALE",
	"FLOOR_TEXTURE_SCALE",
	"EDITOR_DEFAULT_ZOOM",
	"EDITOR_MIN_ZOOM",
	"EDITOR_MAX_ZOOM",
	"EDITOR_ZOOM_STEP",
	"EDITOR_GRID_VISIBLE",
	"MAX_MAP_OBJECTS",
	"OBJECT_SNAP_SIZE",
	"OBJECT_ROTATION_STEP",
	"OBJECT_ANIMATION_FPS",
	"PLACEMENT_PREVIEW_COLOR",
	"PLACEMENT_OUTLINE_COLOR",
	"FLOOR_STAMP_SCALE_STEP",
	"FLOOR_PLAN_DEFAULT_SCALE",
	"FLOOR_PLAN_TARGET_SIZE",
	"PROP_SCALE_OVERRIDES",
	"MAX_AUDIO_VOICES",
	"EDITOR_UI_REFRESH_INTERVAL",
	"FPS_COUNTER_REFRESH_INTERVAL",
	"PARTICLE_DRAG",
	"BLOOD_MIN_OFFSET",
	"BLOOD_MAX_OFFSET",
	"BLOOD_MIN_SIZE",
	"BLOOD_MAX_SIZE",
	"EXIT_SPRITE_SCALE",
	"EXIT_ANIMATION_FPS",
	"DEFAULT_VOLUME",
	"DEFAULT_SHOW_FPS",
	"DEFAULT_SCREEN_SHAKE",
	"DEFAULT_VSYNC",
	"DEFAULT_FULLSCREEN",
	"DEFAULT_FRAME_LIMIT",
	"FRAME_LIMIT_OPTIONS",
	"MAX_BLOOD_STAINS",
]
