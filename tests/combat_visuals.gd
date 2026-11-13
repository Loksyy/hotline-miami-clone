extends SceneTree
const Game = preload("res://scripts/game/main.gd")
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
	game.enemies.clear()
	game.weapon = "FISTS"
	game.reload_remaining = 0
	for i in 8:
		game.elapsed = i * 0.4
		game.cooldown = 0
		game.melee()
		check(game.punch_step == i % 4, "Four-punch cycle")
	game.elapsed += 2
	game.cooldown = 0
	game.melee()
	check(game.punch_step == 0, "Combo resets after a pause")
	game.weapon = "PISTOL"
	game.ammo = 0
	game.reserve_ammo = 30
	game.start_reload()
	check(game.reload_duration == game.reload_remaining and game.reload_duration > 0, "Reload indicator captures full duration")
	game.update_reload(game.reload_duration / 2)
	check(is_equal_approx(game.reload_remaining / game.reload_duration, 0.5), "Reload fills in sync")
	game.update_reload(game.reload_duration)
	check(game.ammo > 0 and game.reload_remaining == 0, "Reload completes normally")
	game.replace_map(game.Maps.blank())
	game.player = game.center([8, 8])
	game.enemies.clear()
	var target := {"pos": game.player + Vector2(70, 0), "alive": true, "health": 100, "alert": false, "target": Vector2.ZERO}
	game.enemies.append(target)
	game.fire_ray(Vector2.RIGHT, 200, 1)
	check(target.health == 99, "Hitscan damages target")
	check(game.traces.back().b.x < target.pos.x, "Tracer stops on target surface")
	check(game.combat_effects.back().pos == game.traces.back().b, "Impact matches tracer endpoint")
	for i in 120: game.add_combat_effect(Vector2.ZERO, 0, "wall")
	check(game.combat_effects.size() == 96, "Combat effects stay bounded")
	game.weapon = "PISTOL"
	game.ammo = 2
	game.reserve_ammo = 5
	game.drops.clear()
	game.projectiles.clear()
	game.throw_weapon()
	game.projectiles[0].life = 0
	game.update_projectiles(0)
	game.drops[0].pos = game.player
	game.pickup()
	check(game.ammo == 2 and game.reserve_ammo == 5, "Throw and pickup preserve magazine reserve")
	game.queue_free()
	await process_frame
	print("Combat visual checks: %d failures" % failures)
	quit(failures)
