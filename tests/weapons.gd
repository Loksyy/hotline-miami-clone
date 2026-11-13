extends SceneTree
const WeaponsSettings = preload("res://scripts/settings/weapons_settings.gd")
const Game = preload("res://scripts/game/main.gd")
const W = preload("res://scripts/game/player_weapons.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	game.set_process(false)
	game.replace_map(game.Maps.blank())
	var entries: Array = game.workshop.catalog.filter(func(e): return e.has("pickup_kind"))
	check(entries.size() == W.PICKUPS.size(), "Every weapon has one library entry")
	for kind in W.PICKUPS:
		check(not kind.begins_with("TEST_") and kind not in ["BROKEN_CUE", "KEY", "BLUE_KEY", "GREEN_GUN", "SCORPION", "NINJA_KNIFE", "NINJA_BLADE", "BODYGUARD_SWORD", "BOSS_PISTOL", "GOLD_TROPHY"], "Removed weapon hidden: " + kind)
		for attacking in [false, true]:
			var key := W.held_sprite(kind, attacking)
			check(game.art.frames.has(key), kind + " animation exists")
			check(game.art.actor_origins.has(key), kind + " has aligned torso anchors")
	for entry in game.workshop.catalog:
		check(entry.category != "Weapons / guns and melee", "Raw weapon category removed")
		check(not "WeaponMask" in entry.path, "WeaponMask excluded")
	for entry in entries:
		var kind: String = entry.pickup_kind
		game.workshop.choose_entry(entry)
		game.workshop.place(game.center([8, 10]))
		check(game.map.objects.back().pickup_kind == kind, kind + " placed as usable weapon")
		check(game.workshop.weapon_icon(kind).get_size() == Vector2(110, 52), kind + " has normalized thumbnail")
		game.map.objects.clear()
		game.player = game.center([8, 10])
		game.weapon = "FISTS"
		game.drops.clear()
		game.projectiles.clear()
		game.enemies.clear()
		game.spawn_drop(game.player, kind, int(W.stats(kind)[0]) if W.is_gun(kind) else 0)
		game.attack_animation = 0.2
		game.swing = 0.1
		game.pickup()
		check(game.attack_animation == 0 and game.swing == 0, kind + " pickup clears previous attack")
		check(game.weapon == kind, kind + " pickup identity")
		check(game.art.frames.has("pickup_" + kind), kind + " world sprite exists")
		game.aim = 0.0
		game.reload_remaining = 0.0
		if W.is_gun(kind):
			var before: int = game.ammo
			game.fire()
			check(game.ammo == before - 1, kind + " fires ammunition")
		elif W.is_melee(kind):
			var target := {"pos": game.player + Vector2(10, 0), "alive": true, "health": 100, "alert": false, "target": Vector2.ZERO, "stun": 0.0}
			game.enemies = [target]
			game.fire()
			check(target.health < 100, kind + " melee damages enemy")
		game.enemies.clear()
		game.throw_weapon()
		check(game.projectiles.back().weapon == kind, kind + " throw identity")
		game.projectiles.back().life = 0.0
		game.update_projectiles(0.01)
		if kind != "MOLOTOV": check(game.drops.back().weapon == kind, kind + " landing identity")
		game.fires.clear()
	# Throw-only weapons must hurt enemies, rather than acting as a punch.
	game.projectiles.clear()
	game.weapon = "SHURIKEN"
	var victim := {"pos": game.player + Vector2(12, 0), "alive": true, "health": 100, "alert": false, "target": Vector2.ZERO, "stun": 0.0, "timer": 0.0}
	game.enemies = [victim]
	game.fire()
	game.update_projectiles(0.02)
	check(victim.health == 100 - WeaponsSettings.THROW_WEAPON_DAMAGE, "Throwing weapons deal configured damage")
	check(W.stats("DOUBLE_BARREL")[0] == 2, "Double barrel has two shells")
	check(game.art.actor_origin("weapon_AXE_attack", 0).x > 24, "Axe uses its own canvas anchor")
	check(game.art.actor_origin("weapon_SWORD_walk", 0).y > 24, "Sword aligns tall sprite with legs")
	game.enemies.clear()
	for kind in W.PICKUPS:
		if not W.is_gun(kind): continue
		var counts: Array[int] = []
		for fps in [30, 120]:
			game.weapon = kind
			game.ammo = 500
			game.cooldown = 0.0
			for tick in fps * 2:
				game.cooldown -= 1.0 / fps
				if game.cooldown <= 0: game.fire()
			counts.append(500 - game.ammo)
		check(absi(counts[0] - counts[1]) <= 1, kind + " fire cadence stable across frame rates")
	if "--preview" in OS.get_cmdline_user_args():
		game.workshop.show_library_page()
		for i in game.workshop.category.item_count:
			if game.workshop.category.get_item_text(i) == "Weapons": game.workshop.category.select(i)
		game.workshop.filter_catalog()
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/weapons-library.png")
	game.queue_free()
	await process_frame
	print("Weapon checks: %d weapons, %d failures" % [entries.size(), failures])
	quit(1 if failures else 0)
