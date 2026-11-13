extends SceneTree
const Game = preload("res://scripts/game/main.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	game.replace_map(game.Maps.blank())
	game.toggle_mode()
	game.player = game.center([12, 10])
	game.play_center = game.player
	game.enemies.clear()
	game.weapon = "MOLOTOV"
	game.ignite(game.player + Vector2(100, 0))
	for i in 15: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/molotov-preview.png")
	game.queue_free()
	await process_frame
	quit()
