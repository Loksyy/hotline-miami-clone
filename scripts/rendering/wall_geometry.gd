extends RefCounted
## Pure shared wall geometry. Drawing and collision use these same rectangles.
const Format = preload("res://scripts/maps/map_format.gd")
const SIZE := Format.TILE
static func connects(map: Dictionary, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < Format.WIDTH and cell.y < Format.HEIGHT and map.cells[cell.y * Format.WIDTH + cell.x] in [2, 5]

static var cached_segments: Dictionary = {}
static var cached_thickness := -1.0

static func segments(map: Dictionary, cell: Vector2i, thickness_setting: float) -> Array[Rect2]:
	if cached_thickness != thickness_setting:
		cached_segments.clear()
		cached_thickness = thickness_setting
	var mask := 0
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for i in 4:
		if connects(map, cell + directions[i]): mask |= 1 << i
	var key := Vector3i(cell.x, cell.y, mask)
	if not cached_segments.has(key): cached_segments[key] = build_segments(cell, thickness_setting, mask)
	return cached_segments[key]

static func build_segments(cell: Vector2i, thickness_setting: float, mask: int) -> Array[Rect2]:
	var thickness := clampf(thickness_setting, 2, SIZE)
	var half := thickness / 2.0
	var origin := Vector2(cell) * SIZE
	var middle := origin + Vector2.ONE * SIZE / 2.0
	var left := (mask & 1) != 0
	var right := (mask & 2) != 0
	var up := (mask & 4) != 0
	var down := (mask & 8) != 0
	var segments: Array[Rect2] = []
	# One continuous horizontal run owns the junction. Vertical branches butt
	# against its edges, never overlap it with another textured end cap.
	if left or right:
		var x0 := origin.x if left else middle.x - half
		var x1 := origin.x + SIZE if right else middle.x + half
		segments.append(Rect2(Vector2(x0, middle.y - half), Vector2(x1 - x0, thickness)))
		if up: segments.append(Rect2(Vector2(middle.x - half, origin.y), Vector2(thickness, SIZE / 2.0 - half)))
		if down: segments.append(Rect2(Vector2(middle.x - half, middle.y + half), Vector2(thickness, SIZE / 2.0 - half)))
	elif up or down:
		var y0 := origin.y if up else middle.y - half
		var y1 := origin.y + SIZE if down else middle.y + half
		segments.append(Rect2(Vector2(middle.x - half, y0), Vector2(thickness, y1 - y0)))
	else:
		segments.append(Rect2(middle - Vector2.ONE * half, Vector2.ONE * thickness))
	return segments

