extends SceneTree
const Game = preload("res://scripts/game/main.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	for direction in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		game.replace_map(game.Maps.blank())
		var cell := Vector2i(8, 8)
		for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var p: Vector2i = cell + offset
			game.map.cells[p.y * game.Maps.WIDTH + p.x] = 2
		var outside: Vector2i = cell + direction
		game.map.cells[outside.y * game.Maps.WIDTH + outside.x] = 0
		var regions: Array[Rect2] = game.floor_regions(cell)
		check(regions.size() == 3, "Stepped corner excludes diagonal outside quarter")
		var point := (Vector2(cell) + Vector2.ONE * 0.5 + Vector2(direction) * 0.25) * game.SIZE
		for piece in regions: check(not piece.has_point(point), "No floor beyond wall corner")
		var a := Vector2(cell) * game.SIZE
		var polygon := PackedVector2Array([a, a + Vector2(game.SIZE, 0), a + Vector2.ONE * game.SIZE, a + Vector2(0, game.SIZE)])
		for piece in game.workshop.floor_patch_polygons(polygon):
			check(not Geometry2D.is_point_in_polygon(point, piece), "Placed floor textures share corner clipping")
		game.snapshot()
		game.paint(cell, true)
		check(game.floor_regions(cell) == regions, "Deleting corner preserves exact floor shape")
		game.paint(cell + Vector2i.RIGHT, true)
		check(game.floor_regions(cell) == regions, "Deleting adjacent wall cannot stretch floor")
		var loaded: Dictionary = game.Maps.normalize(JSON.parse_string(JSON.stringify(game.map)))
		check(game.Maps.validate(loaded).is_empty(), "Saved floor shapes validate")
		game.replace_map(loaded)
		check(game.floor_regions(cell) == regions, "Floor shape survives save and reload")
	game.queue_free()
	await process_frame
	print("Floor corner checks: %d failures" % failures)
	quit(1 if failures else 0)
