extends RefCounted
## Original horizontal PNG strips are referenced directly, without modifying them.
const ROOT := "res://HLM1 Files/"
const FILES := {
	"molotov": "Weapons/sprMolotov_strip4.png",
	"fire": "Weapons/sprBottleFlames_strip5.png",
	"fire_burst": "Weapons/sprBottleExplodeFlame_strip9.png",
	"player_silencer": "Player/sprPWalkSilencer_strip8.png",
	"player_silencer_attack": "Player/sprPAttackSilencer_strip3.png",
	"player_double_barrel": "Player/sprPWalkDoubleBarrel_strip8.png",
	"player_double_barrel_attack": "Player/sprPAttackDoubleBarrel1_strip5.png",
	"player_club": "Player/sprPWalkClub_strip8.png",
	"player_club_attack": "Player/sprPAttackClub_strip9.png",
	"player_nightstick": "Player/sprPWalkNightStick_strip8.png",
	"player_nightstick_attack": "Player/sprPAttackNightStick_strip9.png",
	"player_pipe": "Player/sprPWalkPipe_strip8.png",
	"player_pipe_attack": "Player/sprPAttackPipe_strip9.png",
	"player_knife": "Player/sprPWalkKnife_strip8.png",
	"player_knife_attack": "Player/sprPAttackKnife_strip9.png",
	"player_shotgun": "Player/sprPWalkShotgun_strip8.png",
	"player_shotgun_attack": "Player/sprPAttackShotgun_strip12.png",
	"player_rifle": "Player/sprPWalkM16_strip8.png",
	"player_rifle_attack": "Player/sprPAttackM16_strip2.png",
	"player_machine_gun": "Player/sprPWalkUzi_strip8.png",
	"player_machine_gun_attack": "Player/sprPAttackUzi_strip2.png",
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
	"wall_source": "Floor/sprFloor_strip4.png",
	"sofa": "Furniture/sprSofaH48_strip2.png",
	"weapons": "Weapons/sprWeapons_strip35.png",
	"blood": "Gore/sprBloodSplatSmall_strip8.png",
	"cursor": "Combat/sprCursor.png",
	"exit": "Combat/sprGoArrow_strip4.png",
	"floors": "Floor tiles/bacground0.png",
}
var textures: Dictionary = {}
var frames: Dictionary = {}
var actor_origins: Dictionary = {}

func _init() -> void:
	var pattern := RegEx.new()
	pattern.compile("_strip([0-9]+)")
	var sources := FILES.duplicate()
	var weapons = preload("res://scripts/game/player_weapons.gd")
	for kind in weapons.SOURCES: sources["pickup_" + kind] = weapons.pickup_asset(kind)
	for kind in weapons.ANIMATIONS:
		var stem: String = weapons.ANIMATIONS[kind]
		for file in DirAccess.get_files_at(ROOT + "Player/"):
			if file.begins_with("sprPWalk" + stem + "_strip") and file.ends_with(".png"): sources["weapon_" + kind + "_walk"] = "Player/" + file
			if file.begins_with("sprPAttack" + stem + "_strip") and file.ends_with(".png"): sources["weapon_" + kind + "_attack"] = "Player/" + file
	for key in sources:
		var texture := load(ROOT + sources[key]) as Texture2D
		if texture == null: continue
		textures[key] = texture
		var match_result := pattern.search(sources[key])
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
		if sources[key].begins_with("Player/sprPWalk") or sources[key].begins_with("Player/sprPAttack"):
			# The original strips have different canvas margins. Cache the same head/torso
			# anchor in each frame, so changing sheets cannot displace the body from its legs.
			var image := texture.get_image()
			var origins: Array[Vector2] = []
			for i in count:
				var sum := Vector2.ZERO
				var pixels := 0
				for y in image.get_height():
					for x in int(width):
						var c := image.get_pixel(i * int(width) + x, y)
						if c.a > 0.5 and c.to_html(false) in ["c0c000"]:
							sum += Vector2(x + 0.5, y + 0.5)
							pixels += 1
				origins.append(sum / pixels if pixels > 0 else Vector2(16, 16))
			actor_origins[key] = origins

	_build_default_walls()

func _build_default_walls() -> void:
	# Sample only the straight edges of Floor's first corner. Exclude its
	# wooden floor and corner cap so these strips repeat for any wall length.
	var regions := {"wall": Rect2(33, 28, 8, 8), "wall_v": Rect2(41, 20, 8, 8)}
	for key in regions:
		var strip := AtlasTexture.new()
		strip.atlas = textures["wall_source"]
		strip.region = regions[key]
		strip.filter_clip = true
		frames[key] = [strip]

func frame(key: String, index: int = 0) -> Texture2D:
	if not frames.has(key): return null
	return frames[key][posmod(index, frames[key].size())]

func floor_region(tile: int) -> Rect2:
	match tile:
		3: return Rect2(0, 240, 16, 16)
		4: return Rect2(80, 16, 16, 16)
	return Rect2(0, 112, 16, 16)

func actor_origin(key: String, index: int) -> Vector2:
	if not actor_origins.has(key): return Vector2(16, 16)
	return actor_origins[key][posmod(index, actor_origins[key].size())]
