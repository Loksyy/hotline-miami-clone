extends Node
## Full asset library and non-destructive object layer for the map workshop.
const S = preload("res://scripts/game_settings.gd")
const ROOT := "res://HLM1 Files/"
var game: Node2D
var catalog: Array = []
var metadata: Dictionary = {}
var cache: Dictionary = {}
var atlas_cache: Dictionary = {}
var filtered: Array = []
var page := 0
const PAGE_SIZE := 30
var window: PanelContainer
var search: LineEdit
var category: OptionButton
var grid: GridContainer
var page_label: Label
var preview: TextureRect
var description: Label
var frame_input: SpinBox
var scale_input: SpinBox
var rotation_input: SpinBox
var layer_input: OptionButton
var animate_input: CheckBox
var solid_input: CheckBox
var snap_input: CheckBox
var tiled_input: CheckBox
var width_input: SpinBox
var height_input: SpinBox
var crop_inputs: Array[SpinBox] = []
var draft: Dictionary = {}
var mode := "terrain"
var selected := -1
var dragging := false
var drag_offset := Vector2.ZERO
var drag_started := false
var clipboard: Dictionary = {}
var clock := 0.0
var syncing_inspector := false
var tabs: TabContainer
var play_help: Label
var browse_filter: OptionButton
var favorites: Array = []
var recent: Array = []
var previous_button: Button
var next_button: Button
var favorite_button: Button
var apply_button: Button
var selection_actions: HBoxContainer
var empty_results: Label
var mode_badge: Label
var undo_button: Button
var redo_button: Button

func section(title: String, parent: Node) -> Label:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color("60e4dc")
	parent.add_child(label)
	return label

func foldout(title: String, parent: Node) -> VBoxContainer:
	var toggle := CheckButton.new()
	toggle.text = title
	parent.add_child(toggle)
	var content := VBoxContainer.new()
	content.visible = false
	parent.add_child(content)
	toggle.toggled.connect(func(value): content.visible = value)
	return content

func style_dock() -> void:
	var theme := Theme.new()
	theme.default_font_size = 16
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("1b293b") if state == "normal" else Color("2b4055")
		if state == "disabled": box.bg_color = Color("121b27")
		box.set_corner_radius_all(6)
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		if state == "focus":
			box.set_border_width_all(1)
			box.border_color = Color("60e4dc")
		theme.set_stylebox(state, "Button", box)
	theme.set_constant("separation", "VBoxContainer", 8)
	theme.set_constant("h_separation", "GridContainer", 8)
	theme.set_constant("v_separation", "GridContainer", 8)
	window.theme = theme

func _ready() -> void:
	game = get_parent()
	var text := FileAccess.get_file_as_string("res://assets/catalog.json").trim_prefix("\ufeff")
	var value: Variant = JSON.parse_string(text)
	if value is Array: catalog = value
	for entry in catalog: metadata[entry.path] = entry
	build_browser()

func objects() -> Array:
	if not game.map.has("objects"): game.map.objects = []
	return game.map.objects

func button(text: String, action: Callable, parent: Node) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 38
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.focus_mode = Control.FOCUS_NONE
	control.pressed.connect(action)
	parent.add_child(control)
	return control

func number(label_text: String, minimum: float, maximum: float, step: float, initial: float, parent: Node) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 92
	row.add_child(label)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = initial
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	control.value_changed.connect(func(_v): update_preview())
	return control

