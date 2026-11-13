extends SceneTree
const Game = preload("res://scripts/game/main.gd")
const T = preload("res://scripts/settings/live_tuning.gd")
const S = preload("res://scripts/settings/game_settings.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	T.storage_path = "user://test_developer_lab.cfg"
	var game := Game.new()
	root.add_child(game)
	game.sound.muted = true
	game.toggle_mode()
	var lab = game.workshop.play_lab
	check(lab.rows.get_child_count() == S.GROUPS[0].SETTING_NAMES.size(), "Default page shows only player settings")
	var before: Dictionary = S.read_value("WEAPON_STAT_OVERRIDES").duplicate(true)
	check(lab.update_dictionary("WEAPON_STAT_OVERRIDES", "UZI", 0, 32), "Edit Uzi magazine with labeled control")
	check(S.read_value("WEAPON_STAT_OVERRIDES").UZI[0] == 32, "Gun changes reach gameplay")
	check(S.read_value("WEAPON_STAT_OVERRIDES").MP5 == before.MP5, "Editing one gun preserves another")
	check(not lab.update_dictionary("WEAPON_STAT_OVERRIDES", "UZI", 0, -1), "Invalid magazine rejected")
	check(S.read_value("WEAPON_STAT_OVERRIDES").UZI[0] == 32, "Invalid input preserves last accepted value")
	check(T.has_unsaved_changes(), "Live edits are marked unsaved")
	lab.search.text = "uzi"
	lab.search.text_changed.emit("uzi")
	check(lab.rows.get_child_count() == 1, "Search finds gun profile across categories")
	lab.modified.button_pressed = true
	check(lab.rows.get_child_count() == 1, "Modified filter retains changed profile")
	var magazine: SpinBox = lab.rows.find_children("*", "SpinBox", true, false)[0]
	magazine.value = 40
	check(S.read_value("WEAPON_STAT_OVERRIDES").UZI[0] == 40, "Visible magazine control edits the correct gun and field")
	magazine.value = -1
	check(magazine.value == 40 and S.read_value("WEAPON_STAT_OVERRIDES").UZI[0] == 40, "Rejected UI edit rolls back displayed value")
	for i in 8: await process_frame
	if "--preview" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/developer-lab-new.png")
	check(game.workshop.play_lab_panel.get_global_rect().end.x <= 1920, "Lab fits sidebar width")
	check(game.workshop.play_lab_panel.get_global_rect().end.y <= 1080, "Lab fits sidebar height")
	check(T.save() == OK and not T.has_unsaved_changes(), "Save clears unsaved indicator")
	lab.reset_buttons["WEAPON_STAT_OVERRIDES"].pressed.emit()
	check(S.read_value("WEAPON_STAT_OVERRIDES") == T.defaults.WEAPON_STAT_OVERRIDES, "Reset restores only the selected setting")
	check(T.has_unsaved_changes(), "Reset of saved tuning needs saving")
	T.reset()
	DirAccess.remove_absolute(T.storage_path)
	game.queue_free()
	await process_frame
	print("Developer Lab checks: %d failures" % failures)
	quit(1 if failures else 0)
