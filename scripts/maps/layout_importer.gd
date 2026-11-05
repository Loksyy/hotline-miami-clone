extends "res://scripts/maps/map_format.gd"
## Converts source floor-plan images into playable terrain.

static func layout_background(color: Color) -> bool:
	return color.a < 0.1 or (color.g > color.r * 1.4 and color.g > color.b * 1.2)

static var layout_cache: Dictionary = {}

static func from_layout(asset: String, frame: int, frames: int) -> Dictionary:
	var key := "%s:%d:%d" % [asset, frame, frames]
	if not layout_cache.has(key): layout_cache[key] = convert_layout(asset, frame, frames)
	# Callers edit maps freely; the cached template must never share arrays.
	return layout_cache[key].duplicate(true)

static func convert_layout(asset: String, frame: int, frames: int) -> Dictionary:
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

