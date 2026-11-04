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
	# Apartment layout: entry/living room, kitchen, bedroom and rear exit.
	var map := blank()
	map.name = "01 / NIGHT SHIFT APARTMENT"
	for y in HEIGHT:
		for x in WIDTH:
			map.cells[y * WIDTH + x] = 0
	for y in range(2, 20):
		for x in range(3, 29):
			var boundary := x in [3, 28] or y in [2, 19]
			map.cells[y * WIDTH + x] = 2 if boundary else (4 if x >= 19 and y < 11 else 3)
	for y in range(3, 19): map.cells[y * WIDTH + 18] = 2
	for x in range(19, 28): map.cells[11 * WIDTH + x] = 2
	for cell in [[18, 7], [18, 15], [24, 11]]: map.cells[cell[1] * WIDTH + cell[0]] = 5
	map.spawn = [6, 15]
	map.exit = [26, 17]
	map.enemies = [[12, 5], [24, 5], [22, 16]]
	# The source floor-plan is a miniature diagram: keep it as an editable
	# planning reference beside the furnished rooms, rather than fake collision.
	map.objects = [
		prop("Floor Plans/sprApartment1_strip16.png", Vector2(448, 28), 1.0, 0, false, 8),
		prop("Furniture/sprSofaH48_strip2.png", Vector2(252, 182), 1.0),
		prop("Furniture/sprAndersTable.png", Vector2(280, 294), 1.0),
		prop("Furniture/sprAndersBed.png", Vector2(700, 392), 1.0),
		prop("Furniture/sprAndersDrawer.png", Vector2(762, 420), 0.4),
		prop("Furniture/sprAndersDesk_strip6.png", Vector2(644, 168), 1.0)
	]
	return map

static func prop(asset: String, position: Vector2, scale: float = 1.0, layer: int = 1, solid: bool = true, frame: int = 0) -> Dictionary:
	return {"asset": asset, "pos": [position.x, position.y], "frame": frame,
		"scale": S.PROP_SCALE_OVERRIDES.get(asset, scale), "rotation": 0.0, "layer": layer, "animated": false,
		"solid": solid, "crop": [0, 0, 0, 0]}

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
