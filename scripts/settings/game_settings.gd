extends RefCounted
## EDIT THIS FILE TO TUNE THE GAME, THEN STOP AND RUN AGAIN (F5).
## Times are seconds, distances are pixels, speeds are pixels/second.
## Keep durations/speeds positive and ammunition counts nonnegative.

# QUICK INDEX: Player; Weapons; Enemies; World/layouts; Feedback; Editor; Defaults.
# Search a constant name (Ctrl+F). Keep source-art frame counts in game_art.gd.

# PLAYER
static var PLAYER_SPEED := 280.0
static var PLAYER_COLLISION_RADIUS := 8.0
static var PLAYER_HIT_RADIUS := 10.0
static var PLAYER_HEALTH := 1
static var START_WEAPON := "PISTOL" # PISTOL, BAT, or FISTS
static var PICKUP_RANGE := 42.0

# PISTOL / RELOAD
static var MAGAZINE_SIZE := 8
static var START_RESERVE_AMMO := 24
static var FIRE_INTERVAL := 0.18 # Lower means faster firing.
static var RELOAD_TIME := 1.1
static var SHOT_DAMAGE := 1
static var SHOT_RANGE := 850.0
static var EMPTY_TRIGGER_INTERVAL := 0.3
static var GUNSHOT_HEARING_RANGE := 380.0
static var DROPPED_PISTOL_AMMO := 6

# MELEE / THROWN WEAPONS
static var MELEE_INTERVAL := 0.3
static var PUNCH_RANGE := 44.0
static var BAT_RANGE := 62.0
static var MELEE_ARC_DOT := 0.25 # -1 hits all directions; 1 requires exact aim.
static var BAT_DAMAGE := 1
static var FINISHER_DAMAGE := 1
static var STUN_DURATION := 2.5
static var THROW_SPEED := 650.0
static var THROW_LIFETIME := 0.65
static var THROW_HIT_RADIUS := 14.0
static var DOOR_STUN_RANGE := 48.0
static var DOOR_INTERACT_DISTANCE := 45.0
static var WALL_THICKNESS := 8.0 # Native wall artwork thickness, independent of 28px cells.

# EDITOR APPEARANCE
static var EDITOR_CANVAS_COLOR := Color("10222a")
static var EDITOR_GRID_COLOR := Color("26414b")
static var EDITOR_PANEL_COLOR := Color("35213e")
static var EDITOR_NEON_COLOR := Color("e4489c")

# ENEMIES
static var ENEMY_HEALTH := 1
static var ENEMY_HIT_RADIUS := 12.0
static var ENEMY_GUN_SPEED := 115.0
static var ENEMY_MELEE_SPEED := 165.0
static var ENEMY_SIGHT_RANGE := 350.0
static var ENEMY_CLOSE_DETECTION_RANGE := 75.0
static var ENEMY_VISION_DOT := 0.2 # Lower gives a wider field of view.
static var ENEMY_REACTION_TIME := 0.7
static var ENEMY_FIRE_INTERVAL := 0.8
static var ENEMY_BULLET_SPEED := 550.0
static var ENEMY_BULLET_LIFETIME := 2.0
static var ENEMY_DAMAGE := 1
static var ENEMY_SHOOT_DISTANCE := 150.0
static var ENEMY_MELEE_STOP_DISTANCE := 18.0
static var ENEMY_MELEE_RANGE := 23.0
static var ENEMY_MELEE_INTERVAL := 0.6
static var PATH_REFRESH_TIME := 0.3
static var PATH_ARRIVAL_DISTANCE := 4.0

# SCORE / ROUND
static var KILL_SCORE := 1000
static var COMBO_WINDOW := 3.0
static var EXIT_RADIUS := 22.0

# FEEDBACK / ACCESSIBILITY
static var SOUND_ENABLED := true # M toggles sound during play.
static var SOUND_VOLUME_DB := -8.0
static var SCREEN_SHAKE_SCALE := 1.0 # Set 0 to disable.
static var SHOT_SHAKE := 3.0
static var HIT_SHAKE := 5.0
static var DEATH_SHAKE := 8.0
static var DOOR_SHAKE := 4.0
static var SHAKE_DECAY := 24.0
static var MELEE_FLASH_TIME := 0.16
static var SHOT_TRACE_TIME := 0.09
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
static var ATTACK_ANIMATION_TIME := 0.18
static var WEAPON_SPRITE_SCALE := 0.75
static var BLOOD_SPRITE_SCALE := 0.55
static var FLOOR_TEXTURE_SCALE := 1.5 # World pixels per source pixel; independent of grid size.
static var EDITOR_DEFAULT_ZOOM := 1.5
static var EDITOR_MIN_ZOOM := 0.65
static var EDITOR_MAX_ZOOM := 4.0
static var EDITOR_ZOOM_STEP := 1.15
static var EDITOR_GRID_VISIBLE := false
static var PLAY_CAMERA_ZOOM := 3
static var PLAY_CAMERA_FOLLOW_SPEED := 10.0
static var SHIFT_LOOK_ENABLED := true # Hold Shift in playtest to see more around you.
static var SHIFT_LOOK_DISTANCE := 160.0 # Maximum camera offset in world pixels toward the cursor.
static var SHIFT_LOOK_TRANSITION_SPEED := 8.0 # Higher = faster look-ahead and return.

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
static var DOOR_LEAF_THICKNESS := 4.0