func build_browser() -> void:
	window = PanelContainer.new()
	window.position = Vector2(1280, 0)
	window.size = Vector2(640, 1080)
	style_dock()
	add_child(window)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	window.add_child(margin)
	var columns := VBoxContainer.new()
	margin.add_child(columns)
	var heading := Label.new()
	heading.text = "MAP WORKSHOP"
	heading.add_theme_font_size_override("font_size", 20)
	columns.add_child(heading)
	game.title_input.reparent(columns)
	var toolbar := HBoxContainer.new()
	columns.add_child(toolbar)
	button("Save", func(): game.choose_file("save"), toolbar).tooltip_text = "Save your map as JSON"
	button("Load", func(): game.choose_file("load"), toolbar)
	undo_button = button("Undo", game.undo, toolbar)
	redo_button = button("Redo", game.redo, toolbar)
	game.toggle_button = button("Playtest [Tab]", game.toggle_mode, columns)
	game.toggle_button.modulate = Color("60e4dc")
	mode_badge = Label.new()
	columns.add_child(mode_badge)
	var editing_modes := HBoxContainer.new()
	columns.add_child(editing_modes)
	button("Select / move [V]", func(): mode = "select"; game.painting = false; game.status.text = "Click an object, drag to move. Double-click for properties.", editing_modes)
	button("Paint terrain [Esc]", func(): game.select_brush(game.brush); tabs.current_tab = 1, editing_modes)
	play_help = Label.new()
	play_help.text = "PLAYTEST\n\nWASD: move / Mouse: aim\nLeft click: attack / Right click: throw\nE: pick up / F: melee / Space: door\nR: reload / T: restart\n\nTab: return to editing"
	play_help.visible = false
	columns.add_child(play_help)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(tabs)
	var map_tab := VBoxContainer.new()
	map_tab.name = "Map"
	tabs.add_child(map_tab)
	section("LAYOUT", map_tab)
	button("New blank map", func(): game.replace_map(game.Maps.blank()), map_tab)
	button("Load demo layout", func(): game.replace_map(game.Maps.demo()), map_tab)
	button("Check routes to enemies and exit", game.check_routes, map_tab)
	section("VIEW", map_tab)
	button("Fit entire map [Home]", func(): game.editor_center = Vector2(448, 308); game.editor_zoom = 1.0; game.queue_redraw(), map_tab)
	button("Toggle grid [G]", func(): game.show_grid = not game.show_grid; game.queue_redraw(), map_tab)
	var guidance := Label.new()
	guidance.text = "1. Build: paint floors and walls, place enemies.\n2. Assets: click a thumbnail, then click the map.\n3. Playtest your layout, then save it.\n\nCAMERA\nMouse wheel: zoom / Middle drag: pan\n\nOBJECTS\nSelect, then drag to move.\nQ / E: rotate / [ / ]: resize\nDelete: remove / Enter: properties\nCtrl+C / V: copy / paste\nCtrl+D: duplicate / Esc: terrain mode"
	foldout("Controls and getting started", map_tab).add_child(guidance)
	var build_tab := VBoxContainer.new()
	build_tab.name = "Build"
	tabs.add_child(build_tab)
	var build_help := Label.new()
	build_help.text = "Choose a tool, then click or drag on the map.\nShift + drag fills a rectangle."
	build_tab.add_child(build_help)
	var tools_grid := GridContainer.new()
	tools_grid.columns = 2
	build_tab.add_child(tools_grid)
	var names := ["Void [1]", "Carpet [2]", "Wall [3]", "Player spawn [4]", "Enemy [5]", "Exit [6]", "Erase / floor [7]", "Wood floor [8]", "Tile floor [9]", "Working door [0]", "Sofa [-]"]
	for i in names.size():
		var index := i
		var tool := button(names[i], func(): game.select_brush(index), tools_grid)
		tool.custom_minimum_size.y = 48
		tool.tooltip_text = "Select, then click or drag on the map. Shift+drag fills an area."
		var icons := {2: "wall", 3: "player_gun", 4: "enemy_gun", 5: "exit", 9: "door", 10: "sofa"}
		if icons.has(i):
			tool.icon = game.art.frame(icons[i])
			tool.expand_icon = true
			tool.add_theme_constant_override("icon_max_width", 32)
		game.palette.append(tool)
	var door_help := Label.new()
	door_help.text = "Doors replace a single wall cell.\nWalk to push open; Space to kick or close.\nRight-click removes enemies or restores floor."
	build_tab.add_child(door_help)
	game.select_brush(game.brush)
	button("Select / move placed objects [V]", func(): mode = "select"; game.painting = false; game.status.text = "Click an object to select it, then drag to move. Enter opens properties.", build_tab)
	var assets_tab := VBoxContainer.new()
	assets_tab.name = "Assets"
	tabs.add_child(assets_tab)
	tabs.current_tab = 2
	var library := VBoxContainer.new()
	library.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	library.custom_minimum_size.y = 340
	assets_tab.add_child(library)
	var filters := HBoxContainer.new()
	library.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "Search all textures: couch, gun, floor, mask..."
	search.clear_button_enabled = true
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(search)
	search.text_changed.connect(func(_text): filter_catalog())
	category = OptionButton.new()
	category.add_item("All categories")
	var categories: Array = []
	for entry in catalog:
		if entry.category not in categories: categories.append(entry.category)
	categories.sort()
	for name in categories: category.add_item(name)
	filters.add_child(category)
	category.item_selected.connect(func(_index): filter_catalog())
	var quick_filters := HBoxContainer.new()
	library.add_child(quick_filters)
	browse_filter = OptionButton.new()
	for name in ["All assets", "Favorites", "Recently used"]: browse_filter.add_item(name)
	browse_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick_filters.add_child(browse_filter)
	browse_filter.item_selected.connect(func(_index): filter_catalog())
	button("Reset filters", reset_filters, quick_filters)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	empty_results = Label.new()
	empty_results.text = "No matching assets. Try a shorter search or reset the filters."
	empty_results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	library.add_child(empty_results)
	var pager := HBoxContainer.new()
	library.add_child(pager)
	previous_button = button("Previous", func(): page = maxi(0, page - 1); refresh_page(), pager)
	page_label = Label.new()
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pager.add_child(page_label)
	next_button = button("Next", func(): page = mini(maxi(0, int(ceil(filtered.size() / float(PAGE_SIZE))) - 1), page + 1); refresh_page(), pager)
	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.custom_minimum_size.x = 580
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assets_tab.add_child(inspector_scroll)
	var inspector := VBoxContainer.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_scroll.add_child(inspector)
	section("PLACEMENT & PROPERTIES", inspector)
	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(580, 100)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inspector.add_child(preview)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 580
	inspector.add_child(description)
	description.text = "Click a thumbnail to start placing it on the map."
	favorite_button = button("Add to favorites", toggle_favorite, inspector)
	frame_input = number("Frame", 0, 1000, 1, 0, inspector)
	scale_input = number("Scale", 0.1, 8, 0.05, 1, inspector)
	rotation_input = number("Rotation", -360, 360, 15, 0, inspector)
	layer_input = OptionButton.new()
	layer_input.add_item("Floor layer / below actors")
	layer_input.add_item("Prop layer / below actors")
	layer_input.add_item("Overlay / above actors")
	layer_input.select(1)
	inspector.add_child(layer_input)
	animate_input = CheckBox.new()
	animate_input.text = "Animate sprite strip"
	inspector.add_child(animate_input)
	solid_input = CheckBox.new()
	solid_input.text = "Solid (sprite rectangle collider)"
	inspector.add_child(solid_input)
	snap_input = CheckBox.new()
	snap_input.text = "Snap placement to grid"
	snap_input.button_pressed = true
	inspector.add_child(snap_input)
	var advanced := foldout("Advanced: atlas crop and room surfaces", inspector)
	var hint := Label.new()
	hint.text = "Atlas crop (0 width = full frame)"
	advanced.add_child(hint)
	for field in ["Crop X", "Crop Y", "Crop width", "Crop height"]:
		crop_inputs.append(number(field, 0, 20000, 1, 0, advanced))
	tiled_input = CheckBox.new()
	tiled_input.text = "Repeat texture as room surface"
	advanced.add_child(tiled_input)
	width_input = number("Area width", 1, 1792, 1, 224, advanced)
	height_input = number("Area height", 1, 1232, 1, 168, advanced)
	button("Place another copy", use_stamp, inspector)
	apply_button = button("Apply changes to selected object", apply_selected, inspector)
	selection_actions = HBoxContainer.new()
	inspector.add_child(selection_actions)
	button("Duplicate", duplicate_selected, selection_actions)
	button("Delete object", delete_selected, selection_actions)
	layer_input.item_selected.connect(func(_index): update_preview())
	animate_input.toggled.connect(func(_value): update_preview())
	solid_input.toggled.connect(func(_value): update_preview())
	tiled_input.toggled.connect(func(_value): update_preview())
	game.status.reparent(columns)
	game.status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.status.custom_minimum_size = Vector2(600, 55)
	filter_catalog()

