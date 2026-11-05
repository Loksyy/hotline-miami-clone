class_name MapData
extends RefCounted
const S = preload("res://scripts/game_settings.gd")

const WIDTH := 32
const HEIGHT := 22
const TILE := 28

static func floor_tile(tile: int) -> bool:
	return tile in [1, 3, 4]

static func blank() -> Dictionary:
	var cells: Array = []
	for y in HEIGHT:
		for x in WIDTH:
			cells.append(2 if x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1 else 1)
	return {"version": 1, "name": "Untitled floor", "cells": cells, "spawn": [3, 11], "enemies": [], "exit": [28, 11], "objects": []}

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

static func starter() -> Dictionary:
	return from_layout("Floor Plans/sprApartment1_strip16.png", 8, 16)

static func layout_background(color: Color) -> bool:
	return color.a < 0.1 or (color.g > color.r * 1.4 and color.g > color.b * 1.2)

static func from_layout(asset: String, frame: int, frames: int) -> Dictionary:
	var image := (load("res://HLM1 Files/" + asset) as Texture2D).get_image()
	var fw := image.get_width() / frames
	var region := image.get_region(Rect2i((frame % frames) * fw, 0, fw, image.get_height()))
	var map := blank()
	map.name = asset.get_file().get_basename() + " / " + str(frame + 1)
	map.objects = []
	map.enemies = []
	map.cells.fill(0)
	# Flood background from the image boundary. Green inside a closed outline
	# is room interior too, not empty space (many frames are outline-only).
	var exterior: Dictionary = {}
	var pending_pixels: Array[Vector2i] = []
	for y in region.get_height():
		for x in region.get_width():
			if x == 0 or y == 0 or x == region.get_width() - 1 or y == region.get_height() - 1:
				var pixel := Vector2i(x, y)
				if layout_background(region.get_pixelv(pixel)):
					exterior[pixel] = true
					pending_pixels.append(pixel)
	var cursor := 0
	while cursor < pending_pixels.size():
		var pixel: Vector2i = pending_pixels[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = pixel + direction
			if next.x < 0 or next.y < 0 or next.x >= region.get_width() or next.y >= region.get_height() or exterior.has(next): continue
			if layout_background(region.get_pixelv(next)):
				exterior[next] = true
				pending_pixels.append(next)
	var low := region.get_size()
	var high := Vector2i.ZERO
	for y in region.get_height():
		for x in region.get_width():
			if not exterior.has(Vector2i(x, y)):
				low = low.min(Vector2i(x, y))
				high = high.max(Vector2i(x + 1, y + 1))
	if high.x <= low.x or high.y <= low.y: return blank()
	var bounds := high - low
	var occupied: Dictionary = {}
	var walls: Dictionary = {}
	var scale := minf(26.0 / bounds.x, 18.0 / bounds.y)
	var size := Vector2i(maxi(3, int(bounds.x * scale)), maxi(3, int(bounds.y * scale)))
	var origin := Vector2i((WIDTH - size.x) / 2, (HEIGHT - size.y) / 2)
	for y in size.y:
		for x in size.x:
			var filled := 0
			var white := 0
			var total := 0
			for py in range(low.y + int(y * bounds.y / float(size.y)), low.y + maxi(int((y + 1) * bounds.y / float(size.y)), int(y * bounds.y / float(size.y)) + 1)):
				for px in range(low.x + int(x * bounds.x / float(size.x)), low.x + maxi(int((x + 1) * bounds.x / float(size.x)), int(x * bounds.x / float(size.x)) + 1)):
					total += 1
					if exterior.has(Vector2i(px, py)): continue
					filled += 1
					var color := region.get_pixel(px, py)
					if color.a > 0.5 and minf(color.r, minf(color.g, color.b)) > 0.65: white += 1
			if filled == 0 or float(filled) / total < 0.25: continue
			var cell := origin + Vector2i(x, y)
			occupied[cell] = true
			if float(white) / filled >= 0.12: walls[cell] = true
	# Keep the perimeter inside the sampled footprint, never add an outer row.
	for cell in occupied:
		var boundary := false
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not occupied.has(cell + step): boundary = true
		map.cells[cell.y * WIDTH + cell.x] = 2 if boundary or walls.has(cell) else 3
	var floors: Array[Vector2i] = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			if floor_tile(map.cells[y * WIDTH + x]): floors.append(Vector2i(x, y))
	if floors.size() < 2: return blank()
	var start: Vector2i = floors[0]
	var checked: Dictionary = {}
	var largest := 0
	for candidate in floors:
		if checked.has(candidate): continue
		var component := layout_reachable(map, candidate)
		checked.merge(component)
		if component.size() > largest:
			largest = component.size()
			start = candidate
	# Connect rooms through structural walls. Each carved wall becomes a door.
	var reached := layout_reachable(map, start)
	for destination in floors:
		if reached.has(destination): continue
		var pending: Array[Vector2i] = [destination]
		var previous: Dictionary = {destination: destination}
		var found := Vector2i(-1, -1)
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_front()
			if reached.has(cell): found = cell; break
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if next.x < 1 or next.y < 1 or next.x >= WIDTH - 1 or next.y >= HEIGHT - 1 or previous.has(next): continue
				if map.cells[next.y * WIDTH + next.x] == 0: continue
				previous[next] = cell
				pending.append(next)
		if found.x >= 0:
			while found != destination:
				if map.cells[found.y * WIDTH + found.x] == 2: map.cells[found.y * WIDTH + found.x] = 5
				found = previous[found]
			reached = layout_reachable(map, start)
	# Any truly separate island stays architectural, without unreachable actors.
	var accessible: Array[Vector2i] = []
	for cell in floors:
		if reached.has(cell): accessible.append(cell)
	if accessible.size() < 2: return blank()
	map.spawn = [start.x, start.y]
	var finish: Vector2i = accessible.back()
	map.exit = [finish.x, finish.y]
	for fraction in [0.35, 0.65]:
		var cell: Vector2i = accessible[int((accessible.size() - 1) * fraction)]
		var coordinate := [cell.x, cell.y]
		if coordinate != map.spawn and coordinate != map.exit and coordinate not in map.enemies: map.enemies.append(coordinate)
	# Alternate basic floor finishes across rooms/sections.
	for cell in accessible:
		if cell.x > WIDTH / 2: map.cells[cell.y * WIDTH + cell.x] = 4
	# Existing open passages need a door too; room connection alone only
	# inserts doors when a wall separates two disconnected regions.
	if not map.cells.has(5):
		for y in range(2, HEIGHT - 2):
			if map.cells.has(5): break
			for x in range(2, WIDTH - 2):
				if [x, y] in [map.spawn, map.exit] + map.enemies: continue
				var index := y * WIDTH + x
				if map.cells[index] != 2: continue
				if (floor_tile(map.cells[index - 1]) and floor_tile(map.cells[index + 1])) or (floor_tile(map.cells[index - WIDTH]) and floor_tile(map.cells[index + WIDTH])):
					map.cells[index] = 5
					break
	# Window artwork overlays exterior structural walls, which retain collision.
	for y in range(2, HEIGHT - 2):
		for x in range(3, WIDTH - 3):
			if map.objects.size() >= 3: break
			if x % 5 != 0 or map.cells[y * WIDTH + x] != 2: continue
			if map.cells[(y - 1) * WIDTH + x] == 0 and floor_tile(map.cells[(y + 1) * WIDTH + x]) and map.cells[y * WIDTH + x - 1] == 2 and map.cells[y * WIDTH + x + 1] == 2:
				map.objects.append(prop("Walls/sprGlassPanelH.png", Vector2(x + 0.5, y + 0.5) * TILE, 1.0, 2, false))
	return map

static func layout_reachable(map: Dictionary, start: Vector2i) -> Dictionary:
	var reached := {start: true}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if next.x < 0 or next.y < 0 or next.x >= WIDTH or next.y >= HEIGHT or reached.has(next): continue
			var tile: int = map.cells[next.y * WIDTH + next.x]
			if not floor_tile(tile) and tile != 5: continue
			reached[next] = true
			pending.append(next)
	return reached

static func prop(asset: String, position: Vector2, scale: float = 1.0, layer: int = 1, solid: bool = true, frame: int = 0) -> Dictionary:
	return {"asset": asset, "pos": [position.x, position.y], "frame": frame,
		"scale": S.PROP_SCALE_OVERRIDES.get(asset, scale), "rotation": 0.0, "layer": layer, "animated": false,
		"solid": solid, "crop": [0, 0, 0, 0]}

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

static func validate(value: Variant) -> String:
	if not value is Dictionary:
		return "Map must be a JSON object."
	for key in ["version", "name", "cells", "spawn", "enemies", "exit"]:
		if not value.has(key):
			return "Missing field: " + key
	if value.version != 1 or not value.name is String:
		return "Unsupported map version or invalid name."
	if not value.cells is Array or value.cells.size() != WIDTH * HEIGHT:
		return "Map must contain exactly 704 tiles."
	for cell in value.cells:
		if not (cell is int or cell is float) or cell != int(cell) or int(cell) < 0 or int(cell) > 6:
			return "Invalid tile type."
	if not value.enemies is Array or value.enemies.size() > S.MAX_ENEMIES:
		return "Invalid enemy list (maximum %d)." % S.MAX_ENEMIES
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
	var props: Variant = value.get("objects", [])
	if not props is Array or props.size() > S.MAX_MAP_OBJECTS: return "Invalid object list."
	for item in props:
		if not item is Dictionary: return "Invalid object."
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
	var result := value.duplicate(true)
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
