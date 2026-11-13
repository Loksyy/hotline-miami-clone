extends RefCounted
## Small combat effects drawn in world pixels; no per-frame textures or nodes.

static func punch_pose(step: int, progress: float) -> Dictionary:
	var t := clampf(progress, 0, 1)
	var strike := smoothstep(0.18, 0.38, t)
	var recovery := 1.0 - smoothstep(0.48, 1.0, t)
	var drive := strike * recovery
	var angle := 0.0
	match step % 4:
		0: angle = -0.4 * drive # Right swing.
		1: angle = 0.5 * drive # Mirrored left swing.
		2: angle = lerpf(-0.7, 0.85, strike) * recovery # Wide hook, then recovery.
		3: angle = lerpf(0.8, -0.75, strike) * recovery
	# Uppercut coils longer, drives upward, then returns to guard.
	var frames := [0, 1, 2, 3, 4, 5, 6] if step % 4 != 3 else [0, 1, 1, 2, 4, 5, 6]
	return {"angle": angle, "lean": drive * (3.0 if step % 4 == 3 else 1.5),
		"mirrored": step % 4 == 1, "frame": frames[mini(6, int((t * 0.5 if t < 0.18 else (lerpf(0.1, 0.6, strike) if t < 0.48 else lerpf(0.6, 0.99, smoothstep(0.48, 1.0, t)))) * 7))]}

static func draw_trace(canvas: CanvasItem, trace: Dictionary) -> void:
	var fade := clampf(trace.time / maxf(0.001, trace.get("duration", 0.09)), 0, 1)
	var start: Vector2 = trace.a
	var end: Vector2 = trace.b
	if start.distance_squared_to(end) < 0.01: return
	# A fading path preserves immediate hitscan feedback; a short bright head
	# moves toward the actual collision point and never extends through walls.
	canvas.draw_line(start, end, Color(1, 0.72, 0.28, fade * 0.25), 1)
	var head := start.lerp(end, clampf((1.0 - fade) * 3.0 + 0.15, 0, 1))
	var tail := head.move_toward(start, minf(32, start.distance_to(head)))
	canvas.draw_line(tail, head, Color(1, 0.65, 0.18, fade * 0.25), 3)
	canvas.draw_line(tail, head, Color(1, 0.96, 0.76, fade), 1)

static func draw_projectile(canvas: CanvasItem, point: Vector2, velocity: Vector2) -> void:
	var direction := velocity.normalized()
	canvas.draw_line(point - direction * 12, point, Color(1, 0.45, 0.24, 0.3), 3)
	canvas.draw_line(point - direction * 8, point, Color("ffeac0"), 1)
	canvas.draw_rect(Rect2(point.floor(), Vector2(2, 2)), Color.WHITE)

static func draw_magazine(canvas: CanvasItem, point: Vector2, progress: float) -> void:
	var origin := point.floor()
	# Square pixels, dark outline, feed lips and six brass cartridge slots.
	canvas.draw_rect(Rect2(origin + Vector2(1, 2), Vector2(10, 23)), Color(0, 0, 0, 0.45))
	canvas.draw_rect(Rect2(origin, Vector2(9, 23)), Color("10131b"))
	canvas.draw_rect(Rect2(origin + Vector2(1, 2), Vector2(7, 19)), Color("515e70"))
	canvas.draw_rect(Rect2(origin + Vector2(2, 3), Vector2(5, 17)), Color("202733"))
	canvas.draw_rect(Rect2(origin + Vector2(1, 0), Vector2(2, 2)), Color("c2ccda"))
	canvas.draw_rect(Rect2(origin + Vector2(6, 0), Vector2(2, 2)), Color("c2ccda"))
	var count := clampi(int(clampf(progress, 0, 1) * 6), 0, 6)
	for row in 6:
		var pos := origin + Vector2(2, 18 - row * 3)
		canvas.draw_rect(Rect2(pos, Vector2(5, 2)), Color("e9b653") if row < count else Color("354050"))
		if row < count: canvas.draw_rect(Rect2(pos, Vector2(1, 1)), Color("fff0ad"))
	canvas.draw_rect(Rect2(origin + Vector2(0, 21), Vector2(9, 2)), Color("9ba8bc"))

static func draw_effect(canvas: CanvasItem, effect: Dictionary) -> void:
	var fade := clampf(effect.life / effect.duration, 0, 1)
	var point: Vector2 = effect.pos
	var direction := Vector2.from_angle(effect.angle)
	var side := direction.orthogonal()
	var power: float = effect.power
	if effect.kind == "muzzle":
		var reach := (5 + 7 * fade) * power
		var outer := PackedVector2Array([point - direction * 2, point + side * 3 * power, point + direction * reach, point - side * 3 * power])
		canvas.draw_colored_polygon(outer, Color(1, 0.62, 0.12, fade))
		canvas.draw_line(point, point + direction * reach * 0.65, Color(1, 1, 0.88, fade), 2)
		return
	var color := Color("fff0c0") if effect.kind in ["wall", "punch"] else Color("ffddd0")
	color.a = fade
	# Short outward sparks mark the actual contact, not the cursor or target center.
	for i in 5:
		var ray := Vector2.from_angle(effect.angle + i * TAU / 5.0)
		var radius := (2 + (1 - fade) * 10) * power
		canvas.draw_line(point + ray * radius * 0.4, point + ray * radius, color, 1)
	if fade > 0.55:
		canvas.draw_rect(Rect2(point.floor() - Vector2.ONE, Vector2(3, 3)), Color(1, 1, 0.9, fade))