# Performance budgets (developer defaults; user preferences are separate).
static var MAX_AUDIO_VOICES := 8
static var EDITOR_UI_REFRESH_INTERVAL := 0.1
static var FPS_COUNTER_REFRESH_INTERVAL := 0.25

# WORLD / LAYOUT GENERATION
# Changing canvas dimensions changes save structure. Keep 96x66 for existing saves.
const MAP_WIDTH_CELLS := 96
const MAP_HEIGHT_CELLS := 66
const CELL_SIZE := 28 # Pixels. Existing prop positions are stored in pixels.
static var LAYOUT_MAX_WIDTH := 26.0 # Generated building size in cells, not canvas size.
static var LAYOUT_MAX_HEIGHT := 18.0
static var LAYOUT_ENEMY_POSITIONS := [0.35, 0.65] # Fractions along reachable floor; [] = no enemies.
static var LAYOUT_MAX_WINDOWS := 3
static var LAYOUT_WINDOW_SPACING := 5 # Cells; at least 1.
static var DEFAULT_LAYOUT_ASSET := "Floor Plans/sprApartment1_strip16.png"
static var DEFAULT_LAYOUT_FRAME := 8 # Zero-based frame index.
static var DEFAULT_LAYOUT_FRAMES := 16 # Source sprite-sheet metadata; match the actual image.

# ENEMY COMPOSITION / PHYSICS
static var ENEMY_WEAPON_PATTERN := [true, false, true] # Repeating gun/melee/gun pattern; true = pistol.
static var ENEMY_START_ANGLE_DEGREES := 180.0
static var ENEMY_COLLISION_RADIUS := 8.0 # Separate from the player's body and bullet-hit radius.
static var ENEMY_BULLET_DAMAGE := ENEMY_DAMAGE
static var ENEMY_MELEE_DAMAGE := ENEMY_DAMAGE
static var ENEMIES_DROP_WEAPONS := true
static var DOOR_PUSH_LOOKAHEAD := 12.0
static var DOOR_CLOSE_CLEARANCE := 0.5

# COLLISION ACCURACY (smaller steps cost more CPU; keep below wall thickness).
static var ACTOR_COLLISION_STEP := 2.0
static var PROJECTILE_COLLISION_STEP := 4.0
static var RAYCAST_STEP := 3.0
static var VISIBILITY_TOLERANCE := 4.0

# EFFECT SIZES / TIMING
static var PARTICLE_DRAG := 9.75 # Exponential damping per second; independent of FPS.
static var BLOOD_MIN_OFFSET := 2.0
static var BLOOD_MAX_OFFSET := 22.0
static var BLOOD_MIN_SIZE := 2.0
static var BLOOD_MAX_SIZE := 7.0
static var EXIT_SPRITE_SCALE := 0.65
static var EXIT_ANIMATION_FPS := 6.0
static var THROW_SPIN_SPEED := 20.0 # Radians per second; visual only.
static var PICKUP_GLOW_RADIUS := 12.0

# FIRST-RUN PREFERENCES (saved pause-menu choices override these).
static var DEFAULT_VOLUME := 0.8 # 0..1
static var DEFAULT_SHOW_FPS := true
static var DEFAULT_SCREEN_SHAKE := true
static var DEFAULT_VSYNC := true
static var DEFAULT_FULLSCREEN := true
static var DEFAULT_FRAME_LIMIT := 120
static var FRAME_LIMIT_OPTIONS := [60, 120, 144, 240, 0] # 0 = unlimited.

