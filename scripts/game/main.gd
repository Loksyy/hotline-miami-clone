extends Node2D
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
const EnemiesSettings = preload("res://scripts/settings/enemies_settings.gd")
const PlayerSettings = preload("res://scripts/settings/player_settings.gd")
const WeaponsSettings = preload("res://scripts/settings/weapons_settings.gd")
const WorldSettings = preload("res://scripts/settings/world_settings.gd")

const WallGeometry = preload("res://scripts/rendering/wall_geometry.gd")
const Maps = preload("res://scripts/maps/map_data.gd")
const ORIGIN := Vector2(32, 80)
const SIZE := 28
const Art = preload("res://scripts/rendering/game_art.gd")
var art := Art.new()
var render_origin := ORIGIN
var MAP_VIEW := Rect2(32, 80, 1416, 968)
var editor_zoom := EditorVisualsSettings.EDITOR_DEFAULT_ZOOM
var editor_center := Vector2(Maps.WIDTH, Maps.HEIGHT) * SIZE / 2.0
var play_center := Vector2.ZERO
var look_offset := Vector2.ZERO
var view_zoom := 1.0
var show_grid := EditorVisualsSettings.EDITOR_GRID_VISIBLE
var player_walk := 0.0
var player_moving := false
var attack_animation := 0.0
var attack_duration := 0.2
var combat_effects: Array = []
var gun_recoil := 0.0
var punch_step := -1
var punch_last_time := -10.0
var reload_duration := 0.0
const CombatVisuals = preload("res://scripts/rendering/combat_visuals.gd")
var attack_is_melee := false
const Sound = preload("res://scripts/audio/sound.gd")
var sound: Node
var navigation := AStarGrid2D.new()
var open_doors: Dictionary = {}
var drops: Array = []
var fires: Array = []
var projectiles: Array = []
var particles: Array = []
var stains: Array = []
var weapon := "PISTOL"
var ammo := 8
var reserve_ammo := 0
var reload_remaining := 0.0
var health := 1
var score := 0
var combo := 0
var combo_time := 0.0
var elapsed := 0.0
var shake := 0.0
var swing := 0.0
var aim := 0.0
var hud: Label
var map: Dictionary = Maps.starter()
var editing := true
var brush := 2
var layout_tool := "paint"
var player := Vector2.ZERO
var enemies: Array = []
var dead := false
var won := false
var cooldown := 0.0
var traces: Array = []
var history: Array = []
var future: Array = []
var painting := false
var rectangle_start := Vector2i(-1, -1)
var rectangle_mode := false
var last_cell := Vector2i(-1, -1)
var status: Label
var mode_label: Label
var title_input: LineEdit
var toggle_button: Button
var palette: Array = []
var dialog: FileDialog
var file_action := ""
const Preferences = preload("res://scripts/settings/runtime_settings.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
var preferences := Preferences.new()
var pause_menu: CanvasLayer
const PlayerWeapons = preload("res://scripts/game/player_weapons.gd")
const EnemyWeapons = preload("res://scripts/game/enemy_weapons.gd")
const Workshop = preload("res://scripts/editor/asset_workshop.gd")
var workshop: Node

func _ready() -> void:
	preload("res://scripts/settings/live_tuning.gd").initialize()
	preferences.load_settings()
	Maps.ensure_floor_layer(map)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sound = Sound.new()
	add_child(sound)
	build_ui()
	workshop = Workshop.new()
	add_child(workshop)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	reset_game()
	queue_redraw()

func label_at(text: String, position: Vector2, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func button_at(text: String, position: Vector2, action: Callable, width: float = 260) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = Vector2(width, 36)
	button.pressed.connect(action)
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button

func build_ui() -> void:
	fps_label = label_at("FPS: --", Vector2(1330, 48), 18)
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_label = label_at("FLOOR DESIGNER", Vector2(420, 30), 18)
	mode_label.hide()
	hud = label_at("AFTER HOURS / 1989   •   DESIGN YOUR WAY IN", Vector2(32, 48), 17)
	title_input = LineEdit.new()
	title_input.text = map.name
	title_input.placeholder_text = "Map name"
	title_input.text_submitted.connect(func(_text): title_input.release_focus())
	add_child(title_input)
	status = Label.new()
	status.text = "Choose a build tool or click an asset, then place it on the map."
	status.modulate = Color("60e4dc")
	add_child(status)
	dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Project Gagugaga maps"])
	dialog.file_selected.connect(on_file_selected)
	add_child(dialog)

func select_brush(index: int) -> void:
	if workshop != null: workshop.mode = "terrain"
	painting = false
	rectangle_mode = false
	if index not in [1, 7, 8] and layout_tool in ["room", "fill"]: layout_tool = "paint"
	if index != 2 and layout_tool == "outline": layout_tool = "paint"
	brush = index
	if status != null:
		var hints := ["Void: drag to remove floor.", "Carpet: drag to paint. Shift+drag fills a room.", "Wall: drag to build connected walls. Shift+drag fills a rectangle.", "Spawn: click a floor to move the player start.", "Enemy: click an empty floor to add an enemy.", "Exit: click a floor to move the exit.", "Erase: removes enemies or clears terrain to empty space.", "Wood: drag to paint. Shift+drag fills a room.", "Tile: drag to paint. Shift+drag fills a room.", "Door: replace one wall cell; orientation follows neighboring walls.", "Sofa: adjacent cells combine into a couch."]
		status.text = hints[index]
	for i in palette.size():
		palette[i].modulate = Color("60e4dc") if i == brush else Color.WHITE

func snapshot() -> void:
	map.name = title_input.text
	history.append(map.duplicate(true))
	if history.size() > EditorVisualsSettings.UNDO_LIMIT:
		history.pop_front()
	future.clear()

func undo() -> void:
	if not editing or history.is_empty(): return
	future.append(map.duplicate(true))
	map = history.pop_back()
	if workshop != null: workshop.selected = -1; workshop.selected_terrain = Vector2i(-1, -1); workshop.dragging = false; workshop.show_library_page()
	title_input.text = map.name
	queue_redraw()

func redo() -> void:
	if not editing or future.is_empty(): return
	history.append(map.duplicate(true))
	map = future.pop_back()
	if workshop != null: workshop.selected = -1; workshop.selected_terrain = Vector2i(-1, -1); workshop.dragging = false; workshop.show_library_page()
	title_input.text = map.name
	queue_redraw()

func replace_map(value: Dictionary) -> void:
	if not editing: return
	snapshot()
	map = value
	Maps.ensure_floor_layer(map)
	if workshop != null: workshop.selected = -1; workshop.selected_terrain = Vector2i(-1, -1); workshop.dragging = false; workshop.show_library_page()
	title_input.text = map.name
	status.text = "New layout ready. Undo restores the previous map."
	queue_redraw()

func choose_file(action: String) -> void:
	if not editing: return
	file_action = action
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if action == "save" else FileDialog.FILE_MODE_OPEN_FILE
	dialog.current_file = "my_floor.json" if action == "save" else ""
	dialog.popup_centered(Vector2i(850, 550))

func on_file_selected(path: String) -> void:
	if file_action == "save":
		map.name = title_input.text
		var error := Maps.validate(map)
		if error != "":
			status.text = error
			return
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			status.text = "Could not write file: " + error_string(FileAccess.get_open_error())
			return
		file.store_string(JSON.stringify(map, "\t"))
		status.text = "Saved: " + path.get_file()
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			status.text = "Could not open map."
			return
		if file.get_length() > EditorVisualsSettings.MAX_MAP_FILE_BYTES:
			status.text = "Map file is too large."
			return
		var value: Variant = JSON.parse_string(file.get_as_text())
		var error := Maps.validate(value)
		if error != "":
			status.text = error
			return
		replace_map(Maps.normalize(value))
		status.text = "Loaded: " + path.get_file()

func toggle_mode() -> void:
	if editing:
		if workshop != null:
			for cell in [map.spawn, map.exit] + map.enemies:
				if workshop.is_solid(center(cell)):
					status.text = "A solid prop overlaps the spawn, exit, or an enemy. Move it before playtesting."
					return
		var error := Maps.validate(map)
		if error != "":
			status.text = error
			return
	editing = not editing
	if workshop != null: workshop.update_mode()
	painting = false
	rectangle_mode = false
	title_input.editable = editing
	title_input.release_focus()
	toggle_button.text = "▶  PLAYTEST   [TAB]" if editing else "■  BACK TO EDITOR   [TAB]"
	mode_label.text = "FLOOR DESIGNER" if editing else "LIVE / ONE SHOT, ONE LIFE"
	status.text = "Editor restored. Your layout is preserved." if editing else "Clear the floor, then reach the green exit."
	reset_game()

func center(cell: Array) -> Vector2:
	return Vector2(cell[0], cell[1]) * SIZE + Vector2.ONE * SIZE / 2.0

func check_routes() -> void:
	if not editing: return
	var error := Maps.validate(map)
	if error != "":
		status.text = error
		return
	rebuild_navigation()
	var start := Vector2i(map.spawn[0], map.spawn[1])
	for cell in [map.exit] + map.enemies:
		if navigation.get_id_path(start, Vector2i(cell[0], cell[1])).is_empty():
			status.text = "Unreachable entity at (%d, %d). Paint a floor route or doorway." % cell
			return
	status.text = "Routes checked: every enemy and the exit are reachable. Doors can be opened."

func reset_game() -> void:
	combat_effects.clear()
	gun_recoil = 0
	punch_step = -1
	punch_last_time = -10.0
	player_walk = 0
	player_moving = false
	attack_animation = 0
	open_doors.clear()
	drops.clear()
	fires.clear()
	for item in map.get("objects", []):
		if item.has("pickup_kind"):
			var kind: String = item.pickup_kind
			spawn_drop(Vector2(item.pos[0], item.pos[1]), kind, int(PlayerWeapons.stats(kind)[0]) if PlayerWeapons.is_gun(kind) else 0)
	projectiles.clear()
	particles.clear()
	stains.clear()
	weapon = PlayerSettings.START_WEAPON
	ammo = int(PlayerWeapons.stats(weapon)[0]) if PlayerWeapons.is_gun(weapon) else 0
	reserve_ammo = starting_reserve(weapon)
	reload_remaining = 0
	health = PlayerSettings.PLAYER_HEALTH
	score = 0
	combo = 0
	combo_time = 0
	elapsed = 0
	shake = 0
	swing = 0
	rebuild_navigation()
	player = center(map.spawn)
	play_center = player
	look_offset = Vector2.ZERO
	enemies.clear()
	for cell in map.enemies:
		enemies.append({"pos": center(cell), "alive": true, "health": EnemiesSettings.ENEMY_HEALTH, "angle": deg_to_rad(EnemiesSettings.ENEMY_START_ANGLE_DEGREES), "alert": false, "timer": EnemiesSettings.ENEMY_REACTION_TIME, "stun": 0.0, "path": PackedVector2Array(), "repath": randf() * EnemiesSettings.PATH_REFRESH_TIME, "target": center(cell), "gun": EnemiesSettings.ENEMY_WEAPON_PATTERN[enemies.size() % EnemiesSettings.ENEMY_WEAPON_PATTERN.size()] if not EnemiesSettings.ENEMY_WEAPON_PATTERN.is_empty() else false})
	for i in enemies.size():
		var coordinate: Array = map.enemies[i]
		var asset: String = map.get("enemy_styles", {}).get("%d,%d" % [coordinate[0], coordinate[1]], "")
		if workshop.metadata.has(asset) and workshop.metadata[asset].category == "Enemies that are alive":
			enemies[i]["appearance"] = asset
			enemies[i]["weapon_kind"] = EnemyWeapons.identify(asset)
			enemies[i].gun = EnemyWeapons.profile(enemies[i].weapon_kind).ranged
	for i in enemies.size():
		var cell: Array = map.enemies[i]
		var options: Dictionary = map.get("enemy_options", {}).get("%d,%d" % cell, {})
		if options.has("active"): enemies[i]["active"] = options.active
		if options.has("damage"): enemies[i]["damage_override"] = options.damage
		if options.has("health"): enemies[i].health = options.health
	dead = false
	won = false
	cooldown = 0
	traces.clear()
	queue_redraw()

func mouse_cell() -> Vector2i:
	return Vector2i((mouse_world() / SIZE).floor())

func fit_map() -> void:
	var low := Vector2i(Maps.WIDTH, Maps.HEIGHT)
	var high := Vector2i.ZERO
	for y in Maps.HEIGHT:
		for x in Maps.WIDTH:
			if map.cells[y * Maps.WIDTH + x] != 0:
				low = low.min(Vector2i(x, y))
				high = high.max(Vector2i(x + 1, y + 1))
	if high.x <= low.x: return
	editor_center = Vector2(low + high) * SIZE / 2.0
	var extent := Vector2(high - low) * SIZE + Vector2.ONE * SIZE * 2
	editor_zoom = clampf(minf(MAP_VIEW.size.x / extent.x, MAP_VIEW.size.y / extent.y), EditorVisualsSettings.EDITOR_MIN_ZOOM, EditorVisualsSettings.EDITOR_MAX_ZOOM)

func set_sidebar_visible(visible: bool) -> void:
	MAP_VIEW.size.x = 1416 if visible else 1856
	queue_redraw()

func camera_zoom() -> float:
	return editor_zoom if editing else maxf(0.1, PlayerSettings.PLAY_CAMERA_ZOOM)

func update_look_ahead(delta: float, looking: bool, cursor: Vector2) -> void:
	var target := Vector2.ZERO
	if looking and PlayerSettings.SHIFT_LOOK_ENABLED and MAP_VIEW.has_point(cursor):
		# Screen-relative direction avoids feedback as the camera itself moves.
		var direction := (cursor - MAP_VIEW.get_center()) / (MAP_VIEW.size / 2.0)
		target = direction.limit_length(1.0) * maxf(0.0, PlayerSettings.SHIFT_LOOK_DISTANCE)
	look_offset = look_offset.lerp(target, 1.0 - exp(-maxf(0.1, PlayerSettings.SHIFT_LOOK_TRANSITION_SPEED) * delta))

func camera_center() -> Vector2:
	return editor_center if editing else play_center + look_offset

func screen_to_world(point: Vector2) -> Vector2:
	return (point - MAP_VIEW.get_center()) / camera_zoom() + camera_center()

func mouse_world() -> Vector2:
	return screen_to_world(get_global_mouse_position())

func zoom_at(point: Vector2, factor: float) -> void:
	var anchor := screen_to_world(point)
	editor_zoom = clampf(editor_zoom * factor, EditorVisualsSettings.EDITOR_MIN_ZOOM, EditorVisualsSettings.EDITOR_MAX_ZOOM)
	editor_center += anchor - screen_to_world(point)
	queue_redraw()

func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < Maps.WIDTH and cell.y < Maps.HEIGHT

func paint(cell: Vector2i, erase: bool) -> void:
	Maps.ensure_floor_layer(map)
	if not inside(cell): return
	var coordinate := [cell.x, cell.y]
	var tool := 6 if erase else brush
	if tool <= 2 or tool >= 7:
		var tile: int = tool if tool <= 2 else tool - 4
		if not Maps.floor_tile(tile) and (coordinate == map.spawn or coordinate == map.exit or coordinate in map.enemies):
			status.text = "Move or erase the entity before covering its floor."
			return
		if tile in [0, 1, 3, 4]:
			map.floors[cell.y * Maps.WIDTH + cell.x] = tile
			map.get("floor_clips", {}).erase(str(cell.y * Maps.WIDTH + cell.x))
			map.get("floor_shapes", {}).erase(str(cell.y * Maps.WIDTH + cell.x))
		if not (tile in [0, 1, 3, 4] and map.cells[cell.y * Maps.WIDTH + cell.x] in [2, 5, 6]):
			map.cells[cell.y * Maps.WIDTH + cell.x] = tile
	elif tool == 6:
		if coordinate in map.enemies:
			map.enemies.erase(coordinate)
			map.get("enemy_styles", {}).erase("%d,%d" % [cell.x, cell.y])
			map.get("enemy_options", {}).erase("%d,%d" % [cell.x, cell.y])
		elif coordinate == map.spawn or coordinate == map.exit:
			status.text = "Move the player start or exit before deleting its floor."
		else:
			var index := cell.y * Maps.WIDTH + cell.x
			if map.cells[index] in [2, 5, 6]:
				# Keep the visible floor footprint independent of the removed structure.
				if map.cells[index] in [2, 5]:
					if not map.has("floor_clips"): map.floor_clips = {}
					if not map.has("floor_shapes"): map.floor_shapes = {}
					for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
						var neighbor: Vector2i = cell + offset
						if not wall_connects(neighbor): continue
						var shapes: Array = []
						for region in floor_regions(neighbor):
							var relative: Vector2 = (region.position - Vector2(neighbor) * SIZE) / SIZE
							shapes.append([relative.x, relative.y, region.size.x / SIZE, region.size.y / SIZE])
						map.floor_shapes[str(neighbor.y * Maps.WIDTH + neighbor.x)] = shapes
						var footprint := floor_rect(neighbor)
						var local := footprint.position - Vector2(neighbor) * SIZE
						map.floor_clips[str(neighbor.y * Maps.WIDTH + neighbor.x)] = [local.x / SIZE, local.y / SIZE, footprint.size.x / SIZE, footprint.size.y / SIZE]
				map.cells[index] = int(map.floors[index])
			else:
				map.cells[index] = 0; map.floors[index] = 0
				map.get("floor_clips", {}).erase(str(index))
				map.get("floor_shapes", {}).erase(str(index))
	else:
		if not Maps.floor_tile(map.cells[cell.y * Maps.WIDTH + cell.x]):
			status.text = "Entities need a floor tile."
			return
		if coordinate == map.spawn or coordinate == map.exit or coordinate in map.enemies: return
		if tool == 3: map.spawn = coordinate
		if tool == 4 and map.enemies.size() < EditorVisualsSettings.MAX_ENEMIES: map.enemies.append(coordinate)
		if tool == 5: map.exit = coordinate
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if dialog.visible: return
	if event is InputEventMouseButton and event.pressed and MAP_VIEW.has_point(event.position):
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null: focused.release_focus()
	if workshop != null and workshop.handle_event(event):
		queue_redraw()
		return
	if editing and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		editor_center -= event.relative / editor_zoom
		painting = false
		queue_redraw()
		return
	if editing and event is InputEventMouseButton and event.pressed and MAP_VIEW.has_point(event.position):
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position, pow(EditorVisualsSettings.EDITOR_ZOOM_STEP, preferences.zoom_sensitivity * (1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)))
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_mode()
		elif event.keycode == KEY_M:
			sound.muted = not sound.muted
		elif editing:
			if event.keycode == KEY_G:
				preferences.editor_grid = not preferences.editor_grid
				preferences.save()
			elif event.ctrl_pressed and event.keycode == KEY_S: choose_file("save")
			elif event.ctrl_pressed and event.keycode == KEY_O: choose_file("load")
			elif event.keycode == KEY_HOME:
				fit_map()
			elif event.ctrl_pressed and event.keycode == KEY_Z:
				if event.shift_pressed: redo()
				else: undo()
			elif event.ctrl_pressed and event.keycode == KEY_Y: redo()
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9: select_brush(event.keycode - KEY_1)
			elif event.keycode == KEY_0: select_brush(9)
			elif event.keycode == KEY_MINUS: select_brush(10)
		elif event.keycode == KEY_T or (event.keycode == KEY_R and (dead or won)):
			reset_game()
			status.text = "Fresh start. Clear the floor."
		elif not dead and not won:
			if event.keycode == KEY_R: start_reload()
			if event.keycode == KEY_E: pickup()
			if event.keycode == KEY_F and cooldown <= 0: melee()
			if event.keycode == KEY_SPACE: use_door(player, true)
	if not editing and not dead and not won and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		throw_weapon()
	if editing and event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if event.pressed and MAP_VIEW.has_point(event.position) and inside(mouse_cell()):
			if event.button_index == MOUSE_BUTTON_LEFT and layout_tool == "sample":
				var tile: int = map.cells[mouse_cell().y * Maps.WIDTH + mouse_cell().x]
				select_brush(tile if tile <= 2 else tile + 4)
				layout_tool = "paint"
				return
			if event.button_index == MOUSE_BUTTON_LEFT and layout_tool == "fill":
				fill_area(mouse_cell())
				return
			snapshot()
			painting = true
			last_cell = mouse_cell()
			rectangle_mode = (event.shift_pressed or layout_tool in ["room", "outline"]) and (brush <= 2 or brush >= 7) and event.button_index == MOUSE_BUTTON_LEFT
			rectangle_start = last_cell
			if not rectangle_mode: paint(last_cell, event.button_index == MOUSE_BUTTON_RIGHT)

func solid(point: Vector2) -> bool:
	var cell := Vector2i((point / SIZE).floor())
	if not inside(cell): return true
	if workshop != null and workshop.is_solid(point): return true
	var tile: int = map.cells[cell.y * Maps.WIDTH + cell.x]
	if tile == 2:
		for segment in wall_segments(cell):
			if segment.has_point(point): return true
		return false
	if tile == 5:
		if open_doors.has(cell): return false
		return door_leaf_rect(cell).has_point(point)
	return not Maps.floor_tile(tile) and not (tile == 5 and open_doors.has(cell))

func fill_area(start: Vector2i) -> void:
	Maps.ensure_floor_layer(map)
	var replacement := brush if brush <= 2 else brush - 4
	if not Maps.floor_tile(replacement) or not inside(start):
		status.text = "Fill: select carpet, wood, or tile first."
		return
	var original: int = map.cells[start.y * Maps.WIDTH + start.x]
	if original == replacement or not Maps.floor_tile(original): return
	snapshot()
	var pending: Array[Vector2i] = [start]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		if not inside(cell) or visited.has(cell): continue
		visited[cell] = true
		if map.cells[cell.y * Maps.WIDTH + cell.x] != original: continue
		map.cells[cell.y * Maps.WIDTH + cell.x] = replacement
		map.floors[cell.y * Maps.WIDTH + cell.x] = replacement
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]: pending.append(cell + offset)
	status.text = "Room floor replaced. Ctrl+Z undoes the fill."
	queue_redraw()

