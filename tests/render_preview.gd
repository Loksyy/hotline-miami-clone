extends SceneTree
## Run without --headless to verify real rendering and capture local previews.
const Game = preload("res://scripts/game/main.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	game.preferences.fullscreen = false
	game.preferences.apply()
	root.size = Vector2i(1920, 1080)
	for i in 360: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/editor-preview.png")
	print("Rendered editor FPS: ", Engine.get_frames_per_second())
	print("Visible FPS counter: ", game.fps_label.text)
	game.workshop.show_room_layouts()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/layouts-preview.png")
	game.pause_menu.open_menu()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/pause-preview.png")
	game.pause_menu.home.hide()
	game.pause_menu.settings_page.show()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/settings-preview.png")
	game.pause_menu.settings_page.hide()
	game.pause_menu.lab.show()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/lab-preview.png")
	game.pause_menu.close_menu()
	game.toggle_mode()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/play-lab-preview.png")
	game.queue_free()
	await process_frame
	quit()