func update_mode() -> void:
	window.show()
	tabs.visible = game.editing
	play_help.visible = not game.editing
	mode_badge.text = "PLAYTEST" if not game.editing else ("PLACE ASSET · Click map to stamp" if mode == "stamp" else ("SELECT · Drag an object to move" if mode == "select" else "BUILD · Paint with the active tool"))
	undo_button.disabled = game.history.is_empty() or not game.editing
	redo_button.disabled = game.future.is_empty() or not game.editing
	var valid_selection := selected >= 0 and selected < objects().size()
	apply_button.disabled = not valid_selection or draft.is_empty()
	selection_actions.visible = valid_selection
	favorite_button.disabled = draft.is_empty()
	favorite_button.text = "Remove from favorites" if draft.get("asset", "") in favorites else "Add to favorites"

func reset_filters() -> void:
	search.text = ""
	category.select(0)
	browse_filter.select(0)
	filter_catalog()

func toggle_favorite() -> void:
	if draft.is_empty(): return
	if draft.asset in favorites: favorites.erase(draft.asset)
	else: favorites.append(draft.asset)
	filter_catalog()

func delete_selected() -> void:
	if selected < 0 or selected >= objects().size(): return
	game.snapshot()
	objects().remove_at(selected)
	selected = -1
	game.queue_redraw()

