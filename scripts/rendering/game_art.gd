extends RefCounted
## Original horizontal PNG strips are referenced directly, without modifying them.
const ROOT := "res://HLM1 Files/"
const FILES := {
	"player_gun": "Player/sprPWalkMagnum_strip8.png",
	"player_bat": "Player/sprPWalkBat_strip8.png",
	"player_fists": "Player/sprPWalkUnarmed_strip8.png",
	"player_shoot": "Player/sprPAttackMagnum_strip3.png",
	"player_swing": "Player/sprPAttackBat_strip9.png",
	"player_punch": "Player/sprPAttackPunch_strip7.png",
	"player_legs": "Player/sprLegs_strip16.png",
	"player_dead": "Player/sprPBackMachinegun_strip4.png",
	"enemy_gun": "Combat/Enemy/sprEWalkSilencer_strip8.png",
	"enemy_bat": "Combat/Enemy/sprEWalkBat_strip8.png",
	"enemy_legs": "Combat/Enemy/sprELegs_strip16.png",
	"enemy_dead": "Combat/Enemy/sprEBackMachinegun_strip4.png",
	"door": "Doors/sprDoorH.png",
	"wall": "Walls/sprWallSoftH.png",
	"wall_v": "Walls/sprWallSoftV.png",
	"sofa": "Furniture/sprSofaH48_strip2.png",
	"weapons": "Weapons/sprWeapons_strip35.png",
	"blood": "Gore/sprBloodSplatSmall_strip8.png",
	"cursor": "Combat/sprCursor.png",
	"exit": "Combat/sprGoArrow_strip4.png",
	"floors": "Floor tiles/bacground0.png",
}
var textures: Dictionary = {}
var frames: Dictionary = {}

func _init() -> void:
	var pattern := RegEx.new()
	pattern.compile("_strip([0-9]+)")
	for key in FILES:
		var texture := load(ROOT + FILES[key]) as Texture2D
		if texture == null: continue
		textures[key] = texture
		var match_result := pattern.search(FILES[key])
		var count := int(match_result.get_string(1)) if match_result else 1
		var width := texture.get_width() / count
		var sequence: Array[AtlasTexture] = []
		for i in count:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(i * width, 0, width, texture.get_height())
			frame.filter_clip = true
			sequence.append(frame)
		frames[key] = sequence

func frame(key: String, index: int = 0) -> Texture2D:
	if not frames.has(key): return null
	return frames[key][posmod(index, frames[key].size())]

func floor_region(tile: int) -> Rect2:
	match tile:
		3: return Rect2(0, 240, 16, 16)
		4: return Rect2(80, 16, 16, 16)
	return Rect2(0, 112, 16, 16)
