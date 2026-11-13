class_name MapData
extends "res://scripts/maps/map_format.gd"
const Importer = preload("res://scripts/maps/layout_importer.gd")

static func demo() -> Dictionary:
	var map := blank()
	map.name = "01 / AFTER HOURS"
	for y in range(1, HEIGHT - 1):
		if y not in [5, 15]:
			map.cells[y * WIDTH + 11] = 2
		if y != 10:
			map.cells[y * WIDTH + 22] = 2
	for x in range(12, 22):
		if x != 16:
			map.cells[8 * WIDTH + x] = 2
	map.enemies = [[8, 4], [17, 4], [17, 14], [27, 5], [27, 17]]
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			if map.cells[y * WIDTH + x] == 1:
				map.cells[y * WIDTH + x] = 3 if x < 11 else (4 if x > 22 else 1)
	for cell in [[11, 5], [11, 15], [22, 10], [16, 8]]:
		map.cells[cell[1] * WIDTH + cell[0]] = 5
	for cell in [[4, 3], [5, 3], [6, 3], [14, 12], [14, 13], [25, 15], [26, 15]]:
		map.cells[cell[1] * WIDTH + cell[0]] = 6
	return map

static func small_blank() -> Dictionary:
	var map := blank()
	map.name = "New room / 30 x 30"
	map.cells.fill(0)
	var origin := Vector2i((WIDTH - 30) / 2, (HEIGHT - 30) / 2)
	for y in 30:
		for x in 30:
			map.cells[(origin.y + y) * WIDTH + origin.x + x] = 2 if x in [0, 29] or y in [0, 29] else 1
	map.cells[(origin.y + 29) * WIDTH + origin.x + 15] = 5
	map.spawn = [origin.x + 15, origin.y + 15]
	map.exit = [origin.x + 15, origin.y + 28]
	ensure_floor_layer(map)
	return map

static func starter() -> Dictionary:
	# Compact 40 x 28 arena inside the larger editable canvas.
	var map := blank()
	map.name = "TEST ARENA / Weapons & enemies"
	map.cells.fill(0)
	var middle := Vector2i(WIDTH / 2, HEIGHT / 2)
	var bounds := Rect2i(middle - Vector2i(20, 14), Vector2i(40, 28))
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var edge := x == bounds.position.x or x == bounds.end.x - 1 or y == bounds.position.y or y == bounds.end.y - 1
			map.cells[y * WIDTH + x] = 2 if edge else 1
	map.spawn = [middle.x, middle.y]
	map.exit = [bounds.end.x - 3, bounds.end.y - 3]
	map.enemy_styles = {}
	var appearances = preload("res://scripts/rendering/enemy_appearance.gd")
	for i in appearances.ARENA_ENEMIES.size():
		var cell := [middle.x - 16 + (i % 9) * 4, middle.y - 10 + (i / 9) * 4]
		map.enemies.append(cell)
		map.enemy_styles["%d,%d" % [cell[0], cell[1]]] = appearances.ROOT + appearances.ARENA_ENEMIES[i]
	var weapons = preload("res://scripts/game/player_weapons.gd")
	var guns: Array[String] = []
	for kind in weapons.PICKUPS:
		if weapons.is_gun(kind): guns.append(kind)
	var left := int(WIDTH / 2) - (guns.size() - 1) * 2
	for i in guns.size():
		var point := (Vector2(left + i * 4, HEIGHT / 2 + 11) + Vector2.ONE * 0.5) * TILE
		var item := prop(weapons.pickup_asset(guns[i]), point, 1.0, 1, false, weapons.drop_frame(guns[i]))
		item.pickup_kind = guns[i]
		map.objects.append(item)
	# Separate melee rows keep every pickup accessible without growing the arena.
	var melee: Array[String] = []
	for kind in weapons.PICKUPS:
		if weapons.is_melee(kind): melee.append(kind)
	for i in melee.size():
		var row := int(i / 9)
		var column := i % 9
		var point := (Vector2(middle.x - 16 + column * 4, middle.y + 2 + row * 3) + Vector2.ONE * 0.5) * TILE
		var item := prop(weapons.pickup_asset(melee[i]), point, 1.0, 1, false, weapons.drop_frame(melee[i]))
		item.pickup_kind = melee[i]
		map.objects.append(item)
	ensure_floor_layer(map)
	return map

static func ensure_floor_layer(map: Dictionary) -> void:
	if map.has("floors"): return
	var floors: Array = []
	for y in HEIGHT:
		for x in WIDTH:
			var tile: int = map.cells[y * WIDTH + x]
			if floor_tile(tile) or tile == 0:
				floors.append(tile)
				continue
			var material := 0
			var nearest := 100000
			for oy in range(-3, 4):
				for ox in range(-3, 4):
					var nx := x + ox
					var ny := y + oy
					if nx < 0 or ny < 0 or nx >= WIDTH or ny >= HEIGHT: continue
					var candidate: int = map.cells[ny * WIDTH + nx]
					var distance := ox * ox + oy * oy
					if floor_tile(candidate) and distance < nearest:
						nearest = distance
						material = candidate
			floors.append(material)
	map.floors = floors

