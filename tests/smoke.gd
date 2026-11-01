extends SceneTree

const Maps = preload("res://scripts/map_data.gd")
const Game = preload("res://scripts/main.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var demo := Maps.demo()
	check(Maps.validate(demo) == "", "Demo must validate")
	check(Maps.validate(JSON.parse_string(JSON.stringify(demo))) == "", "JSON round trip must validate")
	var invalid := demo.duplicate(true)
	invalid.spawn = [-1, 3]
	check(Maps.validate(invalid) != "", "Reject out-of-bounds spawn")
	invalid = demo.duplicate(true)
	invalid.enemies.append(invalid.spawn)
	check(Maps.validate(invalid) != "", "Reject overlapping entities")
	invalid = demo.duplicate(true)
	invalid.cells[0] = "wall"
	check(Maps.validate(invalid) != "", "Reject invalid tile types")
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	var screen_point := Vector2(310, 275)
	var anchored_world := game.screen_to_world(screen_point)
	game.zoom_at(screen_point, 1.5)
	check(game.screen_to_world(screen_point).distance_to(anchored_world) < 0.001, "Zoom preserves world position under cursor")
	game.editor_center += Vector2(50, -20)
	check(game.screen_to_world(game.MAP_VIEW.get_center()).distance_to(game.editor_center) < 0.001, "Panning and pointer coordinates share camera transform")
	game.zoom_at(screen_point, 1000)
	check(game.editor_zoom == game.S.EDITOR_MAX_ZOOM, "Zoom respects maximum")
	game.editor_zoom = game.S.EDITOR_DEFAULT_ZOOM
	game.editor_center = Vector2(448, 308)
	game.set_process(false)
	game.snapshot()
	game.brush = 2
	game.paint(Vector2i(5, 5), false)
	check(game.map.cells[5 * Maps.WIDTH + 5] == 2, "Painting places walls")
	game.undo()
	check(game.map.cells[5 * Maps.WIDTH + 5] == 3, "Undo restores wood floor")
	game.redo()
	check(game.map.cells[5 * Maps.WIDTH + 5] == 2, "Redo restores wall")
	var original := game.map.duplicate(true)
	game.toggle_mode()
	game.enemies[0].alive = false
	game.toggle_mode()
	check(game.map == original, "Playtesting must preserve layout")
	check(game.enemies[0].alive, "Restart must reset enemies")
	check(game.move_actor(Vector2(42, 42), Vector2(-100, 0)).x >= 36, "Collision prevents wall tunneling")
	check(not game.visible_between(Vector2(290, 100), Vector2(350, 100)), "Walls block sight")
	game.file_action = "save"
	game.on_file_selected("user://smoke_map.json")
	game.replace_map(Maps.blank())
	game.file_action = "load"
	game.on_file_selected("user://smoke_map.json")
	check(game.map == original, "Disk save/load preserves map")
	game.replace_map(Maps.blank())
	game.toggle_mode()
	game.player = game.center(game.map.exit)
	game._process(0.016)
	check(game.won, "Exit wins when all enemies are cleared")
	game.toggle_mode()
	game.replace_map(Maps.blank())
	game.map.enemies = [[5, 11]]
	game.toggle_mode()
	game.player = game.center([4, 11])
	game.aim = 0
	game.weapon = "FISTS"
	game.melee()
	check(game.enemies[0].alive and game.enemies[0].stun > 0, "Punch knocks down enemy")
	game.melee()
	check(not game.enemies[0].alive and game.score == 1000, "Follow-up finishes enemy and scores")
	game.pickup()
	check(game.weapon == "PISTOL" and game.ammo == 6, "Pick up dropped pistol")
	game.throw_weapon()
	check(game.weapon == "FISTS" and game.projectiles.size() == 1, "Throw releases held weapon")
	for i in 20: game.update_projectiles(0.05)
	check(game.projectiles.is_empty() and game.drops.size() == 1, "Thrown weapon lands and can be recovered")
	game.toggle_mode()
	game.replace_map(Maps.blank())
	game.map.cells[11 * Maps.WIDTH + 4] = 5
	game.toggle_mode()
	check(game.solid(game.center([4, 11])), "Closed door blocks movement and shots")
	game.use_door(game.player, true)
	check(not game.solid(game.center([4, 11])), "Kicked door opens")
	game.toggle_mode()
	game.replace_map(Maps.demo())
	game.toggle_mode()
	var path := game.navigation.get_id_path(Vector2i(3, 11), Vector2i(28, 11))
	check(path.size() > 25, "Navigation routes around interior walls")
	game.projectiles = [{"pos": game.player + Vector2(40, 0), "vel": Vector2(-550, 0), "life": 2.0, "thrown": false}]
	game.update_projectiles(0.1)
	check(game.dead, "Enemy projectile kills on impact")
	game.reset_game()
	check(not game.dead and game.score == 0 and game.open_doors.is_empty(), "Retry resets combat and door state")
	# Reload tests explicitly equip a pistol; the user may choose a starting bat.
	game.weapon = "PISTOL"
	game.ammo = 2
	game.reserve_ammo = 3
	game.start_reload()
	check(game.reload_remaining == game.S.RELOAD_TIME, "Reload uses configured duration")
	game.fire()
	check(game.ammo == 2, "Cannot fire while reloading")
	game.update_reload(game.S.RELOAD_TIME + 0.01)
	check(game.ammo == 5 and game.reserve_ammo == 0, "Reload only transfers available reserve")
	game.reserve_ammo = 10
	game.start_reload()
	game.throw_weapon()
	check(game.reload_remaining == 0, "Throw cancels reload")
	game.health = 3
	game.damage_player(1)
	check(game.health == 2 and not game.dead, "Player supports configurable multi-hit health")
	game.enemies[0].health = 3
	game.damage_enemy(game.enemies[0], 1)
	check(game.enemies[0].health == 2 and game.enemies[0].alive, "Enemy supports configurable multi-hit health")
	game.toggle_mode()
	game.check_routes()
	check(game.status.text.begins_with("Routes checked"), "Demo entities are reachable")
	game.replace_map(Maps.blank())
	for y in range(1, Maps.HEIGHT - 1): game.map.cells[y * Maps.WIDTH + 10] = 2
	game.check_routes()
	check(game.status.text.begins_with("Unreachable"), "Route checker detects sealed rooms")
	for key in game.Art.FILES:
		check(game.art.frame(key) != null, "Texture loads: " + key)
	check(game.art.frames.player_gun.size() == 8, "Walking strip has eight frames")
	check(game.art.frame("player_gun").get_size() == Vector2(44, 32), "Atlas frame crops a single pose")
	check(game.art.frame("weapons", 7).get_image().get_pixel(0, 0).a == 0, "Sprite transparency is preserved")
	# The entire supplied library is catalogued; strip frames remain separately selectable.
	check(game.workshop.catalog.size() == 1431, "All supplied PNGs are catalogued")
	check(game.workshop.window is PanelContainer, "Asset library is an embedded dock")
	check(game.workshop.window.position == Vector2(1280, 0), "Asset dock occupies right side of 1080p layout")
	check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1920 and ProjectSettings.get_setting("display/window/size/viewport_height") == 1080, "Game uses a 1920 by 1080 viewport")
	for entry in game.workshop.catalog:
		check(ResourceLoader.exists(game.workshop.ROOT + entry.path), "Catalog asset exists: " + entry.path)
	game.workshop.search.text = "Sofa"
	game.workshop.filter_catalog()
	check(game.workshop.filtered.size() > 0 and game.workshop.filtered.size() < game.workshop.catalog.size(), "Library search filters assets")
	game.workshop.choose("Furniture/sprSofaH48_strip2.png")
	game.workshop.read_draft()
	game.workshop.use_stamp()
	check(game.workshop.window.visible, "Choosing a stamp keeps the dock visible")
	game.workshop.draft.solid = true
	game.workshop.draft.rotation = 90.0
	game.workshop.place(Vector2(140, 140))
	check(game.map.objects.size() == 1, "Object placement is separate from tiles")
	check(game.workshop.hit_test(Vector2(140, 140)) == 0, "Rotated object can be selected")
	check(game.workshop.is_solid(Vector2(140, 140)), "Solid object blocks its footprint")
	check(not game.workshop.is_solid(Vector2(170, 140)), "Collision respects rotated sprite bounds")
	check(Maps.validate(game.map) == "", "Map with placed object validates")
	check(Maps.validate(JSON.parse_string(JSON.stringify(game.map))) == "", "Object transforms survive JSON encoding")
	game.undo()
	check(game.map.objects.is_empty(), "Undo removes object placement")
	game.redo()
	check(game.map.objects.size() == 1, "Redo restores object placement")
	var object_map: Dictionary = game.map.duplicate(true)
	game.file_action = "save"
	game.on_file_selected("user://smoke_objects.json")
	game.replace_map(Maps.blank())
	game.file_action = "load"
	game.on_file_selected("user://smoke_objects.json")
	check(game.map == object_map, "Object layer survives disk save/load")
	var bad_object_map := game.map.duplicate(true)
	bad_object_map.objects[0].asset = "../project.godot"
	check(Maps.validate(bad_object_map) != "", "Reject asset paths outside the texture library")
	bad_object_map = game.map.duplicate(true)
	bad_object_map.objects[0].scale = 0
	check(Maps.validate(bad_object_map) != "", "Reject invalid object scale")
	game.workshop.choose("Floor tiles/bacground0.png")
	game.workshop.crop_inputs[0].value = 0
	game.workshop.crop_inputs[1].value = 112
	game.workshop.crop_inputs[2].value = 16
	game.workshop.crop_inputs[3].value = 16
	game.workshop.tiled_input.button_pressed = true
	game.workshop.width_input.value = 224
	game.workshop.height_input.value = 168
	game.workshop.read_draft()
	game.workshop.place(Vector2(400, 350))
	check(game.workshop.contains(game.map.objects[-1], Vector2(490, 350)), "Room surface has independent dimensions")
	check(game.workshop.texture_for("Floor tiles/bacground0.png", 0, [0, 112, 16, 16]).get_size() == Vector2(16, 16), "Atlas crop selects individual floor material")
	check(Maps.validate(game.map) == "", "Room surface map validates")
	check(game.workshop.tabs.get_tab_count() == 3, "Editor groups tools into three dock tabs")
	check(game.workshop.window.is_ancestor_of(game.toggle_button) and game.workshop.window.is_ancestor_of(game.title_input), "Map name and playtest controls live in right dock")
	for tool in game.palette: check(game.workshop.window.is_ancestor_of(tool), "Terrain tools live in right dock")
	game.workshop.mode = "terrain"
	game.workshop.choose("Floor Plans/sprApartment1_strip16.png")
	check(game.workshop.mode == "stamp", "Thumbnail click immediately enables placement")
	check(game.workshop.draft.scale == game.S.FLOOR_PLAN_DEFAULT_SCALE and game.workshop.draft.layer == 0, "Floor plan defaults to enlarged floor layer")
	game.workshop.scale_input.value = 3
	check(is_equal_approx(game.workshop.draft.scale, 3.0), "Inspector updates active stamp immediately")
	game.workshop.frame_input.value = 9
	check(game.workshop.draft.frame == 9, "Frame changes update active stamp")
	game.workshop.choose("Furniture/sprSofaH48_strip2.png")
	check(game.workshop.draft.scale == 1 and not game.workshop.draft.tiled, "Selecting prop resets floor-plan defaults")
	game.replace_map(Maps.demo())
	check(game.map.cells[6 * Maps.WIDTH + 11] == 2 and game.map.cells[11 * Maps.WIDTH + 22] == 2, "Demo doorways no longer have open bypass cells")
	check(game.door_is_vertical(Vector2i(11, 5)), "Door in vertical wall uses vertical leaf")
	check(not game.door_is_vertical(Vector2i(16, 8)), "Door in horizontal wall uses horizontal leaf")
	game.toggle_mode()
	game.player = game.center([10, 5])
	check(not game.visible_between(game.center([10, 5]), game.center([12, 5])), "Closed demo door blocks sight and shots")
	game.use_door(game.player, false)
	check(game.visible_between(game.center([10, 5]), game.center([12, 5])), "Pushing door opens sight and shooting route")
	game.player = game.move_actor(game.player, Vector2(56, 0))
	check(game.player.distance_to(game.center([12, 5])) < 1, "Player can pass through open doorway")
	game.use_door(game.player, true)
	check(not game.open_doors.has(Vector2i(11, 5)), "Space closes nearby unoccupied door")
	game.use_door(game.player, true)
	game.player = game.center([11, 5])
	game.use_door(game.player, true)
	check(game.open_doors.has(Vector2i(11, 5)), "Occupied doorway cannot close on player")
	game.reset_game()
	check(game.open_doors.is_empty(), "Restart closes all doors")
	game.toggle_mode()
	game.paint(Vector2i(11, 5), true)
	check(game.map.cells[5 * Maps.WIDTH + 11] == 1, "Terrain erase restores floor")
	game.queue_free()
	await process_frame
	print("Smoke checks completed: %d failures" % failures)
	quit(1 if failures else 0)
