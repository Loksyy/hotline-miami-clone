extends RefCounted
## EDIT THIS FILE TO TUNE THE GAME, THEN STOP AND RUN AGAIN (F5).
## Times are seconds, distances are pixels, speeds are pixels/second.
## Keep durations/speeds positive and ammunition counts nonnegative.

# PLAYER
const PLAYER_SPEED := 280.0
const PLAYER_COLLISION_RADIUS := 8.0
const PLAYER_HIT_RADIUS := 10.0
const PLAYER_HEALTH := 1
const START_WEAPON := "PISTOL" # PISTOL, BAT, or FISTS
const PICKUP_RANGE := 42.0

# PISTOL / RELOAD
const MAGAZINE_SIZE := 8
const START_RESERVE_AMMO := 24
const FIRE_INTERVAL := 0.18 # Lower means faster firing.
const RELOAD_TIME := 1.1
const SHOT_DAMAGE := 1
const SHOT_RANGE := 850.0
const EMPTY_TRIGGER_INTERVAL := 0.3
const GUNSHOT_HEARING_RANGE := 380.0
const DROPPED_PISTOL_AMMO := 6

# MELEE / THROWN WEAPONS
const MELEE_INTERVAL := 0.3
const PUNCH_RANGE := 44.0
const BAT_RANGE := 62.0
const MELEE_ARC_DOT := 0.25 # -1 hits all directions; 1 requires exact aim.
const BAT_DAMAGE := 1
const FINISHER_DAMAGE := 1
const STUN_DURATION := 2.5
const THROW_SPEED := 650.0
const THROW_LIFETIME := 0.65
const THROW_HIT_RADIUS := 14.0
const DOOR_STUN_RANGE := 48.0
const DOOR_INTERACT_DISTANCE := 45.0

# ENEMIES
const ENEMY_HEALTH := 1
const ENEMY_HIT_RADIUS := 12.0
const ENEMY_GUN_SPEED := 115.0
const ENEMY_MELEE_SPEED := 165.0
const ENEMY_SIGHT_RANGE := 350.0
const ENEMY_CLOSE_DETECTION_RANGE := 75.0
const ENEMY_VISION_DOT := 0.2 # Lower gives a wider field of view.
const ENEMY_REACTION_TIME := 0.7
const ENEMY_FIRE_INTERVAL := 0.8
const ENEMY_BULLET_SPEED := 550.0
const ENEMY_BULLET_LIFETIME := 2.0
const ENEMY_DAMAGE := 1
const ENEMY_SHOOT_DISTANCE := 150.0
const ENEMY_MELEE_STOP_DISTANCE := 18.0
const ENEMY_MELEE_RANGE := 23.0
const ENEMY_MELEE_INTERVAL := 0.6
const PATH_REFRESH_TIME := 0.3
const PATH_ARRIVAL_DISTANCE := 4.0

# SCORE / ROUND
const KILL_SCORE := 1000
const COMBO_WINDOW := 3.0
const EXIT_RADIUS := 22.0

# FEEDBACK / ACCESSIBILITY
const SOUND_ENABLED := true # M toggles sound during play.
const SOUND_VOLUME_DB := -8.0
const SCREEN_SHAKE_SCALE := 1.0 # Set 0 to disable.
const SHOT_SHAKE := 3.0
const HIT_SHAKE := 5.0
const DEATH_SHAKE := 8.0
const DOOR_SHAKE := 4.0
const SHAKE_DECAY := 24.0
const MELEE_FLASH_TIME := 0.16
const SHOT_TRACE_TIME := 0.09
const BLOOD_ENABLED := true
const HIT_PARTICLE_COUNT := 12
const PARTICLE_MIN_SPEED := 40.0
const PARTICLE_MAX_SPEED := 200.0
const PARTICLE_MIN_LIFE := 0.15
const PARTICLE_MAX_LIFE := 0.4

# EDITOR
const UNDO_LIMIT := 100
const MAX_ENEMIES := 200
const MAX_MAP_FILE_BYTES := 1000000

# TEXTURES / ANIMATION (from HLM1 Files)
const ACTOR_SPRITE_SCALE := 0.85
const WALK_ANIMATION_FPS := 12.0
const ATTACK_ANIMATION_TIME := 0.18
const WEAPON_SPRITE_SCALE := 0.75
const BLOOD_SPRITE_SCALE := 0.55
const FLOOR_TEXTURE_SCALE := 1.5 # World pixels per source pixel; independent of grid size.
const EDITOR_DEFAULT_ZOOM := 1.5
const EDITOR_MIN_ZOOM := 0.65
const EDITOR_MAX_ZOOM := 4.0
const EDITOR_ZOOM_STEP := 1.15
const EDITOR_GRID_VISIBLE := false
const PLAY_CAMERA_ZOOM := 1.7
const PLAY_CAMERA_FOLLOW_SPEED := 10.0

# ASSET WORKSHOP
const MAX_MAP_OBJECTS := 2000
const OBJECT_SNAP_SIZE := 7.0
const OBJECT_ROTATION_STEP := 15.0
const OBJECT_ANIMATION_FPS := 12.0
const FLOOR_PLAN_DEFAULT_SCALE := 4.0 # Enlarge miniature map-section artwork.
const FLOOR_PLAN_TARGET_SIZE := 448.0 # Keep already-large floor-plan images at native size.
