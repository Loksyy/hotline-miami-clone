extends SceneTree
const Game = preload("res://scripts/game/main.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func capture(game: Node, name: String) -> void:
	for i in 4: await process_frame
	check(game.workshop.window.get_global_rect().end.y <= 1080, name + " fits screen height")
	check(game.workshop.window.get_global_rect().end.x <= 1920, name + " fits screen width")
	if "--preview" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/sidebar-" + name + ".png")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	var w = game.workshop
	await capture(game, "assets")
	check(w.library_page.is_visible_in_tree() and not w.construction_section.visible, "Assets start without build controls")
	w.build_nav.pressed.emit()
	await capture(game, "build")
	check(w.construction_section.is_visible_in_tree() and not w.tabs.visible, "Build replaces assets")
	check(w.build_atlas_grid.get_child_count() == w.atlas_tiles.size(), "All atlas tiles available in Build")
	w.build_atlas_grid.get_child(0).pressed.emit()
	check(w.construction_section.is_visible_in_tree() and not w.detail_page.visible and w.mode == "stamp", "Atlas selection stays in Build and activates placement")
	game.map.objects.clear()
	var history_size: int = game.history.size()
	w.atlas_painting = true
	w.atlas_stroke_saved = false
	w.atlas_visited.clear()
	w.atlas_previous = game.center(game.map.spawn)
	w.paint_atlas_to(w.atlas_previous + Vector2(game.SIZE * 4, 0))
	check(game.map.objects.size() == 5, "Fast drag paints every crossed cell")
	w.paint_atlas_to(w.atlas_previous)
	check(game.map.objects.size() == 5, "Holding still does not stack tiles")
	check(game.history.size() == history_size + 1, "One undo snapshot per stroke")
	w.atlas_painting = false
	var room: Dictionary = game.Maps.small_blank()
	check(game.Maps.validate(room).is_empty(), "Small blank map validates")
	check(room.cells.count(1) == 28 * 28 and room.cells.count(2) == 115 and room.cells.count(5) == 1, "30 by 30 room with perimeter and one door")
	w.assets_nav.pressed.emit()
	check(not w.construction_section.visible and w.library_page.is_visible_in_tree(), "Assets button returns to browser")
	w.choose_entry(w.filtered[0])
	await capture(game, "properties")
	check(w.detail_page.is_visible_in_tree() and not w.library_page.visible, "Selection opens properties only")
	check(not w.advanced_properties.visible, "Technical properties collapsed initially")
	w.selected = 0
	if not w.objects().is_empty():
		w.objects()[0] = game.Maps.prop(game.PlayerWeapons.pickup_asset("PISTOL"), game.player, 1.0, 1, false, game.PlayerWeapons.drop_frame("PISTOL"))
		w.objects()[0]["pickup_kind"] = "PISTOL"
		w.inspect_selected()
		await capture(game, "weapon-compact")
	w.show_room_layouts()
	await capture(game, "layouts")
	check(w.layouts_page.is_visible_in_tree() and not w.construction_section.visible, "Layouts have a separate page")
	game.queue_free()
	await process_frame
	print("Sidebar checks: %d failures" % failures)
	quit(1 if failures else 0)