func can_stand(point: Vector2, radius: float = -1.0) -> bool:
	if radius < 0: radius = PlayerSettings.PLAYER_COLLISION_RADIUS
	# Include center and edge midpoints: corners alone miss thin walls/doors.
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		if solid(point + offset * radius): return false
	return true

func move_actor(position: Vector2, velocity: Vector2, radius: float = -1.0) -> Vector2:
	var steps := maxi(1, int(ceil(velocity.length() / maxf(0.1, WorldSettings.ACTOR_COLLISION_STEP))))
	var step := velocity / steps
	for i in steps:
		if can_stand(position + Vector2(step.x, 0), radius): position.x += step.x
		if can_stand(position + Vector2(0, step.y), radius): position.y += step.y
	return position

func ray_end(start: Vector2, direction: Vector2, distance: float) -> Vector2:
	var point := start
	for i in int(ceil(distance / maxf(0.1, WorldSettings.RAYCAST_STEP))):
		point = start + direction * minf((i + 1) * maxf(0.1, WorldSettings.RAYCAST_STEP), distance)
		if solid(point): return point
	return point

func visible_between(a: Vector2, b: Vector2) -> bool:
	return ray_end(a, a.direction_to(b), a.distance_to(b)).distance_to(b) < WorldSettings.VISIBILITY_TOLERANCE

