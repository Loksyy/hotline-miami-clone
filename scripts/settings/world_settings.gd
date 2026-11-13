extends RefCounted
## Map generation, geometry, collision precision and round scoring.
## Edit defaults here; restart to reload source edits, or use Developer Lab live.
## Saved Developer Lab overrides take priority. Units: seconds and world pixels.


# MELEE / THROWN WEAPONS
static var DOOR_STUN_RANGE := 48.0
static var WALL_THICKNESS := 8.0 # Native wall artwork thickness, independent of 28px cells.

# SCORE / ROUND
static var KILL_SCORE := 1000
static var COMBO_WINDOW := 3.0
static var EXIT_RADIUS := 22.0

# Native art proportions: couch 48px, bed 50x60px, table 50x30px.
static var DOOR_LEAF_THICKNESS := 4.0

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
static var DOOR_CLOSE_CLEARANCE := 0.5

# COLLISION ACCURACY (smaller steps cost more CPU; keep below wall thickness).
static var ACTOR_COLLISION_STEP := 2.0
static var PROJECTILE_COLLISION_STEP := 4.0
static var RAYCAST_STEP := 3.0
static var VISIBILITY_TOLERANCE := 4.0

const SETTING_NAMES := [
	"DOOR_STUN_RANGE",
	"WALL_THICKNESS",
	"KILL_SCORE",
	"COMBO_WINDOW",
	"EXIT_RADIUS",
	"DOOR_LEAF_THICKNESS",
	"MAP_WIDTH_CELLS",
	"MAP_HEIGHT_CELLS",
	"CELL_SIZE",
	"LAYOUT_MAX_WIDTH",
	"LAYOUT_MAX_HEIGHT",
	"LAYOUT_ENEMY_POSITIONS",
	"LAYOUT_MAX_WINDOWS",
	"LAYOUT_WINDOW_SPACING",
	"DEFAULT_LAYOUT_ASSET",
	"DEFAULT_LAYOUT_FRAME",
	"DEFAULT_LAYOUT_FRAMES",
	"DOOR_CLOSE_CLEARANCE",
	"ACTOR_COLLISION_STEP",
	"PROJECTILE_COLLISION_STEP",
	"RAYCAST_STEP",
	"VISIBILITY_TOLERANCE",
]
