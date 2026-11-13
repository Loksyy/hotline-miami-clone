extends SceneTree
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
class Preview:
	extends "res://scripts/game/main.gd"
	func _draw() -> void:
		if art == null: return
		render_origin = Vector2.ZERO
		view_zoom = 1.0
		draw_rect(Rect2(0, 0, 1920, 1080), Color("243440"))
		var kinds := ["PISTOL", "RIFLE", "MP5", "BAT", "KNIFE", "AXE", "SWORD", "SLEDGEHAMMER", "CLEAVER"]
		for row in kinds.size():
			draw_string(ThemeDB.fallback_font, Vector2(20, 75 + row * 110), kinds[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			for col in 8:
				weapon = kinds[row]
				player_walk = col * 2
				attack_duration = PlayerWeapons.animation_duration(weapon)
				attack_animation = 0.0 if col < 2 else attack_duration * (1.0 - (col - 2) / 6.0)
				attack_is_melee = PlayerWeapons.is_melee(weapon)
				var point := Vector2(260 + col * 200, 65 + row * 110)
				draw_circle(point, 3, Color.RED)
				draw_actor(point, 0, true, weapon, true, false, true)
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
	root.get_texture().get_image().save_png("res://.godot/animation-preview.png")
	game.queue_free()
	await process_frame
	quit()