func fire() -> void:
	if weapon == "MOLOTOV" or PlayerWeapons.family(weapon) == "THROW": throw_weapon(); return
	if reload_remaining > 0: return
	if not PlayerWeapons.is_gun(weapon):
		melee()
		return
	if ammo <= 0:
		cooldown = WeaponsSettings.EMPTY_TRIGGER_INTERVAL
		status.text = "Empty. Throw it, grab another weapon, or use F to punch."
		return
	ammo -= 1
	attack_is_melee = false
	attack_duration = PlayerWeapons.animation_duration(weapon)
	attack_animation = attack_duration
	shake = EditorVisualsSettings.SHOT_SHAKE
	sound.play("shot")
	var stats := PlayerWeapons.stats(weapon)
	# Preserve small frame overshoot so automatic fire does not slow down with FPS.
	cooldown = maxf(-0.05, cooldown) + stats[3]
	var angle := player.angle_to_point(mouse_world())
	var power := 1.5 if int(stats[5]) > 1 else (1.15 if weapon in ["RIFLE", "MACHINE_GUN"] else 1.0)
	gun_recoil = power
	add_combat_effect(ray_end(player, Vector2.from_angle(angle), 18), angle, "muzzle", power)
	var pellets := clampi(int(stats[5]), 1, 32)
	for i in pellets:
		var spread: float = lerpf(-stats[6] / 2, stats[6] / 2, float(i) / (pellets - 1)) if pellets > 1 else randf_range(-stats[6] / 2, stats[6] / 2)
		fire_ray(Vector2.from_angle(angle + deg_to_rad(spread)), stats[2], stats[1])

func add_combat_effect(point: Vector2, angle: float, kind: String, power: float = 1.0) -> void:
	var duration := maxf(0.01, EditorVisualsSettings.MUZZLE_FLASH_TIME if kind == "muzzle" else EditorVisualsSettings.IMPACT_FLASH_TIME)
	if combat_effects.size() >= 96: combat_effects.pop_front()
	combat_effects.append({"pos": point, "angle": angle, "kind": kind, "power": power, "life": duration, "duration": duration})

func fire_ray(direction: Vector2, shot_range: float, damage: int) -> void:
	var endpoint := ray_end(player, direction, shot_range)
	var nearest := player.distance_to(endpoint)
	var victim: Dictionary = {}
	for enemy in enemies:
		if not enemy.alive: continue
		if enemy.pos.distance_to(player) < WeaponsSettings.GUNSHOT_HEARING_RANGE:
			enemy.alert = true
			enemy.target = player
		var projection: float = (enemy.pos - player).dot(direction)
		if projection > 0 and projection < nearest and (player + direction * projection).distance_to(enemy.pos) < EnemiesSettings.ENEMY_HIT_RADIUS:
			var lateral := (player + direction * projection).distance_squared_to(enemy.pos)
			nearest = maxf(0, projection - sqrt(maxf(0, EnemiesSettings.ENEMY_HIT_RADIUS * EnemiesSettings.ENEMY_HIT_RADIUS - lateral)))
			victim = enemy
	if not victim.is_empty():
		damage_enemy(victim, damage)
		endpoint = player + direction * nearest
	if not victim.is_empty() or nearest < shot_range - 1:
		add_combat_effect(endpoint, direction.angle(), "hit" if not victim.is_empty() else "wall")
	traces.append({"a": player + direction * minf(18.0, nearest), "b": endpoint, "duration": EditorVisualsSettings.SHOT_TRACE_TIME, "time": EditorVisualsSettings.SHOT_TRACE_TIME, "color": Color("ffe7a5")})