static func _valid_cell(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for n in value:
		if not (n is int or n is float) or n != int(n):
			return false
	return value[0] >= 0 and value[0] < WIDTH and value[1] >= 0 and value[1] < HEIGHT

# Upgrade original 32x22 saves into the center of the larger canvas.
static func expand_legacy(value: Dictionary) -> Dictionary:
	if not value.get("cells") is Array or value.cells.size() != 704: return value
	var result := value.duplicate(true)
	var offset := Vector2i((WIDTH - 32) / 2, (HEIGHT - 22) / 2)
	for key in ["cells", "floors"]:
		if not result.has(key): continue
		if not result[key] is Array or result[key].size() != 704: continue
		var expanded: Array = []
		expanded.resize(WIDTH * HEIGHT)
		expanded.fill(0)
		for y in 22:
			for x in 32: expanded[(y + offset.y) * WIDTH + x + offset.x] = result[key][y * 32 + x]
		result[key] = expanded
	for key in ["spawn", "exit", "enemies"]:
		var positions: Array = result.get(key, []) if key == "enemies" else [result.get(key)]
		for cell in positions:
			if cell is Array and cell.size() == 2 and numeric(cell[0]) and numeric(cell[1]):
				cell[0] += offset.x
				cell[1] += offset.y
	for item in result.get("objects", []):
		if item is Dictionary and item.get("pos") is Array and item.pos.size() == 2 and numeric(item.pos[0]) and numeric(item.pos[1]):
			item.pos[0] += offset.x * TILE
			item.pos[1] += offset.y * TILE
	return result

static func validate(value: Variant) -> String:
	if not value is Dictionary:
		return "Map must be a JSON object."
	value = expand_legacy(value)
	for key in ["version", "name", "cells", "spawn", "enemies", "exit"]:
		if not value.has(key):
			return "Missing field: " + key
	if value.version != 1 or not value.name is String:
		return "Unsupported map version or invalid name."
	if not value.cells is Array or value.cells.size() != WIDTH * HEIGHT:
		return "Map must contain exactly %d tiles." % (WIDTH * HEIGHT)
	for cell in value.cells:
		if not (cell is int or cell is float) or cell != int(cell) or int(cell) < 0 or int(cell) > 6:
			return "Invalid tile type."
	if not value.enemies is Array or value.enemies.size() > EditorVisualsSettings.MAX_ENEMIES:
		return "Invalid enemy list (maximum %d)." % EditorVisualsSettings.MAX_ENEMIES
	var occupied: Array = []
	for cell in [value.spawn, value.exit] + value.enemies:
		if not _valid_cell(cell):
			return "Entity position is outside the map."
		if not floor_tile(int(value.cells[int(cell[1]) * WIDTH + int(cell[0])])):
			return "Spawn, exit, and enemies must be on floor tiles."
		if cell in occupied:
			return "Entity positions must not overlap."
		occupied.append(cell)
	if value.has("floors"):
		if not value.floors is Array or value.floors.size() != WIDTH * HEIGHT: return "Invalid floor layer."
		for tile in value.floors:
			if not numeric(tile) or tile != int(tile) or int(tile) not in [0, 1, 3, 4]: return "Invalid floor material."
	if value.has("enemy_options"):
		if not value.enemy_options is Dictionary: return "Invalid enemy settings."
		for key in value.enemy_options:
			var options: Variant = value.enemy_options[key]
			if not key is String or not options is Dictionary: return "Invalid enemy settings."
			if options.has("active") and not options.active is bool: return "Invalid enemy active setting."
			for field in ["health", "damage"]:
				if options.has(field) and (not numeric(options[field]) or not is_finite(float(options[field])) or options[field] != int(options[field]) or options[field] < (1 if field == "health" else 0) or options[field] > 10000): return "Invalid enemy combat value."
	if value.has("enemy_styles"):
		if not value.enemy_styles is Dictionary: return "Invalid enemy appearances."
		for key in value.enemy_styles:
			var asset: Variant = value.enemy_styles[key]
			if not key is String or not asset is String or ".." in asset: return "Invalid enemy appearance."
			if preload("res://scripts/editor/asset_categories.gd").category_for(asset) != "Enemies that are alive" or not ResourceLoader.exists("res://HLM1 Files/" + asset): return "Invalid living enemy texture."
	if value.has("floor_clips"):
		if not value.floor_clips is Dictionary: return "Invalid floor outlines."
		for key in value.floor_clips:
			if not key is String or not key.is_valid_int() or int(key) < 0 or int(key) >= WIDTH * HEIGHT: return "Invalid floor outline cell."
			var rect: Variant = value.floor_clips[key]
			if not rect is Array or rect.size() != 4: return "Invalid floor outline."
			for component in rect:
				if not numeric(component) or component < 0 or component > 1: return "Invalid floor outline bounds."
			if rect[0] + rect[2] > 1.001 or rect[1] + rect[3] > 1.001: return "Floor outline exceeds its cell."
	if value.has("floor_shapes"):
		if not value.floor_shapes is Dictionary: return "Invalid floor shapes."
		for key in value.floor_shapes:
			if not key is String or not key.is_valid_int() or int(key) < 0 or int(key) >= WIDTH * HEIGHT: return "Invalid floor shape cell."
			var pieces: Variant = value.floor_shapes[key]
			if not pieces is Array or pieces.size() > 4: return "Invalid floor shape pieces."
			for piece in pieces:
				if not piece is Array or piece.size() != 4: return "Invalid floor shape."
				for component in piece:
					if not numeric(component) or component < 0 or component > 1: return "Invalid floor shape bounds."
				if piece[0] + piece[2] > 1.001 or piece[1] + piece[3] > 1.001: return "Floor shape exceeds its cell."
	var props: Variant = value.get("objects", [])
	if not props is Array or props.size() > EditorVisualsSettings.MAX_MAP_OBJECTS: return "Invalid object list."
	for item in props:
		if not item is Dictionary: return "Invalid object."
		if item.has("pickup_kind") and not preload("res://scripts/game/player_weapons.gd").SOURCES.has(item.pickup_kind): return "Unknown weapon pickup."
		for key in ["asset", "pos", "frame", "scale", "rotation", "layer", "animated", "solid", "crop"]:
			if not item.has(key): return "Object missing field: " + key
		if not item.asset is String or item.asset.contains("..") or item.asset.begins_with("/") or item.asset.contains(":") or item.asset.contains("\\") or not item.asset.ends_with(".png"):
			return "Invalid object asset path."
		if not ResourceLoader.exists("res://HLM1 Files/" + item.asset): return "Missing object texture: " + item.asset
		if not item.pos is Array or item.pos.size() != 2: return "Invalid object position."
		for n in item.pos:
			if not numeric(n): return "Invalid object position."
		if item.pos[0] < 0 or item.pos[1] < 0 or item.pos[0] >= WIDTH * TILE or item.pos[1] >= HEIGHT * TILE: return "Object center is outside the map."
		for key in ["frame", "scale", "rotation", "layer"]:
			if not numeric(item[key]): return "Invalid object transform."
		if item.scale < 0.1 or item.scale > 8 or absf(item.rotation) > 36000: return "Object transform out of bounds."
		if item.frame < 0 or item.frame != int(item.frame) or item.layer < 0 or item.layer > 2 or item.layer != int(item.layer): return "Invalid object frame or layer."
		if not item.animated is bool or not item.solid is bool: return "Invalid object flags."
		if not item.crop is Array or item.crop.size() != 4: return "Invalid crop."
		for n in item.crop:
			if not numeric(n) or n < 0 or n > 20000: return "Invalid crop."
		if item.has("tiled") and not item.tiled is bool: return "Invalid surface flag."
		if item.has("size") or item.get("tiled", false):
			if not item.get("size") is Array or item.size.size() != 2: return "Invalid surface dimensions."
			for n in item.size:
				if not numeric(n) or n < 1 or n > 1792: return "Surface dimensions out of bounds."
	return ""

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func normalize(value: Dictionary) -> Dictionary:
	var result := expand_legacy(value).duplicate(true)
	for i in result.cells.size():
		result.cells[i] = int(result.cells[i])
	for cell in [result.spawn, result.exit] + result.enemies:
		cell[0] = int(cell[0])
		cell[1] = int(cell[1])
	if result.has("floors"):
		for i in result.floors.size(): result.floors[i] = int(result.floors[i])
	result.version = int(result.version)
	for item in result.get("objects", []):
		item.frame = int(item.frame)
		item.layer = int(item.layer)
		item.scale = float(item.scale)
		item.rotation = float(item.rotation)
		for i in 2: item.pos[i] = float(item.pos[i])
		for i in 4: item.crop[i] = int(item.crop[i])
		if item.has("size"):
			for i in 2: item.size[i] = float(item.size[i])
	return result

# Stable facade used by editor, gameplay, tests and catalog tooling.
static func from_layout(asset: String, frame: int, frames: int) -> Dictionary:
	return Importer.from_layout(asset, frame, frames)

static func layout_reachable(map: Dictionary, start: Vector2i) -> Dictionary:
	return Importer.layout_reachable(map, start)
