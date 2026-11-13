extends VBoxContainer
## Browsable live settings. Validation and persistence live in live_tuning.gd.
const S = preload("res://scripts/settings/game_settings.gd")
const Tuning = preload("res://scripts/settings/live_tuning.gd")
const Weapons = preload("res://scripts/game/player_weapons.gd")
const GROUP_NAMES := ["Player & camera", "Weapons & damage", "Enemies", "World & layouts", "Editor & effects"]
const GUN_FIELDS := ["Bullets in one magazine", "Damage per bullet", "Bullet range (pixels)", "Time between shots (seconds)", "Reload time (seconds)", "Bullets fired at once", "Shot spread (degrees)"]
signal back_requested
var compact := false
var rows: VBoxContainer
var message: Label
var search: LineEdit
var category: OptionButton
var modified: CheckButton
var summary: Label
var save_button: Button
var reset_dialog: ConfirmationDialog
var labels: Dictionary = {}
var reset_buttons: Dictionary = {}

func _ready() -> void:
	Tuning.initialize()
	custom_minimum_size = Vector2.ZERO if compact else Vector2(900, 680)
	add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "DEVELOPER LAB"
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)
	var hint := Label.new()
	hint.text = "Tweak live. Save to keep changes between sessions."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	search = LineEdit.new()
	search.placeholder_text = "Search all settings: speed, shotgun, reload..."
	search.clear_button_enabled = true
	add_child(search)
	var filters := HBoxContainer.new()
	add_child(filters)
	category = OptionButton.new()
	category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for name in GROUP_NAMES: category.add_item(name)
	category.add_item("All settings")
	filters.add_child(category)
	modified = CheckButton.new()
	modified.text = "Modified only"
	modified.tooltip_text = "Settings that differ from the source defaults."
	filters.add_child(modified)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 220 if compact else 350
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	search.text_changed.connect(func(_q): rebuild())
	category.item_selected.connect(func(_i): rebuild())
	modified.toggled.connect(func(_v): rebuild())
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 36
	add_child(message)
	var actions := HBoxContainer.new()
	add_child(actions)
	save_button = action("Save tuning", actions, func():
		message.text = "Saved for future sessions." if Tuning.save() == OK else "Could not save tuning."
		refresh_status())
	action("Reset all...", actions, func(): reset_dialog.popup_centered())
	if not compact: action("Back", actions, func(): back_requested.emit())
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Reset all tuning?"
	reset_dialog.dialog_text = "Restore every source default? This changes live gameplay.\nYour saved tuning is replaced only when you click Save tuning."
	reset_dialog.confirmed.connect(func(): Tuning.reset(); rebuild(); message.text = "Source defaults restored. Save to keep them.")
	add_child(reset_dialog)
	rebuild()

