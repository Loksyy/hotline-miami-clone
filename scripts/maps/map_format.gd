extends RefCounted
## Shared map dimensions, tile types and constructors. No editor dependencies.
const S = preload("res://scripts/settings/game_settings.gd")
const WIDTH := S.MAP_WIDTH_CELLS
const HEIGHT := S.MAP_HEIGHT_CELLS
const TILE := S.CELL_SIZE

static func floor_tile(tile: int) -> bool:
	return tile in [1, 3, 4]

static func blank() -> Dictionary:
	var cells: Array = []
	for y in HEIGHT:
		for x in WIDTH:
			cells.append(2 if x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1 else 1)
	return {"version": 1, "name": "Untitled floor", "cells": cells, "spawn": [3, 11], "enemies": [], "exit": [28, 11], "objects": []}

static func prop(asset: String, position: Vector2, scale: float = 1.0, layer: int = 1, solid: bool = true, frame: int = 0) -> Dictionary:
	return {"asset": asset, "pos": [position.x, position.y], "frame": frame,
		"scale": S.PROP_SCALE_OVERRIDES.get(asset, scale), "rotation": 0.0, "layer": layer, "animated": false,
		"solid": solid, "crop": [0, 0, 0, 0]}