func duplicate_selected() -> void:
	if selected < 0 or selected >= objects().size(): return
	draft = objects()[selected].duplicate(true)
	place(Vector2(draft.pos[0], draft.pos[1]) + Vector2.ONE * S.OBJECT_SNAP_SIZE)

func filter_catalog() -> void:
	filtered.clear()
	var query := search.text.to_lower()
	var group := category.get_item_text(category.selected)
	for entry in catalog:
		if browse_filter.selected == 1 and entry.path not in favorites: continue
		if browse_filter.selected == 2 and entry.path not in recent: continue
		if category.selected != 0 and entry.category != group: continue
		if not query.is_empty() and not entry.path.to_lower().contains(query): continue
		filtered.append(entry)
	page = 0
	refresh_page()

func texture_for(path: String, frame: int = 0, crop: Array = []) -> AtlasTexture:
	if not metadata.has(path): return null
	var entry: Dictionary = metadata[path]
	var cache_key := path + ":" + str(posmod(frame, int(entry.frames))) + ":" + str(crop)
	if atlas_cache.has(cache_key): return atlas_cache[cache_key]
	if not cache.has(path): cache[path] = load(ROOT + path)
	var source: Texture2D = cache[path]
	if source == null: return null
	var width: float = float(entry.width) / entry.frames
	var region := Rect2(posmod(frame, int(entry.frames)) * width, 0, width, entry.height)
	if crop.size() == 4 and crop[2] > 0 and crop[3] > 0:
		var clipped := Rect2(crop[0], crop[1], crop[2], crop[3]).intersection(Rect2(0, 0, width, entry.height))
		if clipped.has_area(): region = Rect2(region.position + clipped.position, clipped.size)
	var result := AtlasTexture.new()
	result.atlas = source
	result.region = region
	result.filter_clip = true
	atlas_cache[cache_key] = result
	return result

