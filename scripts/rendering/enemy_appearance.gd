extends RefCounted
## One walking appearance per character/weapon; action strips are not extra enemies.
const ROOT := "Combat/Enemy/"
const ARENA_ENEMIES := [
	"sprEWalkUnarmed_strip8.png", "sprEWalkBat_strip8.png", "sprEWalkClub_strip8.png",
	"sprEWalkPipe_strip8.png", "sprEWalkKnife_strip8.png", "sprEWalkSilencer_strip8.png",
	"sprEWalkM16_strip8.png", "sprEWalkShotgun_strip8.png", "sprEWalkDoubleBarrel_strip8.png",
	"sprPoliceWalkUnarmed_strip8.png", "sprPoliceWalkGun_strip8.png", "sprPoliceWalkM16_strip8.png",
	"sprPoliceWalkShotgun_strip8.png", "sprPoliceWalkNightStick_strip8.png",
	"sprEFatWalk_strip8.png", "sprPInspectorWalk_strip8.png",
	"sprWaiterWalkFood_strip8.png", "sprWaiterWalkUzi_strip8.png",
]

static func death_asset(appearance: String) -> String:
	var name := appearance.get_file().to_lower()
	if "police" in name: return ROOT + "sprPoliceBackMachinegun_strip4.png"
	if "inspector" in name: return ROOT + "sprPInspectorDead_strip3.png"
	if "fat" in name: return ROOT + "sprEFatDead_strip6.png"
	if "waiter" in name: return ROOT + "sprWaiterDeadMachinegun_strip3.png"
	return ROOT + "sprEBackMachinegun_strip4.png"