func _process(delta: float) -> void:
	fps_label.visible = preferences.show_fps
	fps_update_time += delta
	if fps_update_time >= EditorVisualsSettings.FPS_COUNTER_REFRESH_INTERVAL:
		fps_update_time = 0.0
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	delta = minf(delta, 0.05)
	if workshop != null: workshop.tick(delta)
	gun_recoil = move_toward(gun_recoil, 0, delta * 12)
	for effect in combat_effects: effect.life -= delta
	combat_effects = combat_effects.filter(func(effect): return effect.life > 0)
	shake = move_toward(shake, 0, delta * EditorVisualsSettings.SHAKE_DECAY)
	swing = maxf(0, swing - delta)
	for particle in particles:
		particle.pos += particle.vel * delta
		particle.vel *= exp(-EditorVisualsSettings.PARTICLE_DRAG * delta)
		particle.life -= delta
	particles = particles.filter(func(p): return p.life > 0)
	if editing:
		hud.text = "FLOOR DESIGNER   /   %d ENEMIES   /   %s" % [map.enemies.size(), "%d%% ZOOM | WHEEL + MIDDLE MOUSE" % int(editor_zoom * 100)]
		if dialog.visible:
			painting = false
			rectangle_mode = false
		if painting:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				if rectangle_mode:
					var end := mouse_cell().clamp(Vector2i.ZERO, Vector2i(Maps.WIDTH - 1, Maps.HEIGHT - 1))
					for y in range(mini(rectangle_start.y, end.y), maxi(rectangle_start.y, end.y) + 1):
						for x in range(mini(rectangle_start.x, end.x), maxi(rectangle_start.x, end.x) + 1):
							var edge := x in [mini(rectangle_start.x, end.x), maxi(rectangle_start.x, end.x)] or y in [mini(rectangle_start.y, end.y), maxi(rectangle_start.y, end.y)]
							var saved_brush := brush
							if layout_tool in ["room", "outline"] and edge: brush = 2
							if layout_tool != "outline" or edge: paint(Vector2i(x, y), false)
							brush = saved_brush
				rectangle_mode = false
				painting = false
			elif not rectangle_mode and MAP_VIEW.has_point(get_global_mouse_position()) and mouse_cell() != last_cell:
				var next := mouse_cell()
				var difference := next - last_cell
				var steps := maxi(absi(difference.x), absi(difference.y))
				for i in range(1, steps + 1):
					paint(Vector2i(Vector2(last_cell).lerp(Vector2(next), float(i) / steps).round()), Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
				last_cell = next
		queue_redraw()
		return
	update_drops(delta)
	update_look_ahead(delta, Input.is_physical_key_pressed(KEY_SHIFT) and not get_viewport().gui_get_focus_owner() is LineEdit, get_global_mouse_position())
	for trace in traces: trace.time -= delta
	traces = traces.filter(func(trace): return trace.time > 0)
	if dead or won:
		queue_redraw()
		return
	elapsed += delta
	attack_animation = maxf(0, attack_animation - delta)
	update_reload(delta)
	combo_time = maxf(0, combo_time - delta)
	if combo_time == 0: combo = 0
	aim = player.angle_to_point(mouse_world())
	var movement := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if get_viewport().gui_get_focus_owner() is LineEdit: movement = Vector2.ZERO
	var previous_position := player
	if movement.length_squared() > 0:
		var probe := player + movement.normalized() * (PlayerSettings.PLAYER_COLLISION_RADIUS + PlayerSettings.DOOR_PUSH_LOOKAHEAD)
		var door_cell := Vector2i((probe / SIZE).floor())
		if inside(door_cell) and map.cells[door_cell.y * Maps.WIDTH + door_cell.x] == 5 and not open_doors.has(door_cell):
			use_door(player, false)
	player = move_actor(player, movement.normalized() * PlayerSettings.PLAYER_SPEED * delta)
	player_moving = player.distance_to(previous_position) > 0.1
	if player_moving: player_walk += delta * EditorVisualsSettings.WALK_ANIMATION_FPS
	cooldown -= delta
	play_center = play_center.lerp(player, 1.0 - exp(-PlayerSettings.PLAY_CAMERA_FOLLOW_SPEED * delta))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and cooldown <= 0 and MAP_VIEW.has_point(get_global_mouse_position()) and inside(mouse_cell()): fire()
	var alive := 0
	for enemy in enemies:
		enemy["attack_time"] = maxf(0, enemy.get("attack_time", 0.0) - delta)
		var attack: Dictionary = EnemyWeapons.profile(enemy.get("weapon_kind", "PISTOL" if enemy.gun else "BAT"))
		enemy["moving"] = false
		if not enemy.alive: continue
		alive += 1
		enemy.stun = maxf(0, enemy.stun - delta)
		if not enemy_is_active(enemy):
			enemy["attack_time"] = 0.0
			enemy.alert = false
			continue
		if enemy.stun > 0: continue
		var distance: float = enemy.pos.distance_to(player)
		var facing: float = Vector2.from_angle(enemy.angle).dot(enemy.pos.direction_to(player))
		var sees: bool = distance < EnemiesSettings.ENEMY_SIGHT_RANGE and (enemy.alert or distance < EnemiesSettings.ENEMY_CLOSE_DETECTION_RANGE or facing > EnemiesSettings.ENEMY_VISION_DOT) and visible_between(enemy.pos, player)
		if sees:
			enemy.alert = true
			enemy.target = player
		if enemy.alert:
			enemy.angle = enemy.pos.angle_to_point(enemy.target)
			if distance > (minf(EnemiesSettings.ENEMY_SHOOT_DISTANCE, attack.range * 0.8) if enemy.gun else minf(EnemiesSettings.ENEMY_MELEE_STOP_DISTANCE, attack.range * 0.8)) or not sees:
				pursue(enemy, delta)
			if sees and enemy.gun and distance <= attack.range:
				enemy.timer -= delta
				if enemy.timer <= 0:
					enemy_attack(enemy, attack)
			elif sees and not enemy.gun and distance < attack.range:
				enemy.timer -= delta
				if enemy.timer <= 0: enemy_attack(enemy, attack)
			else: enemy.timer = EnemiesSettings.ENEMY_REACTION_TIME
	update_projectiles(delta)
	update_fires(delta)
	hud.text = "%s %s  /  %06d PTS %s  /  %.1fs  /  HP %d" % [weapon, ("RELOADING %.1f" % reload_remaining) if reload_remaining > 0 else ("%d rounds | %d mags + %d spare" % [ammo, reserve_ammo / maxi(1, int(PlayerWeapons.stats(weapon)[0])), reserve_ammo % maxi(1, int(PlayerWeapons.stats(weapon)[0]))] if PlayerWeapons.is_gun(weapon) else ""), score, ("x%d" % combo) if combo > 1 else "", elapsed, health]
	if dead: status.text = "DOWN. Press R to retry, or TAB to adjust the map."
	elif alive == 0 and player.distance_to(center(map.exit)) < WorldSettings.EXIT_RADIUS:
		won = true
		status.text = "FLOOR CLEARED. R to replay, TAB to keep building."
	elif reload_remaining > 0: status.text = "Reloading. Keep moving and use cover."
	elif PlayerWeapons.is_gun(weapon) and ammo == 0: status.text = "EMPTY / R reload, RMB throw, E pick up, F melee."
	elif nearest_door(player).x >= 0: status.text = "DOOR / Walk to push open. Space: kick open or close."
	else: status.text = "%d enemies remaining  /  Clear the floor, then reach EXIT." % alive
	queue_redraw()

func enemy_is_active(enemy: Dictionary) -> bool:
	return enemy.get("active", not EnemiesSettings.ENEMIES_INACTIVE)

func enemy_attack(enemy: Dictionary, attack: Dictionary) -> void:
	if not enemy_is_active(enemy): return
	attack = attack.duplicate()
	attack.damage = enemy.get("damage_override", attack.damage)
	enemy.timer = maxf(0.05, attack.interval)
	enemy["attack_time"] = maxf(0.01, EnemiesSettings.ENEMY_ATTACK_ANIMATION_TIME)
	if not attack.ranged:
		if enemy.pos.distance_to(player) <= attack.range and visible_between(enemy.pos, player): damage_player(attack.damage)
		sound.play("swing")
		return
	var angle: float = enemy.pos.angle_to_point(player)
	add_combat_effect(ray_end(enemy.pos, Vector2.from_angle(angle), 18), angle, "muzzle", 1.3 if attack.pellets > 1 else 0.8)
	for i in attack.pellets:
		var spread: float = lerpf(-attack.spread / 2, attack.spread / 2, float(i) / (attack.pellets - 1)) if attack.pellets > 1 else randf_range(-attack.spread / 2, attack.spread / 2)
		var speed: float = maxf(1, attack.speed)
		projectiles.append({"pos": enemy.pos, "vel": Vector2.from_angle(angle + deg_to_rad(spread)) * speed, "life": attack.range / speed, "damage": attack.damage, "thrown": false})
	sound.play("shot")

func rebuild_navigation() -> void:
	navigation.region = Rect2i(0, 0, Maps.WIDTH, Maps.HEIGHT)
	navigation.cell_size = Vector2(SIZE, SIZE)
	navigation.offset = Vector2.ONE * SIZE / 2
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for y in Maps.HEIGHT:
		for x in Maps.WIDTH:
			var tile: int = map.cells[y * Maps.WIDTH + x]
			var blocked := not Maps.floor_tile(tile) and tile != 5
			if workshop != null and workshop.is_solid(Vector2(x, y) * SIZE + Vector2.ONE * SIZE / 2): blocked = true
			navigation.set_point_solid(Vector2i(x, y), blocked)

func pursue(enemy: Dictionary, delta: float) -> void:
	if not enemy_is_active(enemy): return
	var previous_position: Vector2 = enemy.pos
	enemy.repath -= delta
	if enemy.repath <= 0:
		var start := Vector2i(enemy.pos / SIZE)
		var end := Vector2i(enemy.target / SIZE)
		if inside(start) and inside(end) and not navigation.is_point_solid(start) and not navigation.is_point_solid(end):
			enemy.path = navigation.get_point_path(start, end)
		enemy.repath = EnemiesSettings.PATH_REFRESH_TIME
	if enemy.path.size() > 1:
		var target: Vector2 = enemy.path[1]
		if enemy.pos.distance_to(target) < EnemiesSettings.PATH_ARRIVAL_DISTANCE:
			enemy.path.remove_at(0)
		else:
			use_door(enemy.pos, false)
			enemy.angle = enemy.pos.angle_to_point(target)
			enemy.pos = move_actor(enemy.pos, enemy.pos.direction_to(target) * (EnemiesSettings.ENEMY_GUN_SPEED if enemy.gun else EnemiesSettings.ENEMY_MELEE_SPEED) * delta, EnemiesSettings.ENEMY_COLLISION_RADIUS)
	elif enemy.pos.distance_to(enemy.target) > EnemiesSettings.PATH_ARRIVAL_DISTANCE:
		enemy.pos = move_actor(enemy.pos, enemy.pos.direction_to(enemy.target) * (EnemiesSettings.ENEMY_GUN_SPEED if enemy.gun else EnemiesSettings.ENEMY_MELEE_SPEED) * delta, EnemiesSettings.ENEMY_COLLISION_RADIUS)
	enemy["moving"] = enemy.pos.distance_to(previous_position) > 0.1

func nearest_door(position: Vector2, closed_only: bool = false) -> Vector2i:
	var cell := Vector2i((position / SIZE).floor())
	var closest := Vector2i(-1, -1)
	var distance := PlayerSettings.DOOR_INTERACT_DISTANCE
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var target: Vector2i = cell + offset
		if not inside(target) or map.cells[target.y * Maps.WIDTH + target.x] != 5: continue
		if closed_only and open_doors.has(target): continue
		var candidate := position.distance_to(Vector2(target) * SIZE + Vector2.ONE * SIZE / 2)
		if candidate < distance:
			closest = target
			distance = candidate
	return closest

func use_door(position: Vector2, kick: bool) -> void:
	var target := nearest_door(position, not kick)
	if target.x < 0: return
	if open_doors.has(target):
		# Never close a door on an actor standing in its opening.
		var opening := door_leaf_rect(target).grow(maxf(PlayerSettings.PLAYER_COLLISION_RADIUS, EnemiesSettings.ENEMY_COLLISION_RADIUS) + WorldSettings.DOOR_CLOSE_CLEARANCE)
		if opening.has_point(player): return
		for enemy in enemies:
			if enemy.alive and opening.has_point(enemy.pos): return
		open_doors.erase(target)
	else:
		open_doors[target] = true
		if kick:
			shake = EditorVisualsSettings.DOOR_SHAKE
			for enemy in enemies:
				if enemy.alive and enemy.pos.distance_to(Vector2(target) * SIZE + Vector2.ONE * SIZE / 2.0) < WorldSettings.DOOR_STUN_RANGE:
					enemy.stun = WeaponsSettings.STUN_DURATION
	sound.play("door")

func door_leaf_rect(cell: Vector2i) -> Rect2:
	var origin := Vector2(cell) * SIZE
	var thickness: float = WorldSettings.DOOR_LEAF_THICKNESS
	if door_is_vertical(cell):
		return Rect2(origin + Vector2((SIZE - thickness) / 2.0, 0), Vector2(thickness, SIZE))
	return Rect2(origin + Vector2(0, (SIZE - thickness) / 2.0), Vector2(SIZE, thickness))

func door_is_vertical(cell: Vector2i) -> bool:
	return wall_at(cell + Vector2i.UP) or wall_at(cell + Vector2i.DOWN)

func draw_door(cell: Vector2i) -> void:
	var vertical := door_is_vertical(cell)
	var opened := not editing and open_doors.has(cell)
	var position := Vector2(cell) * SIZE
	var hinge := position + (Vector2(SIZE / 2.0, 0) if vertical else Vector2(0, SIZE / 2.0))
	var angle := PI / 2 if vertical else 0.0
	if opened: angle -= PI / 2
	# Full door texture and matching orientation span the actual doorway.
	sprite("door", hinge, angle, SIZE / 32.0, 0, Vector2(0, 2))

func melee() -> void:
	if reload_remaining > 0: return
	if not PlayerWeapons.is_melee(weapon):
		punch_step = (punch_step + 1) % 4 if elapsed - punch_last_time < WeaponsSettings.PUNCH_COMBO_WINDOW else 0
		punch_last_time = elapsed
	cooldown = PlayerWeapons.animation_duration(weapon, true)
	swing = WeaponsSettings.MELEE_FLASH_TIME
	attack_is_melee = true
	attack_duration = PlayerWeapons.animation_duration(weapon, true)
	if not PlayerWeapons.is_melee(weapon):
		attack_duration = maxf(0.08, WeaponsSettings.PUNCH_UPPERCUT_INTERVAL if punch_step == 3 else (WeaponsSettings.PUNCH_HOOK_INTERVAL if punch_step == 2 else WeaponsSettings.PUNCH_JAB_INTERVAL))
		cooldown = attack_duration
	attack_animation = attack_duration
	sound.play("swing")
	var direction := Vector2.from_angle(aim)
	for enemy in enemies:
		if not enemy.alive: continue
		var distance: float = player.distance_to(enemy.pos)
		if distance < (WeaponsSettings.PLAYER_KNIFE_RANGE if PlayerWeapons.family(weapon) == "KNIFE" else (WeaponsSettings.PLAYER_PIPE_RANGE if PlayerWeapons.family(weapon) == "PIPE" else (WeaponsSettings.BAT_RANGE if PlayerWeapons.is_melee(weapon) else WeaponsSettings.PUNCH_RANGE))) and direction.dot(player.direction_to(enemy.pos)) > WeaponsSettings.MELEE_ARC_DOT and visible_between(player, enemy.pos):
			if not PlayerWeapons.is_melee(weapon):
				add_combat_effect(enemy.pos, aim, "punch", 1.8 if punch_step == 3 else 1.0)
				var push := 0.0 if not enemy_is_active(enemy) else (WeaponsSettings.UPPERCUT_KNOCKBACK if punch_step == 3 else WeaponsSettings.PUNCH_KNOCKBACK)
				for step in int(ceil(clampf(push, 0, 100) / 2.0)):
					enemy.pos = move_actor(enemy.pos, direction * minf(2, push), EnemiesSettings.ENEMY_COLLISION_RADIUS)
					push -= 2
			if PlayerWeapons.is_melee(weapon) or enemy.stun > 0 or punch_step == 3:
				damage_enemy(enemy, WeaponsSettings.BAT_DAMAGE if PlayerWeapons.is_melee(weapon) else WeaponsSettings.FINISHER_DAMAGE)
			else:
				enemy.stun = WeaponsSettings.STUN_DURATION
				enemy.timer = EnemiesSettings.ENEMY_REACTION_TIME
				sound.play("hit")
				shake = EditorVisualsSettings.HIT_SHAKE

func kill_enemy(enemy: Dictionary) -> void:
	if not enemy.alive: return
	enemy.alive = false
	var kind: String = enemy.get("weapon_kind", "PISTOL" if enemy.gun else "BAT")
	if EnemiesSettings.ENEMIES_DROP_WEAPONS and kind != "FISTS":
		spawn_drop(enemy.pos, kind, mini(WeaponsSettings.DROPPED_PISTOL_AMMO, int(PlayerWeapons.stats(kind)[0])) if PlayerWeapons.is_gun(kind) else 0, player.direction_to(enemy.pos) * WeaponsSettings.DROP_TOSS_SPEED)
	combo += 1
	combo_time = WorldSettings.COMBO_WINDOW
	score += WorldSettings.KILL_SCORE * combo
	shake = EditorVisualsSettings.HIT_SHAKE
	sound.play("hit")
	spawn_blood(enemy.pos)

func spawn_blood(point: Vector2) -> void:
	if not EditorVisualsSettings.BLOOD_ENABLED: return
	for i in EditorVisualsSettings.HIT_PARTICLE_COUNT:
		var direction := Vector2.from_angle(randf() * TAU)
		particles.append({"pos": point, "vel": direction * randf_range(EditorVisualsSettings.PARTICLE_MIN_SPEED, EditorVisualsSettings.PARTICLE_MAX_SPEED), "life": randf_range(EditorVisualsSettings.PARTICLE_MIN_LIFE, EditorVisualsSettings.PARTICLE_MAX_LIFE)})
		stains.append({"pos": point + direction * randf_range(EditorVisualsSettings.BLOOD_MIN_OFFSET, EditorVisualsSettings.BLOOD_MAX_OFFSET), "size": randf_range(EditorVisualsSettings.BLOOD_MIN_SIZE, EditorVisualsSettings.BLOOD_MAX_SIZE)})

	if stains.size() > EditorVisualsSettings.MAX_BLOOD_STAINS: stains = stains.slice(stains.size() - EditorVisualsSettings.MAX_BLOOD_STAINS)

func starting_reserve(kind: String) -> int:
	return int(PlayerWeapons.stats(kind)[0]) * maxi(0, WeaponsSettings.START_RESERVE_MAGAZINES) if PlayerWeapons.is_gun(kind) else 0

func spawn_drop(point: Vector2, kind: String, rounds: int, velocity := Vector2.ZERO, reserve: int = -1) -> void:
	if kind == "FISTS": return
	drops.append({"pos": point, "weapon": kind, "ammo": rounds, "reserve": starting_reserve(kind) if reserve < 0 else reserve, "vel": velocity, "angle": randf_range(-PI, PI)})

func update_drops(delta: float) -> void:
	for item in drops:
		var velocity: Vector2 = item.get("vel", Vector2.ZERO)
		var steps := maxi(1, int(ceil(velocity.length() * delta / 2.0)))
		for i in steps:
			var point: Vector2 = item.pos
			var step := velocity * delta / steps
			if solid(point + Vector2(step.x, 0)): velocity.x *= -clampf(WeaponsSettings.DROP_BOUNCE, 0, 1)
			else: point.x += step.x
			if solid(point + Vector2(0, step.y)): velocity.y *= -clampf(WeaponsSettings.DROP_BOUNCE, 0, 1)
			else: point.y += step.y
			item.pos = point
		item["angle"] = item.get("angle", 0.0) + velocity.length() * delta * 0.02
		item["vel"] = velocity * exp(-maxf(0.1, WeaponsSettings.DROP_FRICTION) * delta)

func draw_drops() -> void:
	for item in drops:
		var phase: float = Time.get_ticks_msec() * 0.001 * WeaponsSettings.DROP_BOB_SPEED + item.pos.x * 0.07
		draw_circle(item.pos + Vector2(0, 4), 7, Color(0, 0, 0, 0.45))
		draw_circle(item.pos, WeaponsSettings.PICKUP_GLOW_RADIUS, Color(1, 0.85, 0.4, 0.16))
		var point: Vector2 = item.pos + Vector2(0, sin(phase) * WeaponsSettings.DROP_BOB_HEIGHT - 3)
		var angle: float = item.get("angle", 0.0) + deg_to_rad(sin(phase) * WeaponsSettings.DROP_SWAY_DEGREES)
		sprite("pickup_" + item.weapon, point, angle, WeaponsSettings.WEAPON_SPRITE_SCALE * WeaponsSettings.DROP_PICKUP_SCALE, int(phase) if item.weapon == "MOLOTOV" else PlayerWeapons.drop_frame(item.weapon))

func pickup() -> void:
	var nearest := -1
	var distance := PlayerSettings.PICKUP_RANGE
	for i in drops.size():
		var candidate: float = player.distance_to(drops[i].pos)
		if candidate < distance and visible_between(player, drops[i].pos):
			nearest = i
			distance = candidate
	if nearest < 0: return
	var item: Dictionary = drops.pop_at(nearest)
	if weapon != "FISTS": spawn_drop(player, weapon, ammo, Vector2.from_angle(aim) * WeaponsSettings.DROP_TOSS_SPEED, reserve_ammo)
	attack_animation = 0.0
	attack_is_melee = false
	swing = 0.0
	weapon = item.weapon
	ammo = item.ammo
	reserve_ammo = item.get("reserve", 0)
	reload_remaining = 0
	sound.play("pickup")

func throw_weapon() -> void:
	if weapon == "FISTS": return
	attack_animation = 0.0
	attack_is_melee = false
	swing = 0.0
	projectiles.append({"pos": player, "vel": Vector2.from_angle(aim) * (WeaponsSettings.MOLOTOV_THROW_SPEED if weapon == "MOLOTOV" else WeaponsSettings.THROW_SPEED), "life": WeaponsSettings.MOLOTOV_FLIGHT_TIME if weapon == "MOLOTOV" else WeaponsSettings.THROW_LIFETIME, "thrown": true, "weapon": weapon, "ammo": ammo, "reserve": reserve_ammo})
	weapon = "FISTS"
	ammo = 0
	reload_remaining = 0
	sound.play("swing")

func update_projectiles(delta: float) -> void:
	for bullet in projectiles:
		bullet.life -= delta
		var steps := maxi(1, int(ceil(bullet.vel.length() * delta / maxf(0.1, WorldSettings.PROJECTILE_COLLISION_STEP))))
		for i in steps:
			var next: Vector2 = bullet.pos + bullet.vel * delta / steps
			if solid(next):
				if not bullet.thrown: add_combat_effect(bullet.pos, bullet.vel.angle(), "wall")
				bullet.life = 0
				break
			bullet.pos = next
			if bullet.thrown:
				for enemy in enemies:
					if enemy.alive and enemy.pos.distance_to(next) < WeaponsSettings.THROW_HIT_RADIUS:
						enemy.stun = WeaponsSettings.STUN_DURATION
						enemy.timer = EnemiesSettings.ENEMY_REACTION_TIME
						if PlayerWeapons.family(bullet.weapon) == "THROW": damage_enemy(enemy, WeaponsSettings.THROW_WEAPON_DAMAGE)
						bullet.life = 0
						sound.play("hit")
						break
			elif player.distance_to(next) < PlayerSettings.PLAYER_HIT_RADIUS:
				damage_player(bullet.get("damage", EnemiesSettings.ENEMY_BULLET_DAMAGE))
				add_combat_effect(next, bullet.vel.angle(), "hit")
				bullet.life = 0
			if bullet.life <= 0: break
		if bullet.life <= 0 and bullet.thrown:
			if bullet.weapon == "MOLOTOV": ignite(bullet.pos)
			else: spawn_drop(bullet.pos, bullet.weapon, bullet.ammo, -bullet.vel.normalized() * WeaponsSettings.DROP_TOSS_SPEED * WeaponsSettings.DROP_BOUNCE, bullet.get("reserve", 0))
	projectiles = projectiles.filter(func(b): return b.life > 0)

func ignite(point: Vector2) -> void:
	if solid(point): return
	if fires.size() >= maxi(1, WeaponsSettings.MOLOTOV_MAX_FIRES): fires.pop_front()
	fires.append({"pos": point, "life": WeaponsSettings.MOLOTOV_BURN_TIME, "tick": 0.0, "age": 0.0})
	sound.play("hit")

func update_fires(delta: float) -> void:
	for fire_patch in fires:
		fire_patch.life -= delta
		fire_patch.age += delta
		if fire_patch.life <= 0: continue
		fire_patch.tick -= delta
		if fire_patch.tick > 0: continue
		fire_patch.tick = maxf(0.05, WeaponsSettings.MOLOTOV_DAMAGE_INTERVAL)
		for enemy in enemies:
			if enemy.alive and fire_patch.pos.distance_to(enemy.pos) <= WeaponsSettings.MOLOTOV_FIRE_RADIUS and visible_between(fire_patch.pos, enemy.pos): damage_enemy(enemy, WeaponsSettings.MOLOTOV_DAMAGE)
		if WeaponsSettings.MOLOTOV_HURTS_PLAYER and not dead and fire_patch.pos.distance_to(player) <= WeaponsSettings.MOLOTOV_FIRE_RADIUS and visible_between(fire_patch.pos, player): damage_player(WeaponsSettings.MOLOTOV_DAMAGE)
	fires = fires.filter(func(patch): return patch.life > 0)

func draw_fires() -> void:
	for fire_patch in fires:
		if fire_patch.age < 0.3:
			sprite("fire_burst", fire_patch.pos, 0, WeaponsSettings.WEAPON_SPRITE_SCALE, int(fire_patch.age * 30))
		# Sample the patch against walls so flames cannot be drawn in neighboring rooms.
		for y in range(-2, 3):
			for x in range(-2, 3):
				var point: Vector2 = fire_patch.pos + Vector2(x, y) * WeaponsSettings.MOLOTOV_FIRE_RADIUS / 2.5
				if fire_patch.pos.distance_to(point) > WeaponsSettings.MOLOTOV_FIRE_RADIUS or solid(point) or not visible_between(fire_patch.pos, point): continue
				sprite("fire", point, 0, WeaponsSettings.MOLOTOV_FIRE_RADIUS / 100.0, int(fire_patch.age * 12) + x + y)

func die() -> void:
	if dead: return
	dead = true
	spawn_blood(player)
	if weapon != "FISTS": spawn_drop(player, weapon, ammo, Vector2.from_angle(aim) * WeaponsSettings.DROP_TOSS_SPEED, reserve_ammo)
	weapon = "FISTS"
	ammo = 0
	reload_remaining = 0
	shake = EditorVisualsSettings.DEATH_SHAKE
	sound.play("death")

func damage_enemy(enemy: Dictionary, amount: int) -> void:
	if not enemy.alive or amount <= 0: return
	enemy.health -= amount
	if enemy.health <= 0: kill_enemy(enemy)
	else:
		spawn_blood(enemy.pos)
		enemy.alert = true
		enemy.target = player
		sound.play("hit")

func damage_player(amount: int) -> void:
	if dead or amount <= 0: return
	health -= amount
	shake = EditorVisualsSettings.HIT_SHAKE
	if health <= 0: die()
	else: spawn_blood(player); sound.play("hit")

func start_reload() -> void:
	if not PlayerWeapons.is_gun(weapon) or reload_remaining > 0 or ammo >= int(PlayerWeapons.stats(weapon)[0]) or reserve_ammo <= 0: return
	reload_remaining = PlayerWeapons.stats(weapon)[4]
	reload_duration = reload_remaining
	sound.play("pickup")

func update_reload(delta: float) -> void:
	if reload_remaining <= 0: return
	reload_remaining = maxf(0, reload_remaining - delta)
	if reload_remaining == 0:
		var amount := mini(maxi(0, int(PlayerWeapons.stats(weapon)[0]) - ammo), reserve_ammo)
		ammo += amount
		reserve_ammo -= amount
		sound.play("pickup")

func sprite(key: String, position: Vector2, angle: float = 0.0, scale_value: float = 1.0, index: int = 0, pivot: Vector2 = Vector2(-1, -1), mirrored := false) -> void:
	var texture: Texture2D = art.frame(key, index)
	if texture == null: return
	if pivot.x < 0: pivot = texture.get_size() / 2
	draw_set_transform(render_origin + position * view_zoom, angle, Vector2(1, -1 if mirrored else 1) * scale_value * view_zoom)
	draw_texture(texture, -pivot)
	draw_set_transform(render_origin, 0, Vector2.ONE * view_zoom)

func enemy_asset_has_gun(asset: String) -> bool:
	for token in ["Gun", "M16", "Shotgun", "DoubleBarrel", "Silencer", "Uzi"]:
		if token in asset: return true
	return false

func draw_enemy_appearance(asset: String, point: Vector2, angle: float, moving: bool, attacking: float = 0.0, alive: bool = true) -> bool:
	if not alive:
		var corpse: String = preload("res://scripts/rendering/enemy_appearance.gd").death_asset(asset)
		if not workshop.metadata.has(corpse): return false
		var body := Maps.prop(corpse, point, EditorVisualsSettings.ACTOR_SPRITE_SCALE, 1, false, int(workshop.metadata[corpse].frames) - 1)
		body.rotation = rad_to_deg(angle)
		workshop.draw_item(body)
		return true
	if not workshop.metadata.has(asset): return false
	# Prefer the matching walking sheet when available; attacks remain in the library.
	var walking := asset.replace("Attack", "Walk").replace("Search", "Walk")
	var stem := walking.get_slice("_strip", 0)
	for suffix in ["_strip8.png", "_strip16.png"]:
		if workshop.metadata.has(stem + suffix): asset = stem + suffix; break
	if attacking > 0:
		var attack_stem := asset.get_file().get_slice("_strip", 0).replace("Walk", "Attack").replace("Search", "Attack")
		for candidate in workshop.metadata:
			if candidate.get_base_dir() == asset.get_base_dir() and candidate.get_file().get_slice("_strip", 0) == attack_stem:
				asset = candidate; break
	sprite("enemy_legs", point, angle, EditorVisualsSettings.ACTOR_SPRITE_SCALE, int(elapsed * EditorVisualsSettings.WALK_ANIMATION_FPS) if moving else 0)
	var item := Maps.prop(asset, point, EditorVisualsSettings.ACTOR_SPRITE_SCALE, 1, false)
	item.rotation = rad_to_deg(angle)
	item.frame = mini(int(workshop.metadata[asset].frames) - 1, int((1.0 - attacking / maxf(0.01, EnemiesSettings.ENEMY_ATTACK_ANIMATION_TIME)) * workshop.metadata[asset].frames)) if attacking > 0 else (int(elapsed * EditorVisualsSettings.WALK_ANIMATION_FPS) if moving else 0)
	workshop.draw_item(item)
	return true

func draw_actor(position: Vector2, angle: float, is_player: bool, held_weapon: String, alive: bool = true, stunned: bool = false, moving: bool = false) -> void:
	var prefix := "player" if is_player else "enemy"
	if not alive or stunned:
		sprite(prefix + "_dead", position, angle, EditorVisualsSettings.ACTOR_SPRITE_SCALE, 3 if not alive else 0)
		return
	var walk_frame := int(player_walk if is_player else elapsed * EditorVisualsSettings.WALK_ANIMATION_FPS) if moving else 0
	sprite(prefix + "_legs", position, angle, EditorVisualsSettings.ACTOR_SPRITE_SCALE, walk_frame)
	var key := prefix + ("_gun" if PlayerWeapons.is_gun(held_weapon) else "_bat")
	if is_player: key = PlayerWeapons.held_sprite(held_weapon)
	var index := (walk_frame / 2) % 8 if is_player else walk_frame % 8
	if is_player and attack_animation > 0:
		key = PlayerWeapons.held_sprite("FISTS" if PlayerWeapons.is_gun(held_weapon) and attack_is_melee else held_weapon, true)
		index = mini(art.frames[key].size() - 1, int((1.0 - attack_animation / maxf(0.01, attack_duration)) * art.frames[key].size()))
	# Gun sprites extend right from the body; bat sprites extend below it.
	var pivot := Vector2(16, 16)
	if not is_player and PlayerWeapons.is_gun(held_weapon): pivot = Vector2(16, 12)
	if is_player: pivot = art.actor_origin(key, index)
	var body_angle := angle
	if is_player and PlayerWeapons.custom_held(held_weapon) and PlayerWeapons.is_melee(held_weapon) and attack_animation > 0:
		var progress := 1.0 - attack_animation / maxf(0.01, attack_duration)
		body_angle += sin(progress * TAU) * 0.85
	if is_player and PlayerWeapons.is_gun(held_weapon) and not attack_is_melee:
		position -= Vector2.from_angle(angle) * gun_recoil * EditorVisualsSettings.GUN_RECOIL_PIXELS
	var mirrored := false
	if is_player and key == "player_punch" and attack_is_melee and attack_animation > 0:
		var progress := clampf(1.0 - attack_animation / maxf(0.01, attack_duration), 0, 1)
		var pose := CombatVisuals.punch_pose(maxi(0, punch_step), progress)
		body_angle += pose.angle
		position += Vector2(pose.lean, 0).rotated(angle)
		mirrored = pose.mirrored
		index = pose.frame
		pivot = art.actor_origin(key, index)
	sprite(key, position, body_angle, EditorVisualsSettings.ACTOR_SPRITE_SCALE, index, pivot, mirrored)
	if is_player and PlayerWeapons.custom_held(held_weapon):
		var weapon_angle := body_angle
		sprite("pickup_" + held_weapon, position + Vector2(14, 5).rotated(weapon_angle), weapon_angle, WeaponsSettings.WEAPON_SPRITE_SCALE, int(elapsed * 12) if held_weapon == "MOLOTOV" else PlayerWeapons.drop_frame(held_weapon))

var floor_material_textures: Dictionary = {}

func draw_floor(rectangle: Rect2, tile: int) -> void:
	if not rectangle.has_area(): return
	if not floor_material_textures.has(tile):
		# Extract once so the GPU can repeat the material without sampling other atlas tiles.
		var image: Image = art.textures.floors.get_image()
		floor_material_textures[tile] = ImageTexture.create_from_image(image.get_region(Rect2i(art.floor_region(tile))))
	var scale_value := maxf(0.1, EditorVisualsSettings.FLOOR_TEXTURE_SCALE)
	draw_texture_rect_region(floor_material_textures[tile], rectangle, Rect2(rectangle.position / scale_value, rectangle.size / scale_value), Color.WHITE, false, false)

func wall_at(cell: Vector2i) -> bool:
	return inside(cell) and map.cells[cell.y * Maps.WIDTH + cell.x] == 2

func wall_connects(cell: Vector2i) -> bool:
	return inside(cell) and map.cells[cell.y * Maps.WIDTH + cell.x] in [2, 5]

func wall_segments(cell: Vector2i) -> Array[Rect2]:
	return WallGeometry.segments(map, cell, WorldSettings.WALL_THICKNESS)

func structural_floor(cell: Vector2i, quadrant: Vector2) -> int:
	var point := Vector2(cell) + quadrant
	var best := INF
	var material := 0
	for y in range(cell.y - 2, cell.y + 3):
		for x in range(cell.x - 2, cell.x + 3):
			var neighbor := Vector2i(x, y)
			if not inside(neighbor): continue
			var tile: int = map.cells[y * Maps.WIDTH + x]
			if not Maps.floor_tile(tile) and tile != 0: continue
			var distance := point.distance_squared_to(Vector2(neighbor) + Vector2.ONE * 0.5)
			if distance < best:
				best = distance
				material = tile
	return material

func structural_floor_rect(cell: Vector2i) -> Rect2:
	var origin := Vector2(cell) * SIZE
	var low := origin
	var high := origin + Vector2.ONE * SIZE
	var midpoint := origin + Vector2.ONE * SIZE / 2.0
	# Floor ends at the wall centerline on an exterior side. The wall itself
	# covers the seam; no half-cell strip can remain outside the building.
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + direction
		if inside(neighbor) and map.cells[neighbor.y * Maps.WIDTH + neighbor.x] != 0: continue
		if direction == Vector2i.LEFT: low.x = midpoint.x
		if direction == Vector2i.RIGHT: high.x = midpoint.x
		if direction == Vector2i.UP: low.y = midpoint.y
		if direction == Vector2i.DOWN: high.y = midpoint.y
	return Rect2(low, high - low)

func floor_rect(cell: Vector2i) -> Rect2:
	var index := cell.y * Maps.WIDTH + cell.x
	var clip: Array = map.get("floor_clips", {}).get(str(index), [])
	if clip.size() == 4:
		return Rect2(Vector2(cell) * SIZE + Vector2(clip[0], clip[1]) * SIZE, Vector2(clip[2], clip[3]) * SIZE)
	if map.cells[index] in [2, 5]: return structural_floor_rect(cell)
	return Rect2(Vector2(cell) * SIZE, Vector2.ONE * SIZE)

func floor_regions(cell: Vector2i) -> Array[Rect2]:
	var index := cell.y * Maps.WIDTH + cell.x
	var origin := Vector2(cell) * SIZE
	var result: Array[Rect2] = []
	var saved: Dictionary = map.get("floor_shapes", {})
	if saved.has(str(index)):
		for shape in saved[str(index)]:
			result.append(Rect2(origin + Vector2(shape[0], shape[1]) * SIZE, Vector2(shape[2], shape[3]) * SIZE))
		return result
	var bounds := floor_rect(cell)
	if not map.cells[index] in [2, 5]:
		if bounds.has_area(): result.append(bounds)
		return result
	# Each corner is bounded independently. A diagonal void between two wall
	# neighbors is outside the room even though neither cardinal cell is empty.
	for y in 2:
		for x in 2:
			var dx := -1 if x == 0 else 1
			var dy := -1 if y == 0 else 1
			var diagonal := cell + Vector2i(dx, dy)
			var diagonal_empty: bool = not inside(diagonal) or map.cells[diagonal.y * Maps.WIDTH + diagonal.x] == 0
			if diagonal_empty and wall_connects(cell + Vector2i(dx, 0)) and wall_connects(cell + Vector2i(0, dy)): continue
			var piece := bounds.intersection(Rect2(origin + Vector2(x, y) * SIZE / 2.0, Vector2.ONE * SIZE / 2.0))
			if piece.has_area(): result.append(piece)
	return result

func draw_structural_floor(cell: Vector2i) -> void:
	var material: int = map.floors[cell.y * Maps.WIDTH + cell.x]
	if material != 0:
		for rectangle in floor_regions(cell): draw_floor(rectangle, material)

var wall_fill_cache: Dictionary = {}
var wall_outline_cache: Dictionary = {}
var wall_outline_hash := 0
var wall_outline_builds := 0
var fps_label: Label
var fps_update_time := 0.0

func draw_wall(_rectangle: Rect2, cell: Vector2i) -> void:
	if not wall_fill_cache.has(cell):
		var commands: Array = []
		for segment in wall_segments(cell):
			var vertical := segment.size.y > segment.size.x
			var texture: Texture2D = art.frame("wall_v" if vertical else "wall")
			var native := texture.get_size()
			var scale_value := WorldSettings.WALL_THICKNESS / (native.x if vertical else native.y)
			var period := (native.y if vertical else native.x) * scale_value
			var start := segment.position.y if vertical else segment.position.x
			var finish := segment.end.y if vertical else segment.end.x
			var cursor := start
			while cursor < finish:
				var phase := fposmod(cursor, period)
				var length := minf(finish - cursor, period - phase)
				var target := Rect2(Vector2(segment.position.x, cursor), Vector2(segment.size.x, length)) if vertical else Rect2(Vector2(cursor, segment.position.y), Vector2(length, segment.size.y))
				var source := Rect2(Vector2(0, phase / scale_value), Vector2(native.x, length / scale_value)) if vertical else Rect2(Vector2(phase / scale_value, 0), Vector2(length / scale_value, native.y))
				# Use the texture interior; its baked edge stripes would make false
				# end caps at every L/T junction. Outline the joined wall below.
				if vertical:
					source.position.x += 2
					source.size.x -= 4
				else:
					source.position.y += 2
					source.size.y -= 4
				commands.append([texture, target, source])
				cursor += length
		wall_fill_cache[cell] = commands
	for command in wall_fill_cache[cell]:
		draw_texture_rect_region(command[0], command[1], command[2])
	if not wall_outline_cache.has(cell):
		wall_outline_builds += 1
		var edges: Array = []
		for segment in wall_segments(cell):
			for side in 4:
				var horizontal := side < 2
				var normal: Vector2 = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][side]
				var start := segment.position
				if side == 1: start.y = segment.end.y
				if side == 3: start.x = segment.end.x
				var tangent := Vector2.RIGHT if horizontal else Vector2.DOWN
				var extent := segment.size.x if horizontal else segment.size.y
				var run_start := -1
				for offset in range(int(ceil(extent)) + 1):
					var exposed := offset < int(ceil(extent)) and not wall_geometry_at(start + tangent * (offset + 0.5) + normal * 0.1)
					if exposed and run_start < 0: run_start = offset
					if not exposed and run_start >= 0:
						edges.append([start + tangent * run_start - normal * 0.5, start + tangent * minf(offset, extent) - normal * 0.5])
						run_start = -1
		wall_outline_cache[cell] = edges
	for edge in wall_outline_cache[cell]: draw_line(edge[0], edge[1], Color("ffffff"), 1.0)

