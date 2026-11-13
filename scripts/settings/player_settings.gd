extends RefCounted
## Player movement, health, interaction and play camera.
## Edit defaults here; restart to reload source edits, or use Developer Lab live.
## Saved Developer Lab overrides take priority. Units: seconds and world pixels.


# PLAYER
static var PLAYER_SPEED := 280.0
static var PLAYER_COLLISION_RADIUS := 8.0
static var PLAYER_HIT_RADIUS := 10.0
static var PLAYER_HEALTH := 1
static var START_WEAPON := "PISTOL" # Any usable weapon ID from player_weapons.gd, or FISTS.
static var PICKUP_RANGE := 42.0

# DOOR INTERACTION
static var DOOR_INTERACT_DISTANCE := 45.0

# PLAY CAMERA / SHIFT LOOK
static var PLAY_CAMERA_ZOOM := 3
static var PLAY_CAMERA_FOLLOW_SPEED := 10.0
static var SHIFT_LOOK_ENABLED := true # Hold Shift in playtest to see more around you.
static var SHIFT_LOOK_DISTANCE := 160.0 # Maximum camera offset in world pixels toward the cursor.
static var SHIFT_LOOK_TRANSITION_SPEED := 8.0 # Higher = faster look-ahead and return.

# AUTOMATIC DOOR OPENING
static var DOOR_PUSH_LOOKAHEAD := 12.0

const SETTING_NAMES := [
	"PLAYER_SPEED",
	"PLAYER_COLLISION_RADIUS",
	"PLAYER_HIT_RADIUS",
	"PLAYER_HEALTH",
	"START_WEAPON",
	"PICKUP_RANGE",
	"DOOR_INTERACT_DISTANCE",
	"PLAY_CAMERA_ZOOM",
	"PLAY_CAMERA_FOLLOW_SPEED",
	"SHIFT_LOOK_ENABLED",
	"SHIFT_LOOK_DISTANCE",
	"SHIFT_LOOK_TRANSITION_SPEED",
	"DOOR_PUSH_LOOKAHEAD",
]
