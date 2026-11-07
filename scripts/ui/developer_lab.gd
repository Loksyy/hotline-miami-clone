extends VBoxContainer
const S = preload("res://scripts/settings/game_settings.gd")
const Tuning = preload("res://scripts/settings/live_tuning.gd")
signal back_requested
var compact := false
var rows: VBoxContainer
var message: Label

func _ready() -> void:
	custom_minimum_size = Vector2(0, 0) if compact else Vector2(900, 680)
	var title := Label.new()
	title.text = "DEVELOPER LAB"
	add_child(title)
	var hint := Label.new()
	hint.text = "Balance changes apply live. Starting stats need a new playtest; layout settings affect new maps.\nAppearance/default preferences may need a restart. Canvas dimensions are read-only."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	var search := LineEdit.new()
	search.placeholder_text = "Search settings: ammo, enemy, speed, size..."
	add_child(search)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 400 if compact else 500
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	search.text_changed.connect(func(query):
		for row in rows.get_children(): row.visible = query.to_lower() in str(row.get_meta("key")).to_lower())
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(message)
	var actions := HBoxContainer.new()
	add_child(actions)
	for text in (["Save tuning", "Reset to source defaults"] if compact else ["Save tuning", "Reset to source defaults", "Back"]):
		var button := Button.new()
		button.text = text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(button)
		button.pressed.connect(func():
			if text == "Back": back_requested.emit()
			elif text == "Save tuning": message.text = "Saved for future sessions." if Tuning.save() == OK else "Could not save tuning."
			else: Tuning.reset(); rebuild(); message.text = "Source defaults restored. Save tuning to keep them.")
	rebuild()

func update_value(key: String, value: Variant) -> void:
	message.text = (key.capitalize() + " updated. Save tuning to keep it.") if Tuning.change(key, value) else "Invalid value; previous setting kept."

func rebuild() -> void:
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	for key in S.SETTING_NAMES:
		var row: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
		row.set_meta("key", key)
		rows.add_child(row)
		var label := Label.new()
		label.text = key.capitalize()
		label.tooltip_text = key
		label.custom_minimum_size.x = 0 if compact else 420
		row.add_child(label)
		var value: Variant = Tuning.source.get(key)
		if key in S.LOCKED_SETTINGS:
			var locked := Label.new()
			locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			locked.text = str(value) + " (map format; edit source)"
			row.add_child(locked)
		elif value is bool:
			var toggle := CheckButton.new()
			toggle.button_pressed = value
			toggle.toggled.connect(func(v): update_value(key, v))
			row.add_child(toggle)
		elif value is float or value is int:
			var number := SpinBox.new()
			number.min_value = -100000; number.max_value = 1000000
			number.step = 1 if value is int else 0.01
			number.value = value
			number.custom_minimum_size.x = 230
			number.value_changed.connect(func(v): update_value(key, int(v) if value is int else float(v)))
			row.add_child(number)
		elif value is Color:
			var color := ColorPickerButton.new()
			color.color = value
			color.custom_minimum_size = Vector2(200, 32)
			color.color_changed.connect(func(v): update_value(key, v))
			row.add_child(color)
		else:
			var field := LineEdit.new()
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.text = str(value) if value is String else var_to_str(value)
			field.tooltip_text = "Press Enter to apply. Arrays/dictionaries use Godot syntax."
			field.text_submitted.connect(func(v): update_value(key, v if value is String else str_to_var(v)))
			row.add_child(field)
