extends SceneTree
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
const EnemiesSettings = preload("res://scripts/settings/enemies_settings.gd")
const PlayerSettings = preload("res://scripts/settings/player_settings.gd")
const WeaponsSettings = preload("res://scripts/settings/weapons_settings.gd")
const WorldSettings = preload("res://scripts/settings/world_settings.gd")

const Maps = preload("res://scripts/maps/map_data.gd")
const Game = preload("res://scripts/game/main.gd")
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
	check(Maps.validate(game.map) == "", "New starter apartment validates")
	check(game.map.cells.has(5), "Generated default includes working doors")
	check(not game.map.objects.is_empty(), "Generated default includes windows")
	for item in game.map.objects: check(not item.asset.begins_with("Floor Plans/"), "Default contains no diagram stamps")
	game.check_routes()
	check(game.status.text.begins_with("Routes checked"), "Starter apartment enemies and exit are reachable")
	for i in game.map.objects.size():
		var prop: Dictionary = game.map.objects[i]
		check(game.workshop.hit_test(Vector2(prop.pos[0], prop.pos[1])) == i, "Starter furniture and layout are selectable")
	game.replace_map(Maps.demo())
	var screen_point := Vector2(310, 275)
	var anchored_world := game.screen_to_world(screen_point)
	game.zoom_at(screen_point, 1.5)
	check(game.screen_to_world(screen_point).distance_to(anchored_world) < 0.001, "Zoom preserves world position under cursor")
	game.editor_center += Vector2(50, -20)
	check(game.screen_to_world(game.MAP_VIEW.get_center()).distance_to(game.editor_center) < 0.001, "Panning and pointer coordinates share camera transform")
	game.zoom_at(screen_point, 1000)
	check(game.editor_zoom == EditorVisualsSettings.EDITOR_MAX_ZOOM, "Zoom respects maximum")
	game.editor_zoom = EditorVisualsSettings.EDITOR_DEFAULT_ZOOM
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
	check(game.move_actor(Vector2(42, 42), Vector2(-100, 0)).x >= 14 + WorldSettings.WALL_THICKNESS / 2 + PlayerSettings.PLAYER_COLLISION_RADIUS, "Collision prevents thin-wall tunneling")
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
	check(game.reload_remaining == WeaponsSettings.RELOAD_TIME, "Reload uses configured duration")
	game.fire()
	check(game.ammo == 2, "Cannot fire while reloading")
	game.update_reload(WeaponsSettings.RELOAD_TIME + 0.01)
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
	check(game.workshop.metadata.size() == 1431, "All supplied PNGs are catalogued")
	check(game.workshop.window is PanelContainer, "Asset library is an embedded dock")
	check(game.workshop.window.position == Vector2(1280, 108), "Asset dock leaves room for top toolbar")
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
	check(game.workshop.tabs.get_tab_count() == 1, "Editor has only Build and Items tabs")
	check(not game.workshop.tabs.tabs_visible, "Simplified tabs remain in expected order")
	check(game.workshop.get_node("TopBar").is_ancestor_of(game.toggle_button) and game.workshop.get_node("TopBar").is_ancestor_of(game.title_input), "Map name and playtest controls live in top bar")
	for tool in game.palette: check(game.workshop.is_ancestor_of(tool), "Terrain tools live in right dock")
	game.workshop.mode = "terrain"
	game.workshop.choose("Floor Plans/sprApartment1_strip16.png")
	check(game.workshop.mode == "select", "Layout selection does not activate picture stamping")
	check(game.workshop.draft.scale == EditorVisualsSettings.FLOOR_PLAN_DEFAULT_SCALE and game.workshop.draft.layer == 0, "Floor plan defaults to enlarged floor layer")
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
	game.player = game.center([11, 5]) + Vector2(20, 0)
	game.use_door(game.player, true)
	check(not game.open_doors.has(Vector2i(11, 5)), "Door closes immediately when nearby player is clear of leaf")
	check(not game.can_stand(game.center([11, 5])), "Actor center cannot straddle closed thin door")
	game.reset_game()
	check(game.open_doors.is_empty(), "Restart closes all doors")
	game.toggle_mode()
	game.paint(Vector2i(11, 5), true)
	check(game.map.cells[5 * Maps.WIDTH + 11] == int(game.map.floors[5 * Maps.WIDTH + 11]), "Deleting a door preserves stored floor")
	game.workshop.show_atlas_tiles()
	check(game.workshop.filtered.size() == game.workshop.atlas_tiles.size() and game.workshop.atlas_tiles.size() > 100, "Atlas category exposes non-empty cells")
	var atlas_entry: Dictionary = game.workshop.atlas_tiles[0]
	game.workshop.choose_tile(atlas_entry)
	check(game.workshop.draft.crop == atlas_entry.crop and game.workshop.draft.layer == 0, "Atlas tile selects its crop on the floor layer")
	check(game.workshop.preview.texture.get_size() == Vector2(16, 16), "Atlas preview shows one tile")
	print("Atlas tiles available: %d" % game.workshop.atlas_tiles.size())
	game.workshop.show_room_layouts()
	check(game.workshop.layouts_list.item_count == game.workshop.room_layouts.size() and game.workshop.layouts_page.visible, "Room-layout browser exposes individual frames")
	var layout: Dictionary = game.workshop.room_layouts[1]
	game.workshop.choose_entry(layout)
	check(game.workshop.draft.frame == layout.frame and game.workshop.draft.layer == 0, "Room layout selects exact frame on floor layer")
	game.replace_map(Maps.demo())
	check(game.solid(Vector2(11 * 28 + 14, 3 * 28 + 14)), "Thin wall center blocks")
	check(not game.solid(Vector2(11 * 28 + 2, 3 * 28 + 14)), "Visible floor beside thin wall is walkable")
	check(game.wall_segments(Vector2i(11, 3))[0].size.x == WorldSettings.WALL_THICKNESS, "Vertical wall uses configured native thickness")
	print("Room layouts available: %d" % game.workshop.room_layouts.size())
	game.replace_map(Maps.demo())
	game.select_brush(8)
	game.fill_area(Vector2i(3, 11))
	check(game.map.cells[11 * Maps.WIDTH + 3] == 4, "Fill changes connected room floor")
	check(game.map.cells[14 * Maps.WIDTH + 17] == 1, "Fill does not cross walls or closed door tiles")
	game.undo()
	check(game.map.cells[11 * Maps.WIDTH + 3] == 3, "Room fill is one undoable edit")
	game.layout_tool = "fill"
	game.select_brush(9)
	check(game.layout_tool == "paint", "Door selection leaves floor-only fill tool")
	game.workshop.choose("Furniture/sprSofaH48_strip2.png")
	game.workshop.place(Vector2(448, 308))
	var object_index: int = game.workshop.objects().size() - 1
	var click := InputEventMouseButton.new()
	click.position = game.MAP_VIEW.get_center() + (Vector2(game.workshop.objects()[object_index].pos[0], game.workshop.objects()[object_index].pos[1]) - game.editor_center) * game.editor_zoom
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.ctrl_pressed = true
	game.workshop.mode = "terrain"
	game.workshop.handle_event(click)
	check(game.workshop.selected == object_index and game.workshop.mode == "select", "Ctrl-click grabs object from terrain mode using event coordinates")
	check(game.workshop.draft.asset == game.workshop.objects()[object_index].asset, "Grab synchronizes inspector asset")
	click.ctrl_pressed = false
	click.shift_pressed = true
	click.button_index = MOUSE_BUTTON_RIGHT
	game.workshop.handle_event(click)
	check(game.workshop.objects()[object_index].rotation == 90 and game.workshop.rotation_input.value == 90, "Shift-right-click rotates object and inspector together")
	game.workshop.apply_selected()
	check(game.workshop.objects()[object_index].rotation == 90, "Applying inspector preserves shortcut rotation")
	game.workshop.clipboard = game.workshop.objects()[object_index].duplicate(true)
	var paste := InputEventKey.new()
	paste.pressed = true
	paste.ctrl_pressed = true
	paste.keycode = KEY_V
	game.workshop.mode = "terrain"
	game.workshop.handle_event(paste)
	check(game.workshop.mode == "stamp" and game.workshop.draft.rotation == 90, "Paste works from terrain mode with synchronized properties")
	var before_delete: int = game.workshop.objects().size()
	click.shift_pressed = false
	game.workshop.handle_event(click)
	check(game.workshop.objects().size() == before_delete - 1, "Right-click erases object under pointer")
	game.undo()
	check(game.workshop.objects().size() == before_delete, "Object erasure is undoable")
	game.workshop.choose("Furniture/sprSofaH48_strip2.png")
	var wheel := InputEventMouseButton.new()
	game.workshop.rotate_active(90)
	check(game.workshop.draft.rotation == 90 and game.workshop.rotation_input.value == 90, "Layout rotate button updates preview and properties")
	game.workshop.place(Vector2(448, 308))
	check(game.workshop.objects().back().rotation == 90, "Placed layout keeps preview rotation")
	game.workshop.rotate_active(-90)
	check(game.workshop.draft.rotation == 0, "Layout rotate left reverses right rotation")
	wheel.position = game.MAP_VIEW.get_center()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	var original_scale: float = game.workshop.draft.scale
	var original_zoom: float = game.editor_zoom
	game.workshop.choose_tile(atlas_entry)
	original_scale = game.workshop.draft.scale
	check(game.workshop.handle_event(wheel), "Floor tile consumes wheel for resizing")
	check(is_equal_approx(game.workshop.draft.scale, original_scale + float(game.SIZE) / game.workshop.ATLAS_CELL), "Wheel increases floor size by one grid cell")
	check(game.workshop.scale_input.value == game.workshop.draft.scale and game.editor_zoom == original_zoom, "Wheel resize synchronizes inspector without zooming")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	game.workshop.handle_event(wheel)
	check(is_equal_approx(game.workshop.draft.scale, original_scale), "Wheel down reduces layout size")
	wheel.ctrl_pressed = true
	check(not game.workshop.handle_event(wheel), "Ctrl-wheel passes through to camera zoom")
	wheel.ctrl_pressed = false
	game.workshop.choose_tile(atlas_entry)
	check(is_equal_approx(game.workshop.draft.scale * 16, float(game.SIZE)), "Atlas tile matches terrain cell size")
	check(game.workshop.position_for(Vector2(29, 29)) == Vector2(42, 42), "Tile preview snaps to terrain cell center")
	game.workshop.place(Vector2(29, 29))
	var tile_count: int = game.workshop.objects().size()
	var history_count: int = game.history.size()
	game.workshop.place(Vector2(30, 30))
	check(game.workshop.objects().size() == tile_count and game.history.size() == history_count, "Repeated tile placement neither stacks nor adds undo entry")
	var large: Dictionary = game.workshop.draft.duplicate(true)
	large.scale = float(game.SIZE) * 2 / game.workshop.ATLAS_CELL
	game.workshop.align_floor(large, Vector2(280, 280))
	game.workshop.objects().append(large)
	var neighbor: Dictionary = large.duplicate(true)
	game.workshop.align_floor(neighbor, Vector2(308, 280))
	check(game.workshop.floor_overlap(neighbor), "Different centers cannot hide overlapping large floor tiles")
	game.workshop.align_floor(neighbor, Vector2(336, 280))
	check(not game.workshop.floor_bounds(large).intersects(game.workshop.floor_bounds(neighbor)), "Large floor tiles meet exactly at their grid edges")
	game.workshop.objects().erase(large)

	game.workshop.choose_tile(game.workshop.atlas_tiles[1])
	game.workshop.place(Vector2(30, 30))
	check(game.workshop.objects().size() == tile_count, "Different tile replaces existing cell stamp")
	check(game.workshop.handle_event(wheel), "Floor atlas tiles support wheel resizing")
	game.workshop.choose("Furniture/sprSofaH48_strip2.png")
	check(not game.workshop.handle_event(wheel), "Furniture wheel retains camera zoom")
	root.size = Vector2i(1920, 1080)
	game.workshop.tabs.current_tab = 0
	await process_frame
	await process_frame
	check(game.workshop.window.get_global_rect().end.x <= 1920 and game.workshop.window.get_global_rect().end.y <= 1080, "Items dock fits within 1080p screen")
	check(game.workshop.get_node("TopBar").get_global_rect().end.x <= 1920, "Top toolbar fits screen width")
	game.workshop.show_library_page()
	check(game.workshop.library_page.visible and not game.workshop.detail_page.visible, "Back restores library page")
	game.workshop.choose_entry(layout)
	check(game.workshop.detail_page.visible and not game.workshop.library_page.visible, "Choosing asset opens dedicated detail page")
	await process_frame
	await process_frame
	check(game.workshop.window.get_global_rect().end.y <= 1080, "Expanded inspector remains inside screen")
	var cancel := InputEventKey.new()
	cancel.pressed = true
	cancel.keycode = KEY_ESCAPE
	game.workshop.handle_event(cancel)
	game.workshop.update_mode()
	check(game.workshop.mode == "select" and not game.painting, "Escape cancels placement safely into selection")
	check(game.workshop.select_tool.button_pressed and not game.workshop.place_tool.button_pressed, "Toolbar highlights active selection tool")
	check(game.workshop.select_tool.icon != null and game.workshop.place_tool.icon != null, "Primary tools have vector icons")
	game.workshop.choose_tile(atlas_entry)
	game.workshop.use_stamp()
	game.workshop.update_mode()
	check(game.workshop.place_tool.button_pressed and not game.workshop.select_tool.button_pressed, "Placement tool highlight follows mode")
	game.workshop.choose_entry(layout)
	var before_layout: Dictionary = game.map.duplicate(true)
	game.workshop.build_selected_layout()
	check(Maps.validate(game.map) == "", "Layout builds valid terrain map")
	game.check_routes()
	check(game.status.text.begins_with("Routes checked"), "Generated layout routes are connected")
	game.undo()
	check(game.map == before_layout, "Building a layout can be undone")
	var rejected_layouts := 0
	for entry in game.workshop.room_layouts:
		var generated: Dictionary = Maps.from_layout(entry.path, entry.frame, int(game.workshop.metadata[entry.path].frames))
		if generated.name == "Untitled floor": rejected_layouts += 1
		check(Maps.validate(generated) == "", "Generated layout validates: " + entry.name)
		var connected := Maps.layout_reachable(generated, Vector2i(generated.spawn[0], generated.spawn[1]))
		for cell in [generated.exit] + generated.enemies:
			check(connected.has(Vector2i(cell[0], cell[1])), "Generated layout actors are reachable: " + entry.name)
	game.replace_map(Maps.demo())
	game.workshop.activate_select()
	game.workshop.update_mode()
	check(not game.workshop.delete_tool.disabled, "Delete tool is available without an object selection")
	game.workshop.delete_tool.pressed.emit()
	check(game.workshop.mode == "erase", "Delete activates click-to-erase tool")
	game.editor_center = game.center([11, 3])
	var erase_event := InputEventMouseButton.new()
	erase_event.pressed = true
	erase_event.button_index = MOUSE_BUTTON_LEFT
	erase_event.position = game.MAP_VIEW.get_center() + (game.center([11, 3]) - game.editor_center) * game.editor_zoom
	game.workshop.handle_event(erase_event)
	check(game.map.cells[3 * Maps.WIDTH + 11] == int(game.map.floors[3 * Maps.WIDTH + 11]), "Eraser removes wall and preserves stored floor")
	game.undo()
	check(game.map.cells[3 * Maps.WIDTH + 11] == 2, "Erased wall is undoable")
	check(game.structural_floor(Vector2i(11, 3), Vector2(0.25, 0.25)) == 3, "Wall backing inherits wood on wood side")
	check(game.structural_floor(Vector2i(11, 3), Vector2(0.75, 0.25)) == 1, "Wall backing inherits carpet on carpet side")
	for segment in game.wall_segments(Vector2i(11, 3)):
		check(Rect2(Vector2(11, 3) * game.SIZE, Vector2.ONE * game.SIZE).encloses(segment), "Wall geometry stays within cell bounds")
	game.replace_map(Maps.blank())
	var layered_cell := Vector2i(8, 8)
	game.select_brush(7)
	game.paint(layered_cell, false)
	game.select_brush(2)
	game.paint(layered_cell, false)
	check(game.map.floors[8 * Maps.WIDTH + 8] == 3, "Building wall preserves wood floor layer")
	game.select_brush(8)
	game.paint(layered_cell, false)
	check(game.map.cells[8 * Maps.WIDTH + 8] == 2 and game.map.floors[8 * Maps.WIDTH + 8] == 4, "Floor repaint does not remove wall")
	game.paint(layered_cell, true)
	check(game.map.cells[8 * Maps.WIDTH + 8] == 4, "Removing wall reveals exact repainted floor")
	game.replace_map(Maps.blank())
	# T junction: no overlapping cap rectangles, and a continuous crossbar.
	for cell in [Vector2i(8, 8), Vector2i(7, 8), Vector2i(9, 8), Vector2i(8, 9)]:
		game.map.cells[cell.y * Maps.WIDTH + cell.x] = 2
	var junction: Array = game.wall_segments(Vector2i(8, 8))
	check(junction.size() == 2 and junction[0].size.x == game.SIZE, "T junction uses one continuous crossbar")
	check(not junction[0].intersection(junction[1]).has_area(), "Wall branches meet without overlapping caps")
	check(is_equal_approx(junction[0].end.y, junction[1].position.y), "Wall branches meet without a gap")
	game.map.cells[7 * Maps.WIDTH + 8] = 0
	game.map.cells[8 * Maps.WIDTH + 9] = 0
	var floor_bounds: Rect2 = game.structural_floor_rect(Vector2i(8, 8))
	check(floor_bounds.position.y == 8.5 * game.SIZE and floor_bounds.end.x == 8.5 * game.SIZE, "Exterior floor stops at top and right wall centerlines")
	var patch := PackedVector2Array([Vector2(8, 8), Vector2(9, 8), Vector2(9, 9), Vector2(8, 9)])
	for i in patch.size(): patch[i] *= game.SIZE
	var clipped_patches: Array = game.workshop.floor_patch_polygons(patch)
	check(not clipped_patches.is_empty(), "Floor stamp keeps its interior portion at an exterior corner")
	for polygon in clipped_patches:
		for point in polygon:
			check(point.y >= floor_bounds.position.y and point.x <= floor_bounds.end.x, "Floor stamp cannot spill beyond exterior wall centerlines")
	var outside := PackedVector2Array([Vector2.ZERO, Vector2(28, 0), Vector2(28, 28), Vector2(0, 28)])
	game.map.cells[0] = 0
	check(game.workshop.floor_patch_polygons(outside).is_empty(), "Floor stamps do not draw over empty space")
	var before_wall_delete: Rect2 = game.floor_rect(Vector2i(8, 8))
	game.snapshot()
	game.paint(Vector2i(8, 8), true)
	check(game.floor_rect(Vector2i(8, 8)) == before_wall_delete, "Deleting exterior wall preserves exact floor footprint")
	var saved_outline: Dictionary = JSON.parse_string(JSON.stringify(game.map))
	game.map = Maps.normalize(saved_outline)
	check(game.floor_rect(Vector2i(8, 8)) == before_wall_delete, "Floor outline survives JSON save/load")
	game.undo()
	check(game.map.cells[8 * Maps.WIDTH + 8] == 2, "Undo restores clipped wall")
	game.workshop.show_room_layouts()
	game.workshop.layouts_list.item_selected.emit(8)
	var expected_layout: Dictionary = game.workshop.generated_layout.duplicate(true)
	game.workshop.create_layout_button.pressed.emit()
	check(game.map.cells == expected_layout.cells and game.map.name == expected_layout.name, "Dedicated create button builds exactly the previewed terrain")
	check(game.workshop.library_page.visible and not game.workshop.layouts_page.visible, "Creation returns to editing with visible result")
	for entry in game.workshop.filtered: check(entry.category != "Floor Plans", "Layout diagrams are excluded from assets")
	game._process(0.25)
	check(game.fps_label.text.begins_with("FPS: "), "FPS counter updates")
	game.queue_redraw()
	await process_frame
	await process_frame
	var outline_builds: int = game.wall_outline_builds
	game.queue_redraw()
	await process_frame
	await process_frame
	check(game.wall_outline_builds == outline_builds, "Unchanged frames reuse wall outlines")
	check(rejected_layouts <= 5, "Outline-aware converter supports at least 340 layouts")
	check(game.workshop.room_layouts.size() > 0 and game.workshop.room_layouts.size() < 63, "Curated browser contains unique layout representatives")
	check(game.workshop.find_children("*", "PopupPanel", true, false).is_empty(), "Build tools no longer use a trapping popup")
	game.workshop.show_build_page()
	await process_frame
	await process_frame
	check(game.workshop.window.get_global_rect().end.y <= 1080, "Expanded construction tools stay within screen")
	game.workshop.show_library_page()
	check(not game.workshop.construction_section.visible, "Assets navigation closes construction page")
	game.replace_map(Maps.blank())
	var before_insert: Dictionary = game.map.duplicate(true)
	var fragment := Maps.blank()
	fragment.cells.fill(0)
	for y in range(4, 7):
		for x in range(4, 7): fragment.cells[y * Maps.WIDTH + x] = 3 if x == 5 and y == 5 else 2
	game.workshop.generated_layout = fragment
	game.workshop.insert_layout_button.disabled = false
	game.workshop.insert_layout_button.pressed.emit()
	check(game.workshop.mode == "insert_layout", "Insert button enables placement preview")
	check(not game.workshop.insert_layout_at(Vector2.ZERO), "Out-of-bounds insertion is rejected")
	check(game.map == before_insert, "Rejected insertion leaves map unchanged")
	check(game.workshop.insert_layout_at(Vector2(10, 10) * game.SIZE), "Layout inserts at chosen map location")
	check(game.map.cells[10 * Maps.WIDTH + 10] == 3, "Inserted floor is positioned at cursor")
	check(game.map.spawn == before_insert.spawn and game.map.exit == before_insert.exit, "Insertion retains existing start and exit")
	game.undo()
	check(game.map == before_insert, "Entire insertion undoes in one step")
	game.replace_map(Maps.starter())
	var original_map := game.map.duplicate(true)
	game.workshop.generated_layout = Maps.starter()
	game.workshop.begin_layout_insert()
	check(game.workshop.insert_layout_at(Vector2(15, 33) * game.SIZE), "Full layout can be inserted beside the starting map")
	check(Maps.validate(game.map) == "", "Combined map validates")
	game.undo()
	check(game.map == original_map, "Side-by-side layout insertion undoes without altering original")
	var legacy := {"version": 1, "name": "Legacy", "cells": [], "spawn": [3, 11], "exit": [28, 11], "enemies": [], "objects": []}
	legacy.cells.resize(704)
	legacy.cells.fill(1)
	check(Maps.validate(legacy) == "", "Original 32x22 save remains loadable")
	var migrated := Maps.normalize(legacy)
	check(migrated.cells.size() == Maps.WIDTH * Maps.HEIGHT and migrated.spawn == [35, 33], "Legacy terrain and markers move together into expanded canvas")
	var categories = preload("res://scripts/editor/asset_categories.gd")
	check(categories.category_for("Combat/Enemy/sprEAttackBat_strip9.png") == "Enemies that are alive", "Attack sprites are in living-enemy category")
	check(categories.category_for("Combat/Enemy/sprEAxeKill_strip4.png") == "Enemies / death and damage", "Execution sprites stay out of living category")
	check(categories.category_for("Weapons/sprWeapons_strip35.png") == "Weapons / guns and melee", "Weapon sheets have their own category")
	game.replace_map(Maps.blank())
	game.workshop.choose("Combat/Enemy/sprEWalkM16_strip8.png")
	var previous_props: int = game.workshop.objects().size()
	game.workshop.place(Vector2(10.5, 10.5) * game.SIZE)
	check([10, 10] in game.map.enemies and game.workshop.objects().size() == previous_props, "Living sprite placement creates enemy rather than prop")
	check(Maps.validate(game.map) == "", "Living enemy map validates")
	game.reset_game()
	check(game.enemies.back().gun and game.enemies.back().get("appearance", "") == "Combat/Enemy/sprEWalkM16_strip8.png", "Placed enemy uses chosen appearance and gun AI")
	var weapons = preload("res://scripts/game/enemy_weapons.gd")
	check(weapons.identify("sprEWalkUnarmed_strip8.png") == "FISTS", "Unarmed enemies punch")
	check(weapons.identify("sprEWalkBat_strip8.png") == "BAT", "Bat enemies use weapon melee")
	check(weapons.profile("MELEE").range > weapons.profile("FISTS").range, "Melee weapons reach farther than fists")
	check(weapons.identify("sprEWalkM16_strip8.png") == "RIFLE" and weapons.identify("sprEWaiterWalkUzi_strip8.png") == "MACHINE_GUN", "Rifle and automatic enemies are distinct")
	game.projectiles.clear()
	var shooter: Dictionary = game.enemies.back()
	game.enemy_attack(shooter, weapons.profile("SHOTGUN"))
	check(game.projectiles.size() == EnemiesSettings.ENEMY_SHOTGUN_PELLETS, "Shotgun fires configured pellet count")
	check(not game.projectiles.front().vel.is_equal_approx(game.projectiles.back().vel), "Shotgun pellets fan out")
	game.projectiles.clear()
	game.enemy_attack(shooter, weapons.profile("RIFLE"))
	check(game.projectiles.size() == 1 and game.projectiles[0].damage == EnemiesSettings.ENEMY_RIFLE_DAMAGE, "Rifle projectile carries its damage")
	check(weapons.profile("MACHINE_GUN").interval < weapons.profile("PISTOL").interval, "Machine gun fires faster than pistol")
	game.reset_game()
	game.drops.clear()
	var victim: Dictionary = game.enemies.back()
	victim.weapon_kind = "SHOTGUN"
	victim.gun = true
	game.kill_enemy(victim)
	check(game.drops.size() == 1 and game.drops[0].weapon == "SHOTGUN", "Enemy drops actual shotgun")
	var blood_count: int = game.stains.size()
	game.kill_enemy(victim)
	check(game.drops.size() == 1 and game.stains.size() == blood_count, "Repeated kill cannot duplicate drops or blood")
	game.player = victim.pos
	game.weapon = "FISTS"
	game.pickup()
	check(game.weapon == "SHOTGUN", "Pickup retains weapon identity")
	game.throw_weapon()
	check(game.projectiles.back().weapon == "SHOTGUN", "Throw retains weapon identity")
	game.projectiles.back().life = 0
	game.update_projectiles(0.01)
	check(game.drops.back().weapon == "SHOTGUN", "Thrown weapon lands as same weapon")
	game.health = 1
	game.damage_player(1)
	check(game.dead and game.stains.size() > blood_count, "Player death creates persistent blood")
	var after_death: int = game.stains.size()
	game.damage_player(1)
	check(game.stains.size() == after_death, "Dead player cannot bleed repeatedly from same volley")
	check(weapons.identify("sprEWalkPipe_strip8.png") == "PIPE", "Pipe identity is preserved")
	check(weapons.identify("sprEWalkKnife_strip8.png") == "KNIFE", "Knife identity is preserved")
	game.replace_map(Maps.blank())
	game.reset_game()
	game.player = game.center([8, 10])
	var target := {"pos": game.center([10, 10]), "alive": true, "health": 2, "stun": 0.0, "timer": 0.0}
	game.enemies = [target]
	game.weapon = "PIPE"
	game.aim = 0
	game.throw_weapon()
	game.update_projectiles(0.1)
	check(target.stun == WeaponsSettings.STUN_DURATION and target.health == 2, "Thrown pipe stuns without damaging enemy")
	check(game.projectiles.is_empty() and game.drops.back().weapon == "PIPE", "Thrown pipe becomes recoverable pickup after impact")
	var drop_position: Vector2 = game.drops.back().pos
	game.update_drops(0.1)
	check(game.drops.back().pos != drop_position, "Impact gives dropped weapon physical motion")
	check(not game.solid(game.drops.back().pos), "Dropped weapon stays out of walls")
	for kind in ["BAT", "PIPE", "KNIFE"]:
		game.drops.clear()
		var melee_enemy := {"pos": game.center([10, 10]), "alive": true, "gun": false, "weapon_kind": kind}
		game.kill_enemy(melee_enemy)
		check(game.drops.size() == 1 and game.drops[0].weapon == kind, "Melee enemy drops exact " + kind)
	var player_weapons = preload("res://scripts/game/player_weapons.gd")
	for kind in ["BAT", "PIPE", "KNIFE", "CLUB", "NIGHTSTICK", "PISTOL", "SILENCER", "SHOTGUN", "DOUBLE_BARREL", "RIFLE", "MACHINE_GUN"]:
		game.drops.clear()
		game.projectiles.clear()
		game.weapon = "FISTS"
		game.player = game.center([10, 10])
		var armed := {"pos": game.player, "alive": true, "gun": player_weapons.is_gun(kind), "weapon_kind": kind}
		game.kill_enemy(armed)
		check(game.drops[0].weapon == kind, "Drop preserves " + kind)
		game.pickup()
		check(game.weapon == kind, "Pickup preserves " + kind)
		check(game.art.frames.has(player_weapons.held_sprite(kind)) and game.art.frames.has(player_weapons.held_sprite(kind, true)), "Held and attack sprites exist for " + kind)
		game.throw_weapon()
		check(game.projectiles.back().weapon == kind, "Throw preserves " + kind)
	check(player_weapons.drop_frame("KNIFE") == 5 and player_weapons.drop_frame("PIPE") == 2, "Knife and pipe use inspected atlas frames")
	game.replace_map(Maps.blank())
	var molotov_entry: Dictionary = {}
	for entry in game.workshop.catalog:
		if entry.get("pickup_kind", "") == "MOLOTOV": molotov_entry = entry; break
	check(not molotov_entry.is_empty(), "Molotov has a named playable library entry")
	game.workshop.choose_entry(molotov_entry)
	game.workshop.place(game.center([8, 10]))
	check(game.map.objects.back().pickup_kind == "MOLOTOV", "Editor places usable Molotov")
	check(Maps.validate(Maps.normalize(JSON.parse_string(JSON.stringify(game.map)))) == "", "Weapon pickups survive validated map save/load")
	game.reset_game()
	game.player = game.center([8, 10])
	game.weapon = "FISTS"
	game.pickup()
	check(game.weapon == "MOLOTOV", "Molotov pickup works")
	game.aim = 0
	game.throw_weapon()
	check(game.weapon == "FISTS", "Molotov is consumed on throw")
	game.projectiles.back().life = 0
	game.update_projectiles(0.01)
	check(game.fires.size() == 1 and game.drops.is_empty(), "Molotov shatters into fire instead of reusable pickup")
	game.player = game.center([20, 20])
	var burning := {"pos": game.fires[0].pos, "alive": true, "health": 10, "alert": false, "target": Vector2.ZERO}
	game.enemies = [burning]
	game.update_fires(0.01)
	check(burning.health == 10 - WeaponsSettings.MOLOTOV_DAMAGE, "Fire damages enemy")
	var remaining_health: int = burning.health
	game.update_fires(0.01)
	check(burning.health == remaining_health, "Fire damage respects tick interval")
	game.player = game.fires[0].pos
	game.health = 10
	game.fires[0].tick = 0.0
	game.update_fires(0.01)
	check(game.health == 10 - WeaponsSettings.MOLOTOV_DAMAGE, "Fire damages player too")
	game.player = game.center([20, 20])
	game.fires[0].pos = game.center([8, 10])
	burning.pos = game.center([10, 10])
	for y in range(1, Maps.HEIGHT - 1): game.map.cells[y * Maps.WIDTH + 9] = 2
	remaining_health = burning.health
	game.fires[0].tick = 0.0
	game.update_fires(0.01)
	check(burning.health == remaining_health, "Wall blocks fire damage to nearby enemy")
	game.fires[0].life = 0.01
	game.update_fires(0.02)
	check(game.fires.is_empty(), "Fire expires")
	game.reset_game()
	check(game.fires.is_empty() and game.drops.size() == 1, "Restart restores placed pickup and clears fire")
	game.queue_free()
	print("Layouts without usable geometry: %d / %d" % [rejected_layouts, game.workshop.room_layouts.size()])
	print("Smoke checks completed: %d failures" % failures)
	quit(1 if failures else 0)
