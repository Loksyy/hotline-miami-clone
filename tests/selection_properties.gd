extends SceneTree
const Game = preload("res://scripts/game/main.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	var workshop = game.workshop
	assert(workshop.mode == "select", "Editor starts in selection mode")
	workshop.activate_select()
	workshop.sidebar_visible = false
	workshop.update_mode()
	var coordinate: Array = game.map.enemies[0]
	workshop.show_cell_properties(Vector2i(coordinate[0], coordinate[1]))
	assert(workshop.entity_page.visible and workshop.sidebar_visible)
	assert(workshop.selected_entity == "enemy")
	var active = workshop.entity_page.find_child("EnemyActive", true, false)
	assert(active != null, "Selected enemy has a visible activity switch")
	active.button_pressed = true
	game.reset_game()
	assert(game.enemy_is_active(game.enemies[0]), "Switch enables AI without Apply")
	active.button_pressed = false
	game.reset_game()
	assert(not game.enemy_is_active(game.enemies[0]), "Switch disables AI without Apply")

	workshop.show_cell_properties(Vector2i(game.map.spawn[0], game.map.spawn[1]))
	assert(workshop.selected_entity == "spawn")
	workshop.show_cell_properties(Vector2i(0, 0))
	assert(workshop.selected_entity == "terrain")
	workshop.selected = 0
	workshop.inspect_selected()
	assert(workshop.detail_page.visible and not workshop.entity_page.visible)
	var cell_key := "%d,%d" % game.map.enemies[0]
	game.map.enemy_options = {cell_key: {"active": true, "health": 15, "damage": 7}}
	assert(game.Maps.validate(game.map).is_empty())
	game.reset_game()
	assert(game.enemy_is_active(game.enemies[0]))
	assert(game.enemies[0].health == 15 and game.enemies[0].damage_override == 7)
	game.map.enemy_options[cell_key].active = false
	game.reset_game()
	assert(not game.enemy_is_active(game.enemies[0]))
	game.queue_free()
	await process_frame
	print("Selection properties checks passed")
	quit()
