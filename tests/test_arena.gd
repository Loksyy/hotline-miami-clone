extends SceneTree
const Game = preload("res://scripts/game/main.gd")
const Settings = preload("res://scripts/settings/enemies_settings.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.sound.muted = true
	check(game.Maps.validate(game.map).is_empty(), "Arena validates")
	check(game.map.spawn == [game.Maps.WIDTH / 2, game.Maps.HEIGHT / 2], "Centered spawn")
	for y in range(game.Maps.HEIGHT / 2 - 13, game.Maps.HEIGHT / 2 + 13):
		for x in range(game.Maps.WIDTH / 2 - 19, game.Maps.WIDTH / 2 + 19):
			check(game.map.cells[y * game.Maps.WIDTH + x] == 1, "Open interior")
	var guns := 0
	for kind in game.PlayerWeapons.PICKUPS:
		if game.PlayerWeapons.is_gun(kind) or game.PlayerWeapons.is_melee(kind):
			guns += 1
			var matches := 0
			for item in game.map.objects:
				if item.get("pickup_kind", "") == kind: matches += 1
			check(matches == 1, kind + " available exactly once")
	check(game.map.objects.size() == guns, "Every usable gun and melee weapon once")
	for item in game.map.objects:
		var cell := Vector2i(Vector2(item.pos[0], item.pos[1]) / game.Maps.TILE)
		check(game.map.cells[cell.y * game.Maps.WIDTH + cell.x] == 1, "Pickup inside arena floor")
	check(game.map.enemies.size() == 18, "Only distinct enemy combinations")
	check(game.map.cells.count(2) == 132, "Only compact perimeter walls")
	check(game.map.cells.count(1) == 38 * 26, "Compact floor footprint")
	var appearances = preload("res://scripts/rendering/enemy_appearance.gd")
	for asset in game.map.enemy_styles.values():
		check(game.workshop.metadata.has(appearances.death_asset(asset)), "Matching corpse exists")
	check("Police" in appearances.death_asset("sprPoliceWalkGun_strip8.png"), "Police corpse")
	check("Fat" in appearances.death_asset("sprEFatWalk_strip8.png"), "Heavy corpse")
	check("Inspector" in appearances.death_asset("sprPInspectorWalk_strip8.png"), "Inspector corpse")
	check("Waiter" in appearances.death_asset("sprWaiterWalkUzi_strip8.png"), "Waiter corpse")
	game.reset_game()
	var saved := Settings.ENEMIES_INACTIVE
	Settings.ENEMIES_INACTIVE = true
	var enemy: Dictionary = game.enemies[0]
	var origin: Vector2 = enemy.pos
	game.pursue(enemy, 1.0)
	game.enemy_attack(enemy, game.EnemyWeapons.profile("PISTOL"))
	check(enemy.pos == origin and game.projectiles.is_empty(), "Inactive enemies cannot move or attack")
	var count := game.drops.size()
	enemy.weapon_kind = "PISTOL"
	game.damage_enemy(enemy, 10000)
	check(not enemy.alive and game.drops.size() == count + 1, "Inactive enemies die and drop weapons")
	Settings.ENEMIES_INACTIVE = false
	game.enemy_attack(game.enemies[1], game.EnemyWeapons.profile("PISTOL"))
	check(not game.projectiles.is_empty(), "Turning inactivity off restores attacks")
	Settings.ENEMIES_INACTIVE = saved
	game.queue_free()
	await process_frame
	print("Arena checks: %d failures" % failures)
	quit(failures)