func refresh_page() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for i in range(page * PAGE_SIZE, mini(filtered.size(), (page + 1) * PAGE_SIZE)):
		var entry: Dictionary = filtered[i]
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(145, 94)
		tile.text = entry.name.trim_prefix("spr").left(18)
		tile.tooltip_text = "%s\n%d frames | %d x %d" % [entry.path, entry.frames, entry.width / entry.frames, entry.height]
		tile.icon = texture_for(entry.path)
		tile.expand_icon = true
		tile.add_theme_constant_override("icon_max_width", 64)
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.focus_mode = Control.FOCUS_NONE
		tile.set_meta("asset_path", entry.path)
		tile.modulate = Color("60e4dc") if draft.get("asset", "") == entry.path else Color.WHITE
		tile.pressed.connect(func(): choose(entry.path))
		grid.add_child(tile)
	page_label.text = "  %d results | Page %d / %d" % [filtered.size(), page + 1, maxi(1, int(ceil(filtered.size() / float(PAGE_SIZE))))]

func choose(path: String) -> void:
	syncing_inspector = true
	draft = {"asset": path, "pos": [0.0, 0.0], "frame": 0, "scale": 1.0, "rotation": 0.0, "layer": 1, "animated": false, "solid": false, "crop": [0, 0, 0, 0]}
	var is_floor_plan: bool = metadata[path].category == "Floor Plans"
	var native_size := Vector2(float(metadata[path].width) / metadata[path].frames, metadata[path].height)
	scale_input.value = maxf(1.0, minf(S.FLOOR_PLAN_DEFAULT_SCALE, S.FLOOR_PLAN_TARGET_SIZE / maxf(native_size.x, native_size.y))) if is_floor_plan else 1.0
	rotation_input.value = 0
	layer_input.select(0 if is_floor_plan else 1)
	animate_input.button_pressed = false
	solid_input.button_pressed = false
	tiled_input.button_pressed = false
	frame_input.max_value = metadata[path].frames - 1
	frame_input.value = 0
	for control in crop_inputs: control.value = 0
	syncing_inspector = false
	use_stamp()
	for tile in grid.get_children():
		tile.modulate = Color("60e4dc") if tile.get_meta("asset_path", "") == path else Color.WHITE
	update_preview()
	game.queue_redraw()

func update_preview() -> void:
	if syncing_inspector or draft.is_empty() or crop_inputs.size() < 4: return
	if mode == "stamp" and tiled_input != null: read_draft()
	preview.texture = texture_for(draft.asset, int(frame_input.value), current_crop())
	var size := preview.texture.get_size() * scale_input.value
	description.text = "%s\n%d frames | %.0f x %.0f map pixels\nSelected: click on the map to place." % [draft.asset, metadata[draft.asset].frames, size.x, size.y]
	game.queue_redraw()

func current_crop() -> Array:
	var result: Array = []
	for control in crop_inputs: result.append(int(control.value))
	return result

func read_draft() -> void:
	if draft.is_empty(): return
	draft.frame = int(frame_input.value)
	draft.scale = scale_input.value
	draft.rotation = rotation_input.value
	draft.layer = layer_input.selected
	draft.animated = animate_input.button_pressed
	draft.solid = solid_input.button_pressed
	draft.crop = current_crop()
	draft["tiled"] = tiled_input.button_pressed
	draft["size"] = [width_input.value, height_input.value]

func use_stamp() -> void:
	read_draft()
	if draft.is_empty(): return
	mode = "stamp"
	window.show()
	game.painting = false
	window.release_focus()
	game.status.text = "STAMP: click to place / V select / B library / Esc terrain / Q,E rotate / [,] scale"

func apply_selected() -> void:
	if selected < 0 or selected >= objects().size() or draft.is_empty(): return
	read_draft()
	game.snapshot()
	var position: Array = objects()[selected].pos
	objects()[selected] = draft.duplicate(true)
	objects()[selected].pos = position
	window.release_focus()
	mode = "select"
	game.queue_redraw()

func open_browser() -> void:
	if not game.editing: return
	game.painting = false
	dragging = false
	window.show()
	tabs.current_tab = 2
	search.grab_focus()