func wall_geometry_at(point: Vector2) -> bool:
	var cell := Vector2i((point / SIZE).floor())
	if not inside(cell): return false
	var tile: int = map.cells[cell.y * Maps.WIDTH + cell.x]
	if tile == 5: return door_leaf_rect(cell).has_point(point)
	if tile != 2: return false
	for segment in wall_segments(cell):
		if segment.has_point(point): return true
	return false

var furniture_rects: Array[Rect2] = []
var furniture_hash := 0

func draw_furniture() -> void:
	if furniture_hash != wall_outline_hash:
		furniture_hash = wall_outline_hash
		furniture_rects.clear()
		for y in Maps.HEIGHT:
			var x := 0
			while x < Maps.WIDTH:
				if map.cells[y * Maps.WIDTH + x] != 6:
					x += 1
					continue
				var length := 1
				while x + length < Maps.WIDTH and map.cells[y * Maps.WIDTH + x + length] == 6: length += 1
				furniture_rects.append(Rect2(Vector2(x, y) * SIZE + Vector2(1, 2), Vector2(length * SIZE - 2, SIZE - 4)))
				x += length
	for rectangle in furniture_rects:
		draw_rect(Rect2(rectangle.position + Vector2(2, 3), rectangle.size), Color(0, 0, 0, 0.4))
		draw_texture_rect(art.frame("sofa"), rectangle, false)

