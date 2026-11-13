extends SceneTree
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
class Preview:
	extends "res://scripts/game/main.gd"
	func _draw() -> void:
		if art == null: return
		render_origin = Vector2.ZERO
		view_zoom = 1.0
		draw_rect(Rect2(0, 0, 1920, 1080), Color("243440"))
		for row in 4:
			draw_string(ThemeDB.fallback_font, Vector2(20, 70 + row * 160), ["Right swing", "Left swing", "Hook", "Uppercut"][row], HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
			for col in 7:
				weapon = "FISTS"
				punch_step = row
				attack_duration = 0.3
				attack_animation = attack_duration * (1.0 - col / 7.0)
				attack_is_melee = true
				draw_actor(Vector2(300 + col * 190, 70 + row * 160), 0, true, weapon)
		for col in 7:
			CombatVisuals.draw_effect(self, {"pos": Vector2(280 + col * 190, 950), "angle": 0.0, "kind": "muzzle" if col < 3 else "hit", "power": 1.0, "life": 0.07, "duration": 0.1})
			CombatVisuals.draw_magazine(self, Vector2(300 + col * 190, 750), col / 6.0)
			CombatVisuals.draw_trace(self, {"a": Vector2(260 + col * 190, 880), "b": Vector2(410 + col * 190, 880), "time": 0.09 * (1.0 - col / 7.0), "duration": 0.09})
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Preview.new()
	root.add_child(game)
	game.sound.muted = true
	game.set_process(false)
	EditorVisualsSettings.ACTOR_SPRITE_SCALE = 2.0
	for child in game.get_children():
		if child is CanvasItem: child.hide()
		if child is CanvasLayer: child.hide()
	game.queue_redraw()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/combat-preview.png")
	game.queue_free()
	await process_frame
	quit()