func inspect_selected() -> void:
	if selected < 0 or selected >= objects().size(): return
	syncing_inspector = true
	draft = objects()[selected].duplicate(true)
	frame_input.max_value = metadata[draft.asset].frames - 1
	frame_input.value = draft.frame
	scale_input.value = draft.scale
	rotation_input.value = draft.rotation
	layer_input.select(draft.layer)
	animate_input.button_pressed = draft.animated
	solid_input.button_pressed = draft.solid
	tiled_input.button_pressed = draft.get("tiled", false)
	width_input.value = draft.get("size", [224, 168])[0]
	height_input.value = draft.get("size", [224, 168])[1]
	for i in 4: crop_inputs[i].value = draft.crop[i]
	syncing_inspector = false
	update_preview()
	open_browser()

func position_for(point: Vector2) -> Vector2:
	if snap_input.button_pressed:
		point = (point / S.OBJECT_SNAP_SIZE).round() * S.OBJECT_SNAP_SIZE
	return point.clamp(Vector2.ZERO, Vector2(game.Maps.WIDTH, game.Maps.HEIGHT) * game.SIZE - Vector2.ONE)

func place(point: Vector2) -> void:
	if draft.is_empty() or objects().size() >= S.MAX_MAP_OBJECTS: return
	game.snapshot()
	var item := draft.duplicate(true)
	var position := position_for(point)
	item.pos = [position.x, position.y]
	objects().append(item)
	selected = objects().size() - 1
	game.queue_redraw()

func local_point(item: Dictionary, point: Vector2) -> Vector2:
	return (point - Vector2(item.pos[0], item.pos[1])).rotated(-deg_to_rad(item.rotation)) / item.scale

func contains(item: Dictionary, point: Vector2) -> bool:
	var texture := texture_for(item.asset, item.frame, item.crop)
	if texture == null: return false
	var size := object_size(item, texture)
	return Rect2(-size / 2, size).has_point(local_point(item, point))

func object_size(item: Dictionary, texture: Texture2D) -> Vector2:
	if item.get("tiled", false): return Vector2(item.size[0], item.size[1])
	return texture.get_size()

func hit_test(point: Vector2) -> int:
	for layer in [2, 1, 0]:
		for i in range(objects().size() - 1, -1, -1):
			if objects()[i].layer == layer and contains(objects()[i], point): return i
	return -1

func is_solid(point: Vector2) -> bool:
	for item in game.map.get("objects", []):
		if item.solid and contains(item, point): return true
	return false

