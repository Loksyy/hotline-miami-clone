extends CanvasLayer
## Owns Escape handling and paused UI. Gameplay and editor stop via SceneTree.paused.
var game: Node
var overlay: ColorRect
var home: VBoxContainer
var settings_page: VBoxContainer
var lab: VBoxContainer
var heading: Label
var editor_button: Button

func _ready() -> void:
	game = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.025, 0.06, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 420)
	panel.theme = game.workshop.window.theme
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var pages := VBoxContainer.new()
	margin.add_child(pages)
	home = VBoxContainer.new()
	home.add_theme_constant_override("separation", 14)
	pages.add_child(home)
	heading = Label.new()
	heading.text = "PROJECT GAGUGAGA / PAUSED"
	heading.add_theme_font_size_override("font_size", 24)
	home.add_child(heading)
	add_button("Resume [Esc]", close_menu, home)
	add_button("Settings", func(): home.hide(); settings_page.show(), home)
	add_button("Developer Lab", func(): home.hide(); lab.show(), home)
	editor_button = add_button("Return to editor", return_to_editor, home)
	add_button("Exit game", func(): game.preferences.save(); get_tree().quit(), home)
	var hint := Label.new()
	hint.text = "Save your map from the editor before exiting."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home.add_child(hint)
	settings_page = VBoxContainer.new()
	settings_page.add_theme_constant_override("separation", 12)
	pages.add_child(settings_page)
	var title := Label.new()
	title.text = "SETTINGS"
	settings_page.add_child(title)
	var volume_label := Label.new()
	volume_label.text = "Sound volume"
	settings_page.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0; volume.max_value = 1; volume.step = 0.05
	volume.value = game.preferences.volume
	settings_page.add_child(volume)
	volume.value_changed.connect(func(value): game.preferences.volume = value; game.preferences.apply())
	add_toggle("Show FPS", "show_fps")
	add_toggle("Screen shake", "screen_shake")
	add_toggle("Fullscreen", "fullscreen")
	add_toggle("VSync", "vsync")
	var limit := OptionButton.new()
	var limits: Array = preload("res://scripts/settings/game_settings.gd").FRAME_LIMIT_OPTIONS
	for value in limits: limit.add_item("FPS limit: " + ("Unlimited" if value == 0 else str(value)))
	limit.select(limits.find(game.preferences.frame_limit))
	limit.item_selected.connect(func(index): game.preferences.frame_limit = limits[index]; game.preferences.apply())
	settings_page.add_child(limit)
	add_button("Back", func(): game.preferences.save(); settings_page.hide(); home.show(), settings_page)
	lab = preload("res://scripts/ui/developer_lab.gd").new()
	pages.add_child(lab)
	lab.back_requested.connect(func(): lab.hide(); home.show())
	lab.hide()
	overlay.hide()

func add_button(text: String, action: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func add_toggle(text: String, key: String) -> void:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.button_pressed = game.preferences.get(key)
	toggle.toggled.connect(func(value): game.preferences.set(key, value); game.preferences.apply())
	settings_page.add_child(toggle)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if game.dialog.visible: return
		if overlay.visible:
			if lab.visible:
				lab.hide(); home.show()
			elif settings_page.visible:
				game.preferences.save(); settings_page.hide(); home.show()
			else: close_menu()
		else: open_menu()
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	game.painting = false
	game.rectangle_mode = false
	game.workshop.dragging = false
	game.workshop.activate_select()
	home.show(); settings_page.hide(); lab.hide(); overlay.show()
	editor_button.text = "Back to editor" if game.editing else "Return to editor"
	get_tree().paused = true

func close_menu() -> void:
	game.preferences.save()
	overlay.hide()
	get_tree().paused = false

func return_to_editor() -> void:
	close_menu()
	if not game.editing: game.toggle_mode()
	game.workshop.show_library_page()