const SETTING_NAMES := ["SHIFT_LOOK_ENABLED", "SHIFT_LOOK_DISTANCE", "SHIFT_LOOK_TRANSITION_SPEED", "PLAYER_SPEED", "PLAYER_COLLISION_RADIUS", "PLAYER_HIT_RADIUS", "PLAYER_HEALTH", "START_WEAPON", "PICKUP_RANGE", "MAGAZINE_SIZE", "START_RESERVE_AMMO", "FIRE_INTERVAL", "RELOAD_TIME", "SHOT_DAMAGE", "SHOT_RANGE", "EMPTY_TRIGGER_INTERVAL", "GUNSHOT_HEARING_RANGE", "DROPPED_PISTOL_AMMO", "MELEE_INTERVAL", "PUNCH_RANGE", "BAT_RANGE", "MELEE_ARC_DOT", "BAT_DAMAGE", "FINISHER_DAMAGE", "STUN_DURATION", "THROW_SPEED", "THROW_LIFETIME", "THROW_HIT_RADIUS", "DOOR_STUN_RANGE", "DOOR_INTERACT_DISTANCE", "WALL_THICKNESS", "EDITOR_CANVAS_COLOR", "EDITOR_GRID_COLOR", "EDITOR_PANEL_COLOR", "EDITOR_NEON_COLOR", "ENEMY_HEALTH", "ENEMY_HIT_RADIUS", "ENEMY_GUN_SPEED", "ENEMY_MELEE_SPEED", "ENEMY_SIGHT_RANGE", "ENEMY_CLOSE_DETECTION_RANGE", "ENEMY_VISION_DOT", "ENEMY_REACTION_TIME", "ENEMY_FIRE_INTERVAL", "ENEMY_BULLET_SPEED", "ENEMY_BULLET_LIFETIME", "ENEMY_DAMAGE", "ENEMY_SHOOT_DISTANCE", "ENEMY_MELEE_STOP_DISTANCE", "ENEMY_MELEE_RANGE", "ENEMY_MELEE_INTERVAL", "PATH_REFRESH_TIME", "PATH_ARRIVAL_DISTANCE", "KILL_SCORE", "COMBO_WINDOW", "EXIT_RADIUS", "SOUND_ENABLED", "SOUND_VOLUME_DB", "SCREEN_SHAKE_SCALE", "SHOT_SHAKE", "HIT_SHAKE", "DEATH_SHAKE", "DOOR_SHAKE", "SHAKE_DECAY", "MELEE_FLASH_TIME", "SHOT_TRACE_TIME", "BLOOD_ENABLED", "HIT_PARTICLE_COUNT", "PARTICLE_MIN_SPEED", "PARTICLE_MAX_SPEED", "PARTICLE_MIN_LIFE", "PARTICLE_MAX_LIFE", "UNDO_LIMIT", "MAX_ENEMIES", "MAX_MAP_FILE_BYTES", "ACTOR_SPRITE_SCALE", "WALK_ANIMATION_FPS", "ATTACK_ANIMATION_TIME", "WEAPON_SPRITE_SCALE", "BLOOD_SPRITE_SCALE", "FLOOR_TEXTURE_SCALE", "EDITOR_DEFAULT_ZOOM", "EDITOR_MIN_ZOOM", "EDITOR_MAX_ZOOM", "EDITOR_ZOOM_STEP", "EDITOR_GRID_VISIBLE", "PLAY_CAMERA_ZOOM", "PLAY_CAMERA_FOLLOW_SPEED", "MAX_MAP_OBJECTS", "OBJECT_SNAP_SIZE", "OBJECT_ROTATION_STEP", "OBJECT_ANIMATION_FPS", "PLACEMENT_PREVIEW_COLOR", "PLACEMENT_OUTLINE_COLOR", "FLOOR_STAMP_SCALE_STEP", "FLOOR_PLAN_DEFAULT_SCALE", "FLOOR_PLAN_TARGET_SIZE", "PROP_SCALE_OVERRIDES", "DOOR_LEAF_THICKNESS", "MAX_AUDIO_VOICES", "EDITOR_UI_REFRESH_INTERVAL", "FPS_COUNTER_REFRESH_INTERVAL", "MAP_WIDTH_CELLS", "MAP_HEIGHT_CELLS", "CELL_SIZE", "LAYOUT_MAX_WIDTH", "LAYOUT_MAX_HEIGHT", "LAYOUT_ENEMY_POSITIONS", "LAYOUT_MAX_WINDOWS", "LAYOUT_WINDOW_SPACING", "DEFAULT_LAYOUT_ASSET", "DEFAULT_LAYOUT_FRAME", "DEFAULT_LAYOUT_FRAMES", "ENEMY_WEAPON_PATTERN", "ENEMY_START_ANGLE_DEGREES", "ENEMY_COLLISION_RADIUS", "ENEMY_BULLET_DAMAGE", "ENEMY_MELEE_DAMAGE", "ENEMIES_DROP_WEAPONS", "DOOR_PUSH_LOOKAHEAD", "DOOR_CLOSE_CLEARANCE", "ACTOR_COLLISION_STEP", "PROJECTILE_COLLISION_STEP", "RAYCAST_STEP", "VISIBILITY_TOLERANCE", "PARTICLE_DRAG", "BLOOD_MIN_OFFSET", "BLOOD_MAX_OFFSET", "BLOOD_MIN_SIZE", "BLOOD_MAX_SIZE", "EXIT_SPRITE_SCALE", "EXIT_ANIMATION_FPS", "THROW_SPIN_SPEED", "PICKUP_GLOW_RADIUS", "DEFAULT_VOLUME", "DEFAULT_SHOW_FPS", "DEFAULT_SCREEN_SHAKE", "DEFAULT_VSYNC", "DEFAULT_FULLSCREEN", "DEFAULT_FRAME_LIMIT", "FRAME_LIMIT_OPTIONS"]
const LOCKED_SETTINGS := ["MAP_WIDTH_CELLS", "MAP_HEIGHT_CELLS", "CELL_SIZE"]