func handle_event(event: InputEvent) -> bool:
	if not game.editing: return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B: open_browser(); return true
		if event.keycode == KEY_V and not event.ctrl_pressed: mode = "select"; game.painting = false; return true
		if event.keycode == KEY_ESCAPE: mode = "terrain"; selected = -1; return true
		if mode == "terrain": return false
		if event.keycode == KEY_ENTER: inspect_selected(); return true
		if event.keycode == KEY_DELETE and selected >= 0 and selected < objects().size():
			game.snapshot(); objects().remove_at(selected); selected = -1; return true
		if event.ctrl_pressed and event.keycode == KEY_C and selected >= 0 and selected < objects().size():
			clipboard = objects()[selected].duplicate(true); return true
		if event.ctrl_pressed and event.keycode == KEY_V and not clipboard.is_empty():
			draft = clipboard.duplicate(true); mode = "stamp"; return true
		if event.ctrl_pressed and event.keycode == KEY_D and selected >= 0 and selected < objects().size():
			draft = objects()[selected].duplicate(true); place(Vector2(draft.pos[0], draft.pos[1]) + Vector2.ONE * S.OBJECT_SNAP_SIZE); return true
		if event.keycode in [KEY_Q, KEY_E, KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
			var item: Dictionary = draft if mode == "stamp" else (objects()[selected] if selected >= 0 and selected < objects().size() else {})
			if item.is_empty(): return true
			if mode == "select": game.snapshot()
			if event.keycode == KEY_Q: item.rotation -= S.OBJECT_ROTATION_STEP
			if event.keycode == KEY_E: item.rotation += S.OBJECT_ROTATION_STEP
			if event.keycode == KEY_BRACKETLEFT: item.scale = maxf(0.1, item.scale - 0.1)
			if event.keycode == KEY_BRACKETRIGHT: item.scale = minf(8, item.scale + 0.1)
			return true
	if mode == "terrain": return false
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if not event.pressed: dragging = false; return true
		if not game.MAP_VIEW.has_point(event.position): return false
		if event.button_index == MOUSE_BUTTON_RIGHT: mode = "select"; return true
		if mode == "stamp": place(game.mouse_world()); return true
		selected = hit_test(game.mouse_world())
		if selected >= 0:
			game.status.text = "%s / Enter or double-click: properties / Delete: remove" % objects()[selected].asset.get_file()
			if event.double_click: inspect_selected(); return true
			dragging = true
			drag_started = false
			drag_offset = Vector2(objects()[selected].pos[0], objects()[selected].pos[1]) - game.mouse_world()
		return true
	return false

func tick(delta: float) -> void:
	clock += delta
	update_mode()
	if not game.editing: return
	if dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): dragging = false; return
		if selected < 0 or selected >= objects().size(): dragging = false; return
		if not game.MAP_VIEW.has_point(game.get_global_mouse_position()): return
		var position := position_for(game.mouse_world() + drag_offset)
		if objects()[selected].pos != [position.x, position.y]:
			if not drag_started: game.snapshot(); drag_started = true
			objects()[selected].pos = [position.x, position.y]

func draw_item(item: Dictionary, ghost: bool = false) -> void:
	var frame: int = int(clock * S.OBJECT_ANIMATION_FPS) + int(item.frame) if item.animated else int(item.frame)
	var texture := texture_for(item.asset, frame, item.crop)
	if texture == null: return
	var position := Vector2(item.pos[0], item.pos[1])
	game.draw_set_transform(game.render_origin + position * game.view_zoom, deg_to_rad(item.rotation), Vector2.ONE * item.scale * game.view_zoom)
	var tint := Color(1, 1, 1, 0.55) if ghost else Color.WHITE
	if item.get("tiled", false):
		var extent := object_size(item, texture)
		var step := texture.get_size()
		for y in int(ceil(extent.y / step.y)):
			for x in int(ceil(extent.x / step.x)):
				var offset := Vector2(x, y) * step
				var clipped := (extent - offset).min(step)
				game.draw_texture_rect_region(texture, Rect2(-extent / 2 + offset, clipped), Rect2(Vector2.ZERO, clipped), tint)
	else:
		game.draw_texture(texture, -texture.get_size() / 2, tint)
	game.draw_set_transform(game.render_origin, 0, Vector2.ONE * game.view_zoom)

func draw_layer(layer: int) -> void:
	for item in game.map.get("objects", []):
		if item.layer == layer: draw_item(item)

func draw_tools() -> void:
	if not game.editing: return
	if mode == "stamp" and not draft.is_empty() and game.MAP_VIEW.has_point(game.get_global_mouse_position()):
		var item := draft.duplicate(true)
		var position := position_for(game.mouse_world())
		item.pos = [position.x, position.y]
		draw_item(item, true)
	if selected >= 0 and selected < objects().size() and mode != "terrain":
		var item: Dictionary = objects()[selected]
		var texture := texture_for(item.asset, item.frame, item.crop)
		if texture == null: return
		game.draw_set_transform(game.render_origin + Vector2(item.pos[0], item.pos[1]) * game.view_zoom, deg_to_rad(item.rotation), Vector2.ONE * item.scale * game.view_zoom)
		var size := object_size(item, texture)
		game.draw_rect(Rect2(-size / 2, size), Color("60e4dc"), false, 1.0 / item.scale)
		game.draw_set_transform(game.render_origin, 0, Vector2.ONE * game.view_zoom)