func action(text: String, parent: Node, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func timing_hint(key: String) -> String:
	if key in S.LOCKED_SETTINGS: return "Read-only: part of the map format."
	if key.begins_with("LAYOUT_") or key.begins_with("DEFAULT_LAYOUT_"): return "Applies to newly generated layouts."
	if key in ["PLAYER_HEALTH", "ENEMY_HEALTH", "START_WEAPON", "START_RESERVE_AMMO", "ENEMY_WEAPON_PATTERN"]: return "Start a new playtest to apply starting values."
	if key.begins_with("DEFAULT_") or key.begins_with("EDITOR_"): return "A new session or rebuilt interface may be needed."
	if key.ends_with("INTERVAL"): return "Seconds between actions. Lower = faster."
	return "Applies live. Distances are world pixels; times are seconds."

func setting_label(key: String) -> String:
	return {"WEAPON_STAT_OVERRIDES": "Individual guns", "PLAYER_GUN_PROFILES": "Base gun profiles", "MELEE_WEAPON_INTERVALS": "Melee attack speed", "PROP_SCALE_OVERRIDES": "Object sizes"}.get(key, key.capitalize())

func update_value(key: String, value: Variant) -> bool:
	var accepted := Tuning.change(key, value)
	message.text = key.capitalize() + " updated. " + timing_hint(key) if accepted else "Invalid value; the previous value was kept."
	refresh_status()
	return accepted

func refresh_status() -> void:
	var count := 0
	for key in S.setting_names():
		var changed: bool = S.read_value(key) != Tuning.defaults[key]
		if changed: count += 1
		if labels.has(key): labels[key].text = setting_label(key) + (" *" if changed else "")
		if reset_buttons.has(key): reset_buttons[key].disabled = not changed
	summary.text = "%d modified from defaults%s" % [count, " | Searching all categories" if not search.text.is_empty() else ""]
	save_button.text = "Save changes" if Tuning.has_unsaved_changes() else "Saved"
	save_button.disabled = not Tuning.has_unsaved_changes()

func rebuild() -> void:
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	labels.clear()
	reset_buttons.clear()
	var query := search.text.strip_edges().to_lower().replace(" ", "_")
	for key in S.setting_names():
		var value: Variant = S.read_value(key)
		if query.is_empty() and category.selected < S.GROUPS.size() and key not in S.GROUPS[category.selected].SETTING_NAMES: continue
		var search_text: String = key + " " + setting_label(key) + " " + str(value)
		if key in ["WEAPON_STAT_OVERRIDES", "PLAYER_GUN_PROFILES"]: search_text += " ammo damage fire rate reload pellets spread magazine"
		if key == "FIRE_INTERVAL": search_text += " fire rate"
		if key == "MAGAZINE_SIZE": search_text += " ammo"
		if not query.is_empty() and query not in search_text.to_lower().replace(" ", "_"): continue
		if modified.button_pressed and value == Tuning.defaults[key]: continue
		var row := VBoxContainer.new()
		row.set_meta("key", key)
		rows.add_child(row)
		var heading := HBoxContainer.new()
		row.add_child(heading)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.tooltip_text = key + "\n" + timing_hint(key)
		heading.add_child(label)
		labels[key] = label
		if key not in S.LOCKED_SETTINGS:
			var reset := action("Reset", heading, func():
				var original: Variant = Tuning.defaults[key]
				update_value(key, original.duplicate(true) if original is Array or original is Dictionary else original)
				rebuild())
			reset.size_flags_horizontal = Control.SIZE_SHRINK_END
			reset.tooltip_text = "Restore this setting only."
			reset_buttons[key] = reset
		if key in S.LOCKED_SETTINGS:
			var locked := Label.new()
			locked.text = str(value) + " (map format; read-only)"
			row.add_child(locked)
		elif key in ["PLAYER_GUN_PROFILES", "WEAPON_STAT_OVERRIDES", "MELEE_WEAPON_INTERVALS", "PROP_SCALE_OVERRIDES"]:
			dictionary_editor(key, row)
		elif key == "START_WEAPON":
			var choice := OptionButton.new()
			for kind in ["FISTS"] + Weapons.PICKUPS: choice.add_item(kind)
			for i in choice.item_count:
				if choice.get_item_text(i) == value: choice.select(i)
			choice.item_selected.connect(func(i): update_value(key, choice.get_item_text(i)))
			row.add_child(choice)
		else:
			value_editor(value, row, func(v): return update_value(key, v), timing_hint(key))
	if rows.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "No matching settings. Try another search or turn off Modified only."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows.add_child(empty)
	refresh_status()

func value_editor(value: Variant, parent: Node, apply: Callable, hint: String = "") -> void:
	if value is bool:
		var toggle := CheckButton.new()
		toggle.text = "Enabled"
		toggle.button_pressed = value
		parent.add_child(toggle)
		toggle.toggled.connect(func(v):
			if not apply.call(v): toggle.set_pressed_no_signal(not v))
	elif value is float or value is int:
		var number := SpinBox.new()
		number.min_value = -100000
		number.max_value = 1000000
		number.step = 1 if value is int else 0.01
		number.value = value
		number.tooltip_text = hint
		number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		number.set_meta("accepted", value)
		parent.add_child(number)
		number.value_changed.connect(func(v):
			var next: Variant = int(v) if value is int else float(v)
			if apply.call(next): number.set_meta("accepted", next)
			else: number.set_value_no_signal(number.get_meta("accepted")))
	elif value is Color:
		var color := ColorPickerButton.new()
		color.color = value
		parent.add_child(color)
		color.color_changed.connect(func(v): apply.call(v))
	else:
		var field := LineEdit.new()
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		field.text = str(value) if value is String else var_to_str(value)
		field.tooltip_text = "Press Enter to apply. Arrays use Godot syntax."
		parent.add_child(field)
		field.set_meta("accepted", field.text)
		field.text_submitted.connect(func(v):
			if apply.call(v if value is String else str_to_var(v)): field.set_meta("accepted", v)
			else: field.text = field.get_meta("accepted"))

func dictionary_editor(key: String, parent: Node) -> void:
	var current: Dictionary = S.read_value(key)
	var toggle := CheckButton.new()
	toggle.text = "Edit individual values (%d)" % current.size()
	parent.add_child(toggle)
	var content := VBoxContainer.new()
	content.visible = not search.text.is_empty()
	toggle.button_pressed = content.visible
	parent.add_child(content)
	toggle.toggled.connect(func(v): content.visible = v)
	if key in ["PLAYER_GUN_PROFILES", "WEAPON_STAT_OVERRIDES"]:
		var hint := Label.new()
		hint.text = "Lower shot interval = faster fire. Magazine size applies on reload."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(hint)
	var choose := OptionButton.new()
	choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose.clip_text = true
	content.add_child(choose)
	for item in current: choose.add_item(str(item).get_file().trim_prefix("spr").capitalize())
	var fields := VBoxContainer.new()
	content.add_child(fields)
	var keys := current.keys()
	if keys.is_empty(): return
	var populate := func(index: int):
		for child in fields.get_children(): fields.remove_child(child); child.queue_free()
		var item: String = keys[index]
		var entry: Variant = S.read_value(key)[item]
		if entry is Array:
			for column in entry.size():
				var field_row := HBoxContainer.new()
				fields.add_child(field_row)
				var label := Label.new()
				label.text = GUN_FIELDS[column]
				label.custom_minimum_size.x = 210
				field_row.add_child(label)
				value_editor(entry[column], field_row, func(v): return update_dictionary(key, item, column, v))
		else: value_editor(entry, fields, func(v): return update_dictionary(key, item, -1, v))
	choose.item_selected.connect(populate)
	var selected := 0
	for i in keys.size():
		if str(keys[i]).to_lower() in search.text.to_lower(): selected = i
	choose.select(selected)
	populate.call(selected)

func update_dictionary(key: String, item: String, column: int, value: Variant) -> bool:
	var updated: Dictionary = S.read_value(key).duplicate(true)
	if column < 0: updated[item] = value
	else: updated[item][column] = value
	return update_value(key, updated)