var draw_cpu_us := 0

func _draw() -> void:
	var draw_started := Time.get_ticks_usec()
	var geometry_hash: int = hash([map.cells, WorldSettings.WALL_THICKNESS, WorldSettings.DOOR_LEAF_THICKNESS])
	if geometry_hash != wall_outline_hash:
		wall_outline_hash = geometry_hash
		wall_outline_cache.clear()
		wall_fill_cache.clear()
	var canvas_width := MAP_VIEW.end.x + 32.0
	draw_rect(Rect2(0, 0, canvas_width, 1080), EditorVisualsSettings.EDITOR_CANVAS_COLOR)
	if canvas_width < 1920: draw_rect(Rect2(canvas_width, 0, 1920 - canvas_width, 1080), Color("101725"))
	var jitter := Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) * EditorVisualsSettings.SCREEN_SHAKE_SCALE if not editing and preferences.screen_shake else Vector2.ZERO
	view_zoom = camera_zoom()
	render_origin = MAP_VIEW.get_center() - camera_center() * view_zoom + jitter
	if editing and preferences.editor_grid:
		var grid_color: Color = EditorVisualsSettings.EDITOR_GRID_COLOR
		grid_color.a *= preferences.grid_opacity
		var spacing := SIZE * view_zoom
		var offset := Vector2(fposmod(render_origin.x, spacing), fposmod(render_origin.y, spacing))
		for x in range(int(canvas_width / spacing) + 2):
			draw_line(Vector2(offset.x + x * spacing, 0), Vector2(offset.x + x * spacing, 1080), grid_color, 1)
		for y in range(int(1080 / spacing) + 2):
			draw_line(Vector2(0, offset.y + y * spacing), Vector2(canvas_width, offset.y + y * spacing), grid_color, 1)
	draw_set_transform(render_origin, 0, Vector2.ONE * view_zoom)
	if editing: draw_rect(Rect2(Vector2.ZERO, Vector2(Maps.WIDTH, Maps.HEIGHT) * SIZE), Color("60e4dc"), false, 1.0 / view_zoom)
	# The expanded canvas should cost only what is currently on screen.
	var visible_start := Vector2i(((MAP_VIEW.position - render_origin) / view_zoom / SIZE).floor()) - Vector2i.ONE
	var visible_end := Vector2i(((MAP_VIEW.end - render_origin) / view_zoom / SIZE).ceil()) + Vector2i.ONE
	var floor_shapes: Dictionary = map.get("floor_shapes", {})
	var floor_clips: Dictionary = map.get("floor_clips", {})
	var end_x := mini(Maps.WIDTH, visible_end.x)
	for y in range(maxi(0, visible_start.y), mini(Maps.HEIGHT, visible_end.y)):
		var x := maxi(0, visible_start.x)
		while x < end_x:
			var index := y * Maps.WIDTH + x
			var tile: int = map.cells[index]
			var rectangle := Rect2(Vector2(x, y) * SIZE, Vector2.ONE * SIZE)
			# Only merge plain, identical floor cells. Saved cutouts retain their exact geometry.
			if tile in [1, 3, 4] and not (editing and show_grid) and not floor_shapes.has(str(index)) and not floor_clips.has(str(index)):
				var finish := x + 1
				while finish < end_x:
					var next_index := y * Maps.WIDTH + finish
					if map.cells[next_index] != tile or floor_shapes.has(str(next_index)) or floor_clips.has(str(next_index)): break
					finish += 1
				rectangle.size.x = (finish - x) * SIZE
				draw_floor(rectangle, tile)
				x = finish
				continue
			if tile == 0:
				if not editing: draw_rect(rectangle, EditorVisualsSettings.EDITOR_CANVAS_COLOR)
			elif tile in [2, 5]:
				draw_structural_floor(Vector2i(x, y))
			else:
				for floor_piece in floor_regions(Vector2i(x, y)):
					draw_floor(floor_piece, tile if tile in [1, 3, 4] else 1)
			if editing and show_grid: draw_rect(rectangle, Color(0.6, 0.7, 0.9, 0.12), false)
			x += 1
	if workshop != null: workshop.draw_layer(0)
	# Floor artwork stays underneath structural walls and interactive doors.
	for y in range(maxi(0, visible_start.y), mini(Maps.HEIGHT, visible_end.y)):
		for x in range(maxi(0, visible_start.x), mini(Maps.WIDTH, visible_end.x)):
			var structural_tile: int = map.cells[y * Maps.WIDTH + x]
			if structural_tile == 2:
				draw_wall(Rect2(Vector2(x, y) * SIZE, Vector2.ONE * SIZE), Vector2i(x, y))
			elif structural_tile == 5:
				draw_door(Vector2i(x, y))
	draw_furniture()
	if workshop != null: workshop.draw_layer(1)
	if not editing:
		for stain in stains:
			sprite("blood", stain.pos, 0, EditorVisualsSettings.BLOOD_SPRITE_SCALE, int(stain.size) % 8)
	var exit_position := center(map.exit)
	draw_rect(Rect2(exit_position - Vector2(12, 12), Vector2(24, 24)), Color("50dca0"), false, 2)
	sprite("exit", exit_position, 0, EditorVisualsSettings.EXIT_SPRITE_SCALE, int(elapsed * EditorVisualsSettings.EXIT_ANIMATION_FPS) % 4)
	if editing:
		draw_actor(center(map.spawn), 0, true, PlayerSettings.START_WEAPON)
		for i in map.enemies.size():
			var coordinate: Array = map.enemies[i]
			var asset: String = map.get("enemy_styles", {}).get("%d,%d" % [coordinate[0], coordinate[1]], "")
			if not draw_enemy_appearance(asset, center(coordinate), PI, false): draw_actor(center(coordinate), PI, false, "PISTOL" if i % 3 != 1 else "BAT")
		if preferences.highlight_cell and inside(mouse_cell()): draw_rect(Rect2(Vector2(mouse_cell()) * SIZE, Vector2.ONE * SIZE), Color("ffe7a5"), false, 2)
		if rectangle_mode:
			var end := mouse_cell().clamp(Vector2i.ZERO, Vector2i(Maps.WIDTH - 1, Maps.HEIGHT - 1))
			var start := Vector2i(mini(rectangle_start.x, end.x), mini(rectangle_start.y, end.y))
			var extent := Vector2i(absi(end.x - rectangle_start.x) + 1, absi(end.y - rectangle_start.y) + 1)
			draw_rect(Rect2(Vector2(start) * SIZE, Vector2(extent) * SIZE), Color(0.4, 1, 0.9, 0.2))
	else:
		for enemy in enemies:
			if not draw_enemy_appearance(enemy.get("appearance", ""), enemy.pos, enemy.angle, enemy.get("moving", false), enemy.get("attack_time", 0.0), enemy.alive):
				draw_actor(enemy.pos, enemy.angle, false, "PISTOL" if enemy.gun else "BAT", enemy.alive, enemy.stun > 0, enemy.get("moving", false))
			if enemy.alive and enemy.stun > 0:
				draw_arc(enemy.pos, 16, elapsed * 5, elapsed * 5 + PI, 16, Color("60e4dc"), 3)
			elif enemy.alive and enemy.alert and enemy.gun and enemy_is_active(enemy):
				draw_arc(enemy.pos, 15, -PI / 2, -PI / 2 + TAU * clampf(1 - enemy.timer / EnemiesSettings.ENEMY_REACTION_TIME, 0, 1), 20, Color("ffe7a5"), 2)
		draw_actor(player, player.angle_to_point(mouse_world()), true, weapon, not dead, false, player_moving)
		draw_fires()
		draw_drops() # Above corpses and actors so pickups stay readable.
		for bullet in projectiles:
			if bullet.thrown:
				sprite("pickup_" + bullet.weapon, bullet.pos, elapsed * WeaponsSettings.THROW_SPIN_SPEED, WeaponsSettings.WEAPON_SPRITE_SCALE, int(elapsed * 12) if bullet.weapon == "MOLOTOV" else PlayerWeapons.drop_frame(bullet.weapon))
			else: CombatVisuals.draw_projectile(self, bullet.pos, bullet.vel)
		for particle in particles: draw_circle(particle.pos, 2, Color("f34b78"))
		if inside(mouse_cell()): sprite("cursor", mouse_world(), 0, 0.75)
		for trace in traces: CombatVisuals.draw_trace(self, trace)
		for effect in combat_effects: CombatVisuals.draw_effect(self, effect)
		if reload_remaining > 0 and not dead:
			CombatVisuals.draw_magazine(self, player + Vector2(22, -12), 1.0 - reload_remaining / maxf(0.01, reload_duration))
		if dead or won:
			draw_rect(Rect2(0, 240, Maps.WIDTH * SIZE, 100), Color(0.02, 0.03, 0.06, 0.9))
			draw_string(ThemeDB.fallback_font, Vector2(270, 300), "FLOOR CLEARED" if won else "DOWN / R TO RETRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("60e4dc") if won else Color("ff547b"))
	if workshop != null:
		workshop.draw_layer(2)
		workshop.draw_tools()
	draw_set_transform(Vector2.ZERO)
	# Mask the world to the map panel; UI children are drawn above these panels.
	draw_rect(Rect2(0, 0, canvas_width, MAP_VIEW.position.y), Color("090a12"))
	draw_rect(Rect2(0, MAP_VIEW.end.y, canvas_width, 1080 - MAP_VIEW.end.y), Color("090a12"))
	draw_rect(Rect2(0, MAP_VIEW.position.y, MAP_VIEW.position.x, MAP_VIEW.size.y), Color("090a12"))
	draw_rect(Rect2(MAP_VIEW.end.x, MAP_VIEW.position.y, 32, MAP_VIEW.size.y), Color("090a12"))
	if canvas_width < 1920: draw_rect(Rect2(canvas_width, 0, 1920 - canvas_width, 1080), Color("101725"))
	draw_rect(MAP_VIEW.grow(1), Color("293746"), false, 1)

	draw_cpu_us = Time.get_ticks_usec() - draw_started
