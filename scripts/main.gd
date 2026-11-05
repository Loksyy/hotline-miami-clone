extends Node2D

const WallGeometry = preload("res://scripts/rendering/wall_geometry.gd")
const Maps = preload("res://scripts/map_data.gd")
const ORIGIN := Vector2(32, 108)
const SIZE := 28
const S = preload("res://scripts/game_settings.gd")
const Art = preload("res://scripts/game_art.gd")
var art := Art.new()
var render_origin := ORIGIN
const MAP_VIEW := Rect2(32, 108, 1216, 940)
var editor_zoom := S.EDITOR_DEFAULT_ZOOM
var editor_center := Vector2(448, 308)
var play_center := Vector2.ZERO
var view_zoom := 1.0
var show_grid := S.EDITOR_GRID_VISIBLE
var player_walk := 0.0
var player_moving := false
var attack_animation := 0.0
const Sound = preload("res://scripts/sound.gd")
var sound: Node
var navigation := AStarGrid2D.new()
var open_doors: Dictionary = {}
var drops: Array = []
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
const Preferences = preload("res://scripts/runtime_settings.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
var preferences := Preferences.new()
var pause_menu: CanvasLayer
const Workshop = preload("res://scripts/asset_workshop.gd")
var workshop: Node

func _ready() -> void:
	preferences.load_settings()
	Maps.ensure_floor_layer(map)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	fps_label = label_at("FPS: --", Vector2(1710, 76), 18)
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_label = label_at("FLOOR DESIGNER", Vector2(420, 30), 18)
	mode_label.hide()
	hud = label_at("AFTER HOURS / 1989   •   DESIGN YOUR WAY IN", Vector2(32, 66), 17)
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
	if history.size() > S.UNDO_LIMIT:
		history.pop_front()
	future.clear()

func undo() -> void:
	if not editing or history.is_empty(): return
	future.append(map.duplicate(true))
	map = history.pop_back()
	if workshop != null: workshop.selected = -1; workshop.selected_terrain = Vector2i(-1, -1); workshop.dragging = false
	title_input.text = map.name
	queue_redraw()

func redo() -> void:
	if not editing or future.is_empty(): return
	history.append(map.duplicate(true))
	map = future.pop_back()
	if workshop != null: workshop.selected = -1; workshop.selected_terrain = Vector2i(-1, -1); workshop.dragging = false
	title_input.text = map.name
	queue_redraw()

func replace_map(value: Dictionary) -> void:
	if not editing: return
	snapshot()
	map = value
	Maps.ensure_floor_layer(map)
	if workshop != null: workshop.selected = -1; workshop.selected_terrain = Vector2i(-1, -1); workshop.dragging = false
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
		if file.get_length() > S.MAX_MAP_FILE_BYTES:
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
	player_walk = 0
	player_moving = false
	attack_animation = 0
	open_doors.clear()
	drops.clear()
	projectiles.clear()
	particles.clear()
	stains.clear()
	weapon = S.START_WEAPON
	ammo = S.MAGAZINE_SIZE if weapon == "PISTOL" else 0
	reserve_ammo = S.START_RESERVE_AMMO
	reload_remaining = 0
	health = S.PLAYER_HEALTH
	score = 0
	combo = 0
	combo_time = 0
	elapsed = 0
	shake = 0
	swing = 0
	rebuild_navigation()
	player = center(map.spawn)
	play_center = player
	enemies.clear()
	for cell in map.enemies:
		enemies.append({"pos": center(cell), "alive": true, "health": S.ENEMY_HEALTH, "angle": PI, "alert": false, "timer": S.ENEMY_REACTION_TIME, "stun": 0.0, "path": PackedVector2Array(), "repath": randf() * S.PATH_REFRESH_TIME, "target": center(cell), "gun": enemies.size() % 3 != 1})
	dead = false
	won = false
	cooldown = 0
	traces.clear()
	queue_redraw()

func mouse_cell() -> Vector2i:
	return Vector2i((mouse_world() / SIZE).floor())

func camera_zoom() -> float:
	return editor_zoom if editing else S.PLAY_CAMERA_ZOOM

func camera_center() -> Vector2:
	return editor_center if editing else play_center

func screen_to_world(point: Vector2) -> Vector2:
	return (point - MAP_VIEW.get_center()) / camera_zoom() + camera_center()

func mouse_world() -> Vector2:
	return screen_to_world(get_global_mouse_position())

func zoom_at(point: Vector2, factor: float) -> void:
	var anchor := screen_to_world(point)
	editor_zoom = clampf(editor_zoom * factor, S.EDITOR_MIN_ZOOM, S.EDITOR_MAX_ZOOM)
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
		if tile in [0, 1, 3, 4]: map.floors[cell.y * Maps.WIDTH + cell.x] = tile
		if not (tile in [0, 1, 3, 4] and map.cells[cell.y * Maps.WIDTH + cell.x] in [2, 5, 6]):
			map.cells[cell.y * Maps.WIDTH + cell.x] = tile
	elif tool == 6:
		if coordinate in map.enemies: map.enemies.erase(coordinate)
		elif coordinate == map.spawn or coordinate == map.exit:
			status.text = "Move the player start or exit before deleting its floor."
		else:
			var index := cell.y * Maps.WIDTH + cell.x
			if map.cells[index] in [2, 5, 6]: map.cells[index] = int(map.floors[index])
			else: map.cells[index] = 0; map.floors[index] = 0
	else:
		if not Maps.floor_tile(map.cells[cell.y * Maps.WIDTH + cell.x]):
			status.text = "Entities need a floor tile."
			return
		if coordinate == map.spawn or coordinate == map.exit or coordinate in map.enemies: return
		if tool == 3: map.spawn = coordinate
		if tool == 4 and map.enemies.size() < S.MAX_ENEMIES: map.enemies.append(coordinate)
		if tool == 5: map.exit = coordinate
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if dialog.visible: return
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
			zoom_at(event.position, S.EDITOR_ZOOM_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / S.EDITOR_ZOOM_STEP)
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_mode()
		elif event.keycode == KEY_M:
			sound.muted = not sound.muted
		elif editing:
			if event.keycode == KEY_G: show_grid = not show_grid
			elif event.keycode == KEY_HOME:
				editor_center = Vector2(448, 308)
				editor_zoom = 1.0
			elif event.ctrl_pressed and event.keycode == KEY_Z: undo()
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

func can_stand(point: Vector2) -> bool:
	# Include center and edge midpoints: corners alone miss thin walls/doors.
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		if solid(point + offset * S.PLAYER_COLLISION_RADIUS): return false
	return true

func move_actor(position: Vector2, velocity: Vector2) -> Vector2:
	var steps := maxi(1, int(ceil(velocity.length() / 2.0)))
	var step := velocity / steps
	for i in steps:
		if can_stand(position + Vector2(step.x, 0)): position.x += step.x
		if can_stand(position + Vector2(0, step.y)): position.y += step.y
	return position

func ray_end(start: Vector2, direction: Vector2, distance: float) -> Vector2:
	var point := start
	for i in int(ceil(distance / 3.0)):
		point = start + direction * minf((i + 1) * 3.0, distance)
		if solid(point): return point
	return point

func visible_between(a: Vector2, b: Vector2) -> bool:
	return ray_end(a, a.direction_to(b), a.distance_to(b)).distance_to(b) < 4

func fire() -> void:
	if reload_remaining > 0: return
	if weapon == "FISTS" or weapon == "BAT":
		melee()
		return
	if ammo <= 0:
		cooldown = S.EMPTY_TRIGGER_INTERVAL
		status.text = "Empty. Throw it, grab another weapon, or use F to punch."
		return
	ammo -= 1
	attack_animation = S.ATTACK_ANIMATION_TIME
	shake = S.SHOT_SHAKE
	sound.play("shot")
	cooldown = S.FIRE_INTERVAL
	var direction := player.direction_to(mouse_world())
	var endpoint := ray_end(player, direction, S.SHOT_RANGE)
	var nearest := player.distance_to(endpoint)
	var victim: Dictionary = {}
	for enemy in enemies:
		if not enemy.alive: continue
		if enemy.pos.distance_to(player) < S.GUNSHOT_HEARING_RANGE:
			enemy.alert = true
			enemy.target = player
		var projection: float = (enemy.pos - player).dot(direction)
		if projection > 0 and projection < nearest and (player + direction * projection).distance_to(enemy.pos) < S.ENEMY_HIT_RADIUS:
			nearest = projection
			victim = enemy
	if not victim.is_empty():
		damage_enemy(victim, S.SHOT_DAMAGE)
		endpoint = player + direction * nearest
	traces.append({"a": player, "b": endpoint, "time": S.SHOT_TRACE_TIME, "color": Color("ffe7a5")})

func _process(delta: float) -> void:
	fps_label.visible = preferences.show_fps
	fps_update_time += delta
	if fps_update_time >= S.FPS_COUNTER_REFRESH_INTERVAL:
		fps_update_time = 0.0
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	delta = minf(delta, 0.05)
	if workshop != null: workshop.tick(delta)
	shake = move_toward(shake, 0, delta * S.SHAKE_DECAY)
	swing = maxf(0, swing - delta)
	for particle in particles:
		particle.pos += particle.vel * delta
		particle.vel *= 0.85
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
	var previous_position := player
	if movement.length_squared() > 0:
		var probe := player + movement.normalized() * (S.PLAYER_COLLISION_RADIUS + 12)
		var door_cell := Vector2i((probe / SIZE).floor())
		if inside(door_cell) and map.cells[door_cell.y * Maps.WIDTH + door_cell.x] == 5 and not open_doors.has(door_cell):
			use_door(player, false)
	player = move_actor(player, movement.normalized() * S.PLAYER_SPEED * delta)
	player_moving = player.distance_to(previous_position) > 0.1
	if player_moving: player_walk += delta * S.WALK_ANIMATION_FPS
	cooldown -= delta
	play_center = play_center.lerp(player, 1.0 - exp(-S.PLAY_CAMERA_FOLLOW_SPEED * delta))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and cooldown <= 0 and MAP_VIEW.has_point(get_global_mouse_position()) and inside(mouse_cell()): fire()
	var alive := 0
	for enemy in enemies:
		enemy["moving"] = false
		if not enemy.alive: continue
		alive += 1
		enemy.stun = maxf(0, enemy.stun - delta)
		if enemy.stun > 0: continue
		var distance: float = enemy.pos.distance_to(player)
		var facing: float = Vector2.from_angle(enemy.angle).dot(enemy.pos.direction_to(player))
		var sees: bool = distance < S.ENEMY_SIGHT_RANGE and (enemy.alert or distance < S.ENEMY_CLOSE_DETECTION_RANGE or facing > S.ENEMY_VISION_DOT) and visible_between(enemy.pos, player)
		if sees:
			enemy.alert = true
			enemy.target = player
		if enemy.alert:
			enemy.angle = enemy.pos.angle_to_point(enemy.target)
			if distance > (S.ENEMY_SHOOT_DISTANCE if enemy.gun else S.ENEMY_MELEE_STOP_DISTANCE) or not sees:
				pursue(enemy, delta)
			if sees and enemy.gun:
				enemy.timer -= delta
				if enemy.timer <= 0:
					projectiles.append({"pos": enemy.pos, "vel": enemy.pos.direction_to(player) * S.ENEMY_BULLET_SPEED, "life": S.ENEMY_BULLET_LIFETIME, "thrown": false})
					sound.play("shot")
					enemy.timer = S.ENEMY_FIRE_INTERVAL
			elif sees and distance < S.ENEMY_MELEE_RANGE:
				enemy.timer -= delta
				if enemy.timer <= 0:
					damage_player(S.ENEMY_DAMAGE)
					enemy.timer = S.ENEMY_MELEE_INTERVAL
			else: enemy.timer = S.ENEMY_REACTION_TIME
	update_projectiles(delta)
	hud.text = "%s %s  /  %06d PTS %s  /  %.1fs  /  HP %d" % [weapon, ("RELOADING %.1f" % reload_remaining) if reload_remaining > 0 else ("%d / %d" % [ammo, reserve_ammo] if weapon == "PISTOL" else ""), score, ("x%d" % combo) if combo > 1 else "", elapsed, health]
	if dead: status.text = "DOWN. Press R to retry, or TAB to adjust the map."
	elif alive == 0 and player.distance_to(center(map.exit)) < S.EXIT_RADIUS:
		won = true
		status.text = "FLOOR CLEARED. R to replay, TAB to keep building."
	elif reload_remaining > 0: status.text = "Reloading. Keep moving and use cover."
	elif weapon == "PISTOL" and ammo == 0: status.text = "EMPTY / R reload, RMB throw, E pick up, F melee."
	elif nearest_door(player).x >= 0: status.text = "DOOR / Walk to push open. Space: kick open or close."
	else: status.text = "%d enemies remaining  /  Clear the floor, then reach EXIT." % alive
	queue_redraw()

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
	var previous_position: Vector2 = enemy.pos
	enemy.repath -= delta
	if enemy.repath <= 0:
		var start := Vector2i(enemy.pos / SIZE)
		var end := Vector2i(enemy.target / SIZE)
		if inside(start) and inside(end) and not navigation.is_point_solid(start) and not navigation.is_point_solid(end):
			enemy.path = navigation.get_point_path(start, end)
		enemy.repath = S.PATH_REFRESH_TIME
	if enemy.path.size() > 1:
		var target: Vector2 = enemy.path[1]
		if enemy.pos.distance_to(target) < S.PATH_ARRIVAL_DISTANCE:
			enemy.path.remove_at(0)
		else:
			use_door(enemy.pos, false)
			enemy.angle = enemy.pos.angle_to_point(target)
			enemy.pos = move_actor(enemy.pos, enemy.pos.direction_to(target) * (S.ENEMY_GUN_SPEED if enemy.gun else S.ENEMY_MELEE_SPEED) * delta)
	elif enemy.pos.distance_to(enemy.target) > S.PATH_ARRIVAL_DISTANCE:
		enemy.pos = move_actor(enemy.pos, enemy.pos.direction_to(enemy.target) * (S.ENEMY_GUN_SPEED if enemy.gun else S.ENEMY_MELEE_SPEED) * delta)
	enemy["moving"] = enemy.pos.distance_to(previous_position) > 0.1

func nearest_door(position: Vector2, closed_only: bool = false) -> Vector2i:
	var cell := Vector2i((position / SIZE).floor())
	var closest := Vector2i(-1, -1)
	var distance := S.DOOR_INTERACT_DISTANCE
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
		var opening := door_leaf_rect(target).grow(S.PLAYER_COLLISION_RADIUS + 0.5)
		if opening.has_point(player): return
		for enemy in enemies:
			if enemy.alive and opening.has_point(enemy.pos): return
		open_doors.erase(target)
	else:
		open_doors[target] = true
		if kick:
			shake = S.DOOR_SHAKE
			for enemy in enemies:
				if enemy.alive and enemy.pos.distance_to(Vector2(target) * SIZE + Vector2.ONE * 14) < S.DOOR_STUN_RANGE:
					enemy.stun = S.STUN_DURATION
	sound.play("door")

func door_leaf_rect(cell: Vector2i) -> Rect2:
	var origin := Vector2(cell) * SIZE
	var thickness: float = S.DOOR_LEAF_THICKNESS
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
	cooldown = S.MELEE_INTERVAL
	swing = S.MELEE_FLASH_TIME
	attack_animation = S.ATTACK_ANIMATION_TIME
	sound.play("swing")
	var direction := Vector2.from_angle(aim)
	for enemy in enemies:
		if not enemy.alive: continue
		var distance: float = player.distance_to(enemy.pos)
		if distance < (S.BAT_RANGE if weapon == "BAT" else S.PUNCH_RANGE) and direction.dot(player.direction_to(enemy.pos)) > S.MELEE_ARC_DOT and visible_between(player, enemy.pos):
			if weapon == "BAT" or enemy.stun > 0:
				damage_enemy(enemy, S.BAT_DAMAGE if weapon == "BAT" else S.FINISHER_DAMAGE)
			else:
				enemy.stun = S.STUN_DURATION
				enemy.timer = S.ENEMY_REACTION_TIME
				sound.play("hit")
				shake = S.HIT_SHAKE

func kill_enemy(enemy: Dictionary) -> void:
	if not enemy.alive: return
	enemy.alive = false
	drops.append({"pos": enemy.pos, "weapon": "PISTOL" if enemy.gun else "BAT", "ammo": mini(S.DROPPED_PISTOL_AMMO, S.MAGAZINE_SIZE)})
	combo += 1
	combo_time = S.COMBO_WINDOW
	score += S.KILL_SCORE * combo
	shake = S.HIT_SHAKE
	sound.play("hit")
	if not S.BLOOD_ENABLED: return
	for i in S.HIT_PARTICLE_COUNT:
		var direction := Vector2.from_angle(randf() * TAU)
		particles.append({"pos": enemy.pos, "vel": direction * randf_range(S.PARTICLE_MIN_SPEED, S.PARTICLE_MAX_SPEED), "life": randf_range(S.PARTICLE_MIN_LIFE, S.PARTICLE_MAX_LIFE)})
		stains.append({"pos": enemy.pos + direction * randf_range(2, 22), "size": randf_range(2, 7)})

func pickup() -> void:
	var nearest := -1
	var distance := S.PICKUP_RANGE
	for i in drops.size():
		var candidate: float = player.distance_to(drops[i].pos)
		if candidate < distance and visible_between(player, drops[i].pos):
			nearest = i
			distance = candidate
	if nearest < 0: return
	var item: Dictionary = drops.pop_at(nearest)
	if weapon != "FISTS": drops.append({"pos": player, "weapon": weapon, "ammo": ammo})
	weapon = item.weapon
	ammo = item.ammo
	reload_remaining = 0
	sound.play("pickup")

func throw_weapon() -> void:
	if weapon == "FISTS": return
	projectiles.append({"pos": player, "vel": Vector2.from_angle(aim) * S.THROW_SPEED, "life": S.THROW_LIFETIME, "thrown": true, "weapon": weapon, "ammo": ammo})
	weapon = "FISTS"
	ammo = 0
	reload_remaining = 0
	sound.play("swing")

func update_projectiles(delta: float) -> void:
	for bullet in projectiles:
		bullet.life -= delta
		var steps := maxi(1, int(ceil(bullet.vel.length() * delta / 4)))
		for i in steps:
			var next: Vector2 = bullet.pos + bullet.vel * delta / steps
			if solid(next):
				bullet.life = 0
				break
			bullet.pos = next
			if bullet.thrown:
				for enemy in enemies:
					if enemy.alive and enemy.pos.distance_to(next) < S.THROW_HIT_RADIUS:
						enemy.stun = S.STUN_DURATION
						enemy.timer = S.ENEMY_REACTION_TIME
						bullet.life = 0
						sound.play("hit")
						break
			elif player.distance_to(next) < S.PLAYER_HIT_RADIUS:
				damage_player(S.ENEMY_DAMAGE)
				bullet.life = 0
			if bullet.life <= 0: break
		if bullet.life <= 0 and bullet.thrown:
			drops.append({"pos": bullet.pos, "weapon": bullet.weapon, "ammo": bullet.ammo})
	projectiles = projectiles.filter(func(b): return b.life > 0)

func die() -> void:
	if dead: return
	dead = true
	shake = S.DEATH_SHAKE
	sound.play("death")

func damage_enemy(enemy: Dictionary, amount: int) -> void:
	enemy.health -= amount
	if enemy.health <= 0: kill_enemy(enemy)
	else:
		enemy.alert = true
		enemy.target = player
		sound.play("hit")

func damage_player(amount: int) -> void:
	if dead: return
	health -= amount
	shake = S.HIT_SHAKE
	if health <= 0: die()
	else: sound.play("hit")

func start_reload() -> void:
	if weapon != "PISTOL" or reload_remaining > 0 or ammo >= S.MAGAZINE_SIZE or reserve_ammo <= 0: return
	reload_remaining = S.RELOAD_TIME
	sound.play("pickup")

func update_reload(delta: float) -> void:
	if reload_remaining <= 0: return
	reload_remaining = maxf(0, reload_remaining - delta)
	if reload_remaining == 0:
		var amount := mini(S.MAGAZINE_SIZE - ammo, reserve_ammo)
		ammo += amount
		reserve_ammo -= amount
		sound.play("pickup")

func sprite(key: String, position: Vector2, angle: float = 0.0, scale_value: float = 1.0, index: int = 0, pivot: Vector2 = Vector2(-1, -1)) -> void:
	var texture: Texture2D = art.frame(key, index)
	if texture == null: return
	if pivot.x < 0: pivot = texture.get_size() / 2
	draw_set_transform(render_origin + position * view_zoom, angle, Vector2.ONE * scale_value * view_zoom)
	draw_texture(texture, -pivot)
	draw_set_transform(render_origin, 0, Vector2.ONE * view_zoom)

func draw_actor(position: Vector2, angle: float, is_player: bool, held_weapon: String, alive: bool = true, stunned: bool = false, moving: bool = false) -> void:
	var prefix := "player" if is_player else "enemy"
	if not alive or stunned:
		sprite(prefix + "_dead", position, angle, S.ACTOR_SPRITE_SCALE, 3 if not alive else 0)
		return
	var walk_frame := int(player_walk if is_player else elapsed * S.WALK_ANIMATION_FPS) if moving else 0
	sprite(prefix + "_legs", position, angle, S.ACTOR_SPRITE_SCALE, walk_frame)
	var key := prefix + ("_gun" if held_weapon == "PISTOL" else "_bat")
	if is_player and held_weapon == "FISTS": key = "player_fists"
	var index := walk_frame % 8
	if is_player and attack_animation > 0:
		key = "player_shoot" if held_weapon == "PISTOL" and swing <= 0 else ("player_swing" if held_weapon == "BAT" else "player_punch")
		index = mini(art.frames[key].size() - 1, int((1.0 - attack_animation / S.ATTACK_ANIMATION_TIME) * art.frames[key].size()))
	# Gun sprites extend right from the body; bat sprites extend below it.
	var pivot := Vector2(16, 16)
	if not is_player and held_weapon == "PISTOL": pivot = Vector2(16, 12)
	if key in ["player_swing", "player_punch"]: pivot = art.frame(key).get_size() / 2
	sprite(key, position, angle, S.ACTOR_SPRITE_SCALE, index, pivot)

func draw_floor(rectangle: Rect2, tile: int) -> void:
	# Clip a world-aligned repeating material at cell boundaries, never stretch
	# a complete texture into a cell. Neighboring cells share the same phase.
	var region: Rect2 = art.floor_region(tile)
	var scale_value := maxf(0.1, S.FLOOR_TEXTURE_SCALE)
	var period := region.size * scale_value
	var first := (rectangle.position / period).floor() * period
	var y := first.y
	while y < rectangle.end.y:
		var x := first.x
		while x < rectangle.end.x:
			var patch := Rect2(Vector2(x, y), period).intersection(rectangle)
			var source := Rect2(region.position + (patch.position - Vector2(x, y)) / scale_value, patch.size / scale_value)
			draw_texture_rect_region(art.textures.floors, patch, source)
			x += period.x
		y += period.y

func wall_at(cell: Vector2i) -> bool:
	return inside(cell) and map.cells[cell.y * Maps.WIDTH + cell.x] == 2

func wall_connects(cell: Vector2i) -> bool:
	return inside(cell) and map.cells[cell.y * Maps.WIDTH + cell.x] in [2, 5]

func wall_segments(cell: Vector2i) -> Array[Rect2]:
	return WallGeometry.segments(map, cell, S.WALL_THICKNESS)

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

func draw_structural_floor(cell: Vector2i) -> void:
	var material: int = map.floors[cell.y * Maps.WIDTH + cell.x]
	var rectangle := structural_floor_rect(cell)
	if material != 0 and rectangle.has_area(): draw_floor(rectangle, material)

var wall_outline_cache: Dictionary = {}
var wall_outline_hash := 0
var wall_outline_builds := 0
var fps_label: Label
var fps_update_time := 0.0

func draw_wall(_rectangle: Rect2, cell: Vector2i) -> void:
	for segment in wall_segments(cell):
		var vertical := segment.size.y > segment.size.x
		var texture: Texture2D = art.frame("wall_v" if vertical else "wall")
		var native := texture.get_size()
		var scale_value := S.WALL_THICKNESS / (native.x if vertical else native.y)
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
			draw_texture_rect_region(texture, target, source)
			cursor += length
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
	for edge in wall_outline_cache[cell]: draw_line(edge[0], edge[1], Color("fff6d5"), 1.0)

func wall_geometry_at(point: Vector2) -> bool:
	var cell := Vector2i((point / SIZE).floor())
	if not inside(cell): return false
	var tile: int = map.cells[cell.y * Maps.WIDTH + cell.x]
	if tile == 5: return door_leaf_rect(cell).has_point(point)
	if tile != 2: return false
	for segment in wall_segments(cell):
		if segment.has_point(point): return true
	return false

func draw_furniture() -> void:
	# Adjacent sofa cells form one piece of furniture rather than tiny repeated couches.
	var used: Dictionary = {}
	for y in Maps.HEIGHT:
		for x in Maps.WIDTH:
			var cell := Vector2i(x, y)
			if map.cells[y * Maps.WIDTH + x] != 6 or used.has(cell): continue
			var length := 1
			while x + length < Maps.WIDTH and map.cells[y * Maps.WIDTH + x + length] == 6:
				length += 1
			for i in length: used[Vector2i(x + i, y)] = true
			var rectangle := Rect2(Vector2(cell) * SIZE + Vector2(1, 2), Vector2(length * SIZE - 2, SIZE - 4))
			draw_rect(Rect2(rectangle.position + Vector2(2, 3), rectangle.size), Color(0, 0, 0, 0.4))
			draw_texture_rect(art.frame("sofa"), rectangle, false)
func _draw() -> void:
	var geometry_hash: int = hash([map.cells, S.WALL_THICKNESS, S.DOOR_LEAF_THICKNESS])
	if geometry_hash != wall_outline_hash:
		wall_outline_hash = geometry_hash
		wall_outline_cache.clear()
	draw_rect(Rect2(0, 0, 1280, 1080), S.EDITOR_CANVAS_COLOR)
	draw_rect(Rect2(1280, 0, 640, 1080), Color("101725"))
	var jitter := Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) * S.SCREEN_SHAKE_SCALE if not editing and preferences.screen_shake else Vector2.ZERO
	view_zoom = camera_zoom()
	render_origin = MAP_VIEW.get_center() - camera_center() * view_zoom + jitter
	if editing:
		var spacing := SIZE * view_zoom
		var offset := Vector2(fposmod(render_origin.x, spacing), fposmod(render_origin.y, spacing))
		for x in range(int(1280 / spacing) + 2):
			draw_line(Vector2(offset.x + x * spacing, 0), Vector2(offset.x + x * spacing, 1080), S.EDITOR_GRID_COLOR, 1)
		for y in range(int(1080 / spacing) + 2):
			draw_line(Vector2(0, offset.y + y * spacing), Vector2(1280, offset.y + y * spacing), S.EDITOR_GRID_COLOR, 1)
	draw_rect(MAP_VIEW.grow(2), Color("e44a9c"), false, 2)
	draw_set_transform(render_origin, 0, Vector2.ONE * view_zoom)
	for y in Maps.HEIGHT:
		for x in Maps.WIDTH:
			var tile: int = map.cells[y * Maps.WIDTH + x]
			var rectangle := Rect2(Vector2(x, y) * SIZE, Vector2.ONE * SIZE)
			if tile == 0:
				if not editing: draw_rect(rectangle, S.EDITOR_CANVAS_COLOR)
			elif tile in [2, 5]:
				draw_structural_floor(Vector2i(x, y))
			else:
				draw_floor(rectangle, tile if tile in [1, 3, 4] else 1)
			if editing and show_grid: draw_rect(rectangle, Color(0.6, 0.7, 0.9, 0.12), false)
	if workshop != null: workshop.draw_layer(0)
	# Floor artwork stays underneath structural walls and interactive doors.
	for y in Maps.HEIGHT:
		for x in Maps.WIDTH:
			var structural_tile: int = map.cells[y * Maps.WIDTH + x]
			if structural_tile == 2:
				draw_wall(Rect2(Vector2(x, y) * SIZE, Vector2.ONE * SIZE), Vector2i(x, y))
			elif structural_tile == 5:
				draw_door(Vector2i(x, y))
	draw_furniture()
	if workshop != null: workshop.draw_layer(1)
	if not editing:
		for stain in stains:
			sprite("blood", stain.pos, 0, S.BLOOD_SPRITE_SCALE, int(stain.size) % 8)
		for item in drops:
			draw_circle(item.pos, 12, Color(1, 0.85, 0.4, 0.12 + sin(Time.get_ticks_msec() * 0.006) * 0.05))
			sprite("weapons", item.pos, 0, S.WEAPON_SPRITE_SCALE, 7 if item.weapon == "PISTOL" else 4)
	var exit_position := center(map.exit)
	draw_rect(Rect2(exit_position - Vector2(12, 12), Vector2(24, 24)), Color("50dca0"), false, 2)
	sprite("exit", exit_position, 0, 0.65, int(elapsed * 6) % 4)
	if editing:
		draw_actor(center(map.spawn), 0, true, S.START_WEAPON)
		for i in map.enemies.size(): draw_actor(center(map.enemies[i]), PI, false, "PISTOL" if i % 3 != 1 else "BAT")
		if inside(mouse_cell()): draw_rect(Rect2(Vector2(mouse_cell()) * SIZE, Vector2.ONE * SIZE), Color("ffe7a5"), false, 2)
		if rectangle_mode:
			var end := mouse_cell().clamp(Vector2i.ZERO, Vector2i(Maps.WIDTH - 1, Maps.HEIGHT - 1))
			var start := Vector2i(mini(rectangle_start.x, end.x), mini(rectangle_start.y, end.y))
			var extent := Vector2i(absi(end.x - rectangle_start.x) + 1, absi(end.y - rectangle_start.y) + 1)
			draw_rect(Rect2(Vector2(start) * SIZE, Vector2(extent) * SIZE), Color(0.4, 1, 0.9, 0.2))
	else:
		for enemy in enemies:
			draw_actor(enemy.pos, enemy.angle, false, "PISTOL" if enemy.gun else "BAT", enemy.alive, enemy.stun > 0, enemy.get("moving", false))
			if enemy.alive and enemy.stun > 0:
				draw_arc(enemy.pos, 16, elapsed * 5, elapsed * 5 + PI, 16, Color("60e4dc"), 3)
			elif enemy.alive and enemy.alert and enemy.gun:
				draw_arc(enemy.pos, 15, -PI / 2, -PI / 2 + TAU * clampf(1 - enemy.timer / S.ENEMY_REACTION_TIME, 0, 1), 20, Color("ffe7a5"), 2)
		draw_actor(player, player.angle_to_point(mouse_world()), true, weapon, not dead, false, player_moving)
		for bullet in projectiles:
			if bullet.thrown:
				sprite("weapons", bullet.pos, elapsed * 20, S.WEAPON_SPRITE_SCALE, 7 if bullet.weapon == "PISTOL" else 4)
			else: draw_line(bullet.pos, bullet.pos - bullet.vel.normalized() * 12, Color("ff718e"), 2)
		for particle in particles: draw_circle(particle.pos, 2, Color("f34b78"))
		if inside(mouse_cell()): sprite("cursor", mouse_world(), 0, 0.75)
		for trace in traces: draw_line(trace.a, trace.b, trace.color, 2)
		if dead or won:
			draw_rect(Rect2(0, 240, Maps.WIDTH * SIZE, 100), Color(0.02, 0.03, 0.06, 0.9))
			draw_string(ThemeDB.fallback_font, Vector2(270, 300), "FLOOR CLEARED" if won else "DOWN / R TO RETRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("60e4dc") if won else Color("ff547b"))
	if workshop != null:
		workshop.draw_layer(2)
		workshop.draw_tools()
	draw_set_transform(Vector2.ZERO)
	# Mask the world to the map panel; UI children are drawn above these panels.
	draw_rect(Rect2(0, 0, 1280, MAP_VIEW.position.y), Color("090a12"))
	draw_rect(Rect2(0, MAP_VIEW.end.y, 1280, 1080 - MAP_VIEW.end.y), Color("090a12"))
	draw_rect(Rect2(0, MAP_VIEW.position.y, MAP_VIEW.position.x, MAP_VIEW.size.y), Color("090a12"))
	draw_rect(Rect2(MAP_VIEW.end.x, MAP_VIEW.position.y, 32, MAP_VIEW.size.y), Color("090a12"))
	draw_rect(Rect2(1280, 0, 640, 1080), Color("101725"))
	draw_rect(MAP_VIEW.grow(2), Color("e44a9c"), false, 2)
	if editing:
		for band in 3:
			var top := PackedVector2Array()
			var bottom := PackedVector2Array()
			for x in range(0, 1281, 8):
				var wave := sin(float(x) * 0.018 + band * 0.65) * 5
				top.append(Vector2(x, 94 + wave + band * 3))
				bottom.append(Vector2(x, 1064 + wave + band * 3))
			draw_polyline(top, S.EDITOR_NEON_COLOR.darkened(band * 0.17), 2)
			draw_polyline(bottom, S.EDITOR_NEON_COLOR.darkened(band * 0.17), 2)
