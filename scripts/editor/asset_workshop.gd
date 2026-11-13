extends Node
const EditorVisualsSettings = preload("res://scripts/settings/editor_visuals_settings.gd")
const WeaponsSettings = preload("res://scripts/settings/weapons_settings.gd")
## Full asset library and non-destructive object layer for the map workshop.
const Icons = preload("res://scripts/editor/editor_icons.gd")
const ROOT := "res://HLM1 Files/"
var game: Node2D
var catalog: Array = []
const FLOOR_ATLAS := "Floor tiles/bacground0.png"
const ATLAS_CELL := 16
var atlas_tiles: Array = []
var room_layouts: Array = []
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
var atlas_painting := false
var atlas_stroke_saved := false
var atlas_previous := Vector2.ZERO
var atlas_visited: Dictionary = {}
var mode := "select"
var selected := -1
var weapon_properties: VBoxContainer
var build_atlas_grid: GridContainer
var entity_page: VBoxContainer
var selected_entity := ""
var selected_terrain := Vector2i(-1, -1)
var dragging := false
var drag_offset := Vector2.ZERO
var drag_started := false
var clipboard: Dictionary = {}
var clock := 0.0
var ui_refresh_time := 0.0
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
var select_tool: Button
var delete_tool: Button
var place_tool: Button
var build_layout_button: Button
var layouts_page: VBoxContainer
var layouts_list: ItemList
var layout_preview: TextureRect
var layout_summary: Label
var create_layout_button: Button
var insert_layout_button: Button
var insertion_layout: Dictionary = {}
var insertion_bounds := Rect2i()
var generated_layout: Dictionary = {}
var sidebar_visible := true
var sidebar_button: Button
var play_lab_panel: PanelContainer
var play_lab: VBoxContainer
var construction_section: VBoxContainer
var library_page: VBoxContainer
var detail_page: VBoxContainer
var undo_button: Button
var redo_button: Button
var assets_nav: Button
var build_nav: Button
var advanced_properties: VBoxContainer

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
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial", "sans-serif"])
	theme.default_font = font
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("222e3b") if state == "normal" else (Color("164d49") if state == "pressed" else Color("304354"))
		if state == "disabled": box.bg_color = Color("1c2532")
		box.set_corner_radius_all(5)
		box.set_border_width_all(1)
		box.border_color = Color("344452") if state == "normal" else Color("507385")
		if state == "pressed": box.border_color = Color("45978a")
		if state == "disabled": box.border_color = Color("293440")
		box.content_margin_left = 7
		box.content_margin_right = 7
		box.content_margin_top = 2
		box.content_margin_bottom = 2
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.set_border_width_all(1)
			box.border_color = Color("60e4dc")
		theme.set_stylebox(state, "Button", box)
	for control_type in ["PanelContainer", "TabContainer", "PopupMenu"]:
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color("182230")
		panel.set_corner_radius_all(0)
		panel.set_border_width_all(1)
		panel.border_color = Color("334255")
		theme.set_stylebox("panel", control_type, panel)
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var tab := StyleBoxFlat.new()
		tab.bg_color = Color("205955") if state == "tab_selected" else Color("182230")
		tab.content_margin_left = 24
		tab.content_margin_right = 24
		tab.content_margin_top = 9
		tab.content_margin_bottom = 9
		tab.set_border_width_all(1)
		tab.border_color = Color("334255")
		theme.set_stylebox(state, "TabContainer", tab)
	var field := StyleBoxFlat.new()
	field.bg_color = Color("101923")
	field.set_border_width_all(1)
	field.set_corner_radius_all(6)
	field.border_color = Color("34465c")
	field.content_margin_right = 8
	field.content_margin_left = 8
	field.content_margin_top = 4
	field.content_margin_bottom = 4
	theme.set_stylebox("normal", "LineEdit", field)
	var focused_field := field.duplicate()
	focused_field.border_color = Color("45978a")
	theme.set_stylebox("focus", "LineEdit", focused_field)
	for control_type in ["Button", "OptionButton"]:
		theme.set_color("font_hover_color", control_type, Color("ffffff"))
		theme.set_color("font_pressed_color", control_type, Color("a4f4dc"))
		theme.set_color("icon_normal_color", control_type, Color("a4b7c5"))
		theme.set_color("icon_hover_color", control_type, Color("e7ffff"))
		theme.set_color("icon_pressed_color", control_type, Color("8ce8ce"))
		theme.set_constant("h_separation", control_type, 8)
	theme.set_constant("separation", "VBoxContainer", 5)
	theme.set_constant("h_separation", "GridContainer", 8)
	theme.set_constant("v_separation", "GridContainer", 8)
	for control_type in ["Button", "Label", "LineEdit", "OptionButton", "CheckBox"]:
		theme.set_color("font_color", control_type, Color("e0e8f3"))
		theme.set_color("font_disabled_color", control_type, Color("718096"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "OptionButton", theme.get_stylebox(state, "Button"))
	var empty_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color.TRANSPARENT)
	var empty_icon := ImageTexture.create_from_image(empty_image)
	for icon_name in ["updown", "up", "down", "up_hover", "down_hover", "up_pressed", "down_pressed", "up_disabled", "down_disabled"]:
		theme.set_icon(icon_name, "SpinBox", empty_icon)
	theme.set_constant("buttons_vertical_separation", "SpinBox", 0)
	window.theme = theme

func _ready() -> void:
	game = get_parent()
	var text := FileAccess.get_file_as_string("res://assets/catalog.json").trim_prefix("\ufeff")
	var value: Variant = JSON.parse_string(text)
	if value is Array: catalog = value
	for entry in catalog:
		entry.category = preload("res://scripts/editor/asset_categories.gd").category_for(entry.path)
		metadata[entry.path] = entry
	# Source sheets remain in metadata for saved maps, but only usable weapons are browsable.
	catalog = catalog.filter(func(entry): return entry.category not in ["Weapons / guns and melee", "Floor tiles"])
	var weapons = preload("res://scripts/game/player_weapons.gd")
	for kind in weapons.PICKUPS:
		var entry: Dictionary = metadata[weapons.pickup_asset(kind)].duplicate(true)
		entry.category = "Weapons"
		entry.name = kind.capitalize()
		entry.frame = weapons.drop_frame(kind)
		entry.pickup_kind = kind
		catalog.append(entry)
	var layouts: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/layouts.json"))
	if layouts is Array: room_layouts = layouts
	build_atlas_tiles()
	build_browser()
	activate_select()
	update_mode()

func build_atlas_tiles() -> void:
	var texture: Texture2D = load(ROOT + FLOOR_ATLAS)
	var image := texture.get_image()
	for y in range(0, image.get_height(), ATLAS_CELL):
		for x in range(0, image.get_width(), ATLAS_CELL):
			var populated := false
			for py in range(y, mini(y + ATLAS_CELL, image.get_height())):
				for px in range(x, mini(x + ATLAS_CELL, image.get_width())):
					var color := image.get_pixel(px, py)
					if color.a > 0 and not (color.r8 == 0 and color.g8 == 128 and color.b8 == 64):
						populated = true
						break
				if populated: break
			if populated:
				atlas_tiles.append({"path": FLOOR_ATLAS, "category": "Atlas tiles (16 px)", "name": "Tile %02d,%02d" % [x / ATLAS_CELL + 1, y / ATLAS_CELL + 1], "width": 16, "height": 16, "frames": 1, "crop": [x, y, ATLAS_CELL, ATLAS_CELL]})

func objects() -> Array:
	if not game.map.has("objects"): game.map.objects = []
	return game.map.objects

func button(text: String, action: Callable, parent: Node) -> Button:
	var control := Button.new()
	control.text = text
	var icon_actions := {"Save": "save", "Load": "load", "Undo": "undo", "Redo": "redo", "Playtest": "play", "Grid": "grid", "Fit": "fit", "Build tools": "build", "Select": "select", "Place": "stamp", "Library": "library", "< Back": "back", "Rotate": "rotate", "Duplicate": "copy", "Delete": "delete", "Apply": "check", "Paint": "brush", "Room": "build", "Outline": "build", "Fill": "fill", "Floor tiles": "grid"}
	for prefix in icon_actions:
		if text.begins_with(prefix):
			control.icon = Icons.get_icon(icon_actions[prefix])
			break
	if control.icon == null:
		var extra := {"Assets": "library", "Build": "build", "Browse": "library", "Layouts": "build", "New": "build", "Check": "check", "Pick": "select", "Enclosed": "build", "Hide sidebar": "sidebar", "Show sidebar": "sidebar", "Previous": "back", "Next": "next", "Carpet": "grid", "Wood": "grid", "Tile": "grid", "Floors": "grid", "Add to favorites": "star", "Remove from favorites": "star"}
		control.icon = Icons.get_icon("settings")
		for prefix in extra:
			if text.begins_with(prefix): control.icon = Icons.get_icon(extra[prefix]); break
	control.add_theme_constant_override("icon_max_width", 16)
	control.custom_minimum_size.y = 27
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	label.custom_minimum_size.x = 180
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = initial
	control.custom_minimum_size.x = 80
	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	control.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(control)
	control.value_changed.connect(func(_v): update_preview())
	return control

func build_browser() -> void:
	window = PanelContainer.new()
	window.position = Vector2(1480, 44)
	window.size = Vector2(440, 1036)
	style_dock()
	add_child(window)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 10)
	window.add_child(margin)
	var columns := VBoxContainer.new()
	margin.add_child(columns)
	var top_bar := PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(1920, 44)
	top_bar.theme = window.theme
	add_child(top_bar)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	var toolbar_margin := MarginContainer.new()
	for side in ["left", "right"]: toolbar_margin.add_theme_constant_override("margin_" + side, 10)
	for side in ["top", "bottom"]: toolbar_margin.add_theme_constant_override("margin_" + side, 4)
	top_bar.add_child(toolbar_margin)
	toolbar_margin.add_child(toolbar)
	var heading := Label.new()
	heading.text = "  PROJECT GAGUGAGA  "
	heading.modulate = Color("77e2cb")
	toolbar.add_child(heading)
	game.title_input.reparent(toolbar)
	game.title_input.custom_minimum_size.x = 240
	game.title_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("Save", func(): game.choose_file("save"), toolbar).tooltip_text = "Save map (Ctrl+S)"
	button("Load", func(): game.choose_file("load"), toolbar).tooltip_text = "Open map (Ctrl+O)"
	undo_button = button("Undo", game.undo, toolbar)
	redo_button = button("Redo", game.redo, toolbar)
	button("Fit map", func(): game.fit_map(), toolbar)
	game.toggle_button = button("Playtest [Tab]", game.toggle_mode, toolbar)
	game.toggle_button.modulate = Color("60e4dc")
	mode_badge = Label.new()
	columns.add_child(mode_badge)
	mode_badge.hide()
	mode_badge.add_theme_color_override("font_color", Color("60e4dc"))
	var editing_modes := HBoxContainer.new()
	columns.add_child(editing_modes)
	select_tool = button("Select / move [V]", activate_select, editing_modes)
	select_tool.tooltip_text = "Click a placed object to inspect it. Drag it to move. Escape opens the pause menu."
	select_tool.toggle_mode = true
	delete_tool = button("Delete", func(): mode = "erase"; game.painting = false; game.rectangle_mode = false; game.status.text = "Click an object, wall or tile to erase. Ctrl+Z restores it. Esc opens the pause menu.", editing_modes)
	delete_tool.tooltip_text = "Activate the eraser, then click something on the map. Ctrl+Z restores it."
	delete_tool.toggle_mode = true
	delete_tool.disabled = true
	place_tool = button("Place asset", use_stamp, editing_modes)
	place_tool.tooltip_text = "Place copies of the current asset. Pick an asset in the library first."
	place_tool.toggle_mode = true
	place_tool.hide()
	var navigation := HBoxContainer.new()
	columns.add_child(navigation)
	assets_nav = button("Assets [B]", open_browser, navigation)
	build_nav = button("Build", show_build_page, navigation)
	assets_nav.toggle_mode = true
	build_nav.toggle_mode = true
	play_help = Label.new()
	play_help.text = "PLAYTEST\n\nWASD: move / Mouse: aim\nLeft click: attack / Right click: throw\nE: pick up / F: melee / Space: door\nR: reload / T: restart\n\nTab: return to editing"
	play_help.visible = false
	columns.add_child(play_help)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(tabs)
	var map_tab := VBoxContainer.new()
	map_tab.name = "LEVEL"
	tabs.add_child(map_tab)
	section("MAP ACTIONS", map_tab)
	button("New blank map", func(): game.replace_map(game.Maps.small_blank()); game.fit_map(); activate_select(), map_tab)
	var build_tab := VBoxContainer.new()
	build_tab.name = "BUILD"
	tabs.add_child(build_tab)
	section("BUILD YOUR MAP", build_tab)
	var build_help := Label.new()
	build_help.text = "Choose a surface or structure below.
Selecting this tab alone never starts painting."
	build_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_tab.add_child(build_help)
	section("FLOORS", build_tab)
	var atlas_scroll := ScrollContainer.new()
	atlas_scroll.custom_minimum_size.y = 192
	atlas_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_tab.add_child(atlas_scroll)
	build_atlas_grid = GridContainer.new()
	build_atlas_grid.columns = 9
	build_atlas_grid.add_theme_constant_override("h_separation", 3)
	build_atlas_grid.add_theme_constant_override("v_separation", 3)
	atlas_scroll.add_child(build_atlas_grid)
	var floor_tools := GridContainer.new()
	floor_tools.columns = 3
	build_tab.add_child(floor_tools)
	section("WALLS & DOORS", build_tab)
	var structure_tools := GridContainer.new()
	structure_tools.columns = 2
	build_tab.add_child(structure_tools)
	var door_help := Label.new()
	door_help.text = "Walls connect automatically. Place a door in a wall.
Deleting a wall preserves the floor underneath."
	door_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_tab.add_child(door_help)
	section("DRAWING TOOLS", build_tab)
	var room_tools := GridContainer.new()
	room_tools.columns = 2
	build_tab.add_child(room_tools)
	for tool_name in ["Room", "Fill", "Sample"]:
		var tool_id: String = tool_name.to_lower()
		var tool_label: String = {"Paint": "Freehand brush", "Room": "Enclosed room", "Outline": "Wall rectangle", "Fill": "Fill floor", "Sample": "Pick floor material"}[tool_name]
		var action := button(tool_label, func():
			mode = "terrain"
			if tool_id in ["room", "fill"] and game.brush not in [1, 7, 8]: game.select_brush(1)
			if tool_id == "outline": game.select_brush(2)
			game.layout_tool = tool_id
			game.painting = false
			game.rectangle_mode = false
			game.status.text = "%s / %s" % [tool_label, "Drag a rectangle." if tool_id in ["room", "outline"] else "Click on the map."]
		, room_tools)
		action.tooltip_text = "Floor with perimeter walls" if tool_id == "room" else ("Perimeter walls only; interior is preserved" if tool_id == "outline" else tool_label)
	button("Browse room layouts", show_room_layouts, build_tab)
	section("PLAYER & OBJECTIVES", build_tab)
	var marker_tools := GridContainer.new()
	marker_tools.columns = 2
	build_tab.add_child(marker_tools)
	var hidden_tools := VBoxContainer.new()
	build_tab.add_child(hidden_tools)
	hidden_tools.hide()
	var names := ["Empty", "Carpet", "Wall", "Player start", "Enemy", "Exit", "Erase", "Wood", "Tile", "Door", "Sofa"]
	for i in names.size():
		var index := i
		var parent: Control = floor_tools if i in [1, 7, 8] else (structure_tools if i in [2, 9] else (marker_tools if i in [3, 5] else hidden_tools))
		var tool := button(names[i], func(): game.select_brush(index), parent)
		tool.custom_minimum_size.y = 30
		tool.tooltip_text = "Click to select; draw on the map. Shift + drag: rectangle."
		var icons := {2: "wall", 3: "player_gun", 5: "exit", 9: "door"}
		if icons.has(i):
			tool.icon = game.art.frame(icons[i])
			tool.expand_icon = true
			tool.add_theme_constant_override("icon_max_width", 28)
		game.palette.append(tool)
	button("Browse enemies", func():
		open_browser()
		search.text = ""
		for i in category.item_count:
			if category.get_item_text(i) == "Enemies that are alive": category.select(i)
		filter_catalog()
	, build_tab)
	button("Check routes", game.check_routes, build_tab)
	var assets_tab := VBoxContainer.new()
	assets_tab.name = "ITEMS"
	tabs.add_child(assets_tab)
	tabs.current_tab = 2
	var library := VBoxContainer.new()
	library_page = library
	library.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	library.custom_minimum_size.y = 390
	library.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assets_tab.add_child(library)
	var filters := VBoxContainer.new()
	library.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "Search assets..."
	search.clear_button_enabled = true
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(search)
	search.text_changed.connect(func(_text): filter_catalog())
	category = OptionButton.new()
	category.add_item("All categories")
	var categories: Array = []
	for entry in catalog:
		if entry.category != "Floor Plans" and entry.category not in categories: categories.append(entry.category)
	categories.sort()
	for name in categories: category.add_item(name)
	category.add_item("Atlas tiles (16 px)")
	filters.add_child(category)
	category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category.select(categories.find("Furniture") + 1)
	category.item_selected.connect(func(_index): filter_catalog())
	var quick_filters := HBoxContainer.new()
	library.add_child(quick_filters)
	browse_filter = OptionButton.new()
	for name in ["All assets", "Favorites", "Recently used"]: browse_filter.add_item(name)
	browse_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick_filters.add_child(browse_filter)
	browse_filter.hide()
	var filter_menu := MenuButton.new()
	filter_menu.text = "Show: All assets"
	filter_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick_filters.add_child(filter_menu)
	for label in ["All assets", "Favorites", "Recently used"]: filter_menu.get_popup().add_item(label)
	filter_menu.get_popup().id_pressed.connect(func(id):
		browse_filter.select(id)
		filter_menu.text = "Show: " + filter_menu.get_popup().get_item_text(id)
		filter_catalog())
	browse_filter.item_selected.connect(func(_index): filter_catalog())
	button("Floors", show_atlas_tiles, quick_filters)
	button("Layouts", show_room_layouts, toolbar)
	sidebar_button = button("Hide sidebar", func(): sidebar_visible = not sidebar_visible; update_mode(), toolbar)
	sidebar_button.tooltip_text = "Show or hide the editor / Developer Lab sidebar"
	var settings_button := button("", func(): game.pause_menu.open_settings(), toolbar)
	settings_button.name = "SettingsButton"
	settings_button.icon = Icons.get_icon("gear")
	settings_button.tooltip_text = "Settings ? editor, display and audio"
	settings_button.custom_minimum_size.x = 32
	# Only the map name grows; action buttons keep their natural width.
	for item in toolbar.get_children():
		if item is Button: item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	empty_results = Label.new()
	empty_results.text = "No matching assets. Clear the search or choose All categories."
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
	inspector_scroll.custom_minimum_size.x = 0
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_page = VBoxContainer.new()
	detail_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assets_tab.add_child(detail_page)
	button("< Back to library", show_library_page, detail_page)
	detail_page.add_child(inspector_scroll)
	detail_page.hide()
	var inspector := VBoxContainer.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inspector_padding := MarginContainer.new()
	inspector_padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]: inspector_padding.add_theme_constant_override("margin_" + side, 16)
	inspector_scroll.add_child(inspector_padding)
	inspector_padding.add_child(inspector)
	var rotation_tools := HBoxContainer.new()
	detail_page.add_child(rotation_tools)
	rotation_tools.hide() # Rotation field and Q/E already provide this action.
	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 44)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inspector.add_child(preview)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 0
	inspector.add_child(description)
	description.text = "Click a thumbnail to start placing it on the map."
	build_layout_button = button("Build this layout as a map", build_selected_layout, inspector)
	build_layout_button.tooltip_text = "Replace this floor with editable terrain, doors and windows. Ctrl+Z restores the previous map."
	build_layout_button.hide()
	section("PROPERTIES", inspector)
	weapon_properties = VBoxContainer.new()
	inspector.add_child(weapon_properties)
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
	solid_input.text = "Blocks movement"
	inspector.add_child(solid_input)
	snap_input = CheckBox.new()
	snap_input.text = "Snap to grid"
	snap_input.button_pressed = game.preferences.snap_objects
	snap_input.toggled.connect(func(enabled): game.preferences.snap_objects = enabled; game.preferences.save())
	inspector.add_child(snap_input)
	var advanced := foldout("Advanced", inspector)
	advanced_properties = advanced
	favorite_button.reparent(advanced)
	frame_input.get_parent().reparent(advanced)
	layer_input.reparent(advanced)
	animate_input.reparent(advanced)
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
	place_tool.reparent(inspector)
	place_tool.text = "Placing - click the map"
	place_tool.show()
	apply_button = button("Apply changes", apply_selected, inspector)
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
	game.status.custom_minimum_size = Vector2(0, 36)
	game.status.max_lines_visible = 2
	game.status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	game.status.add_theme_font_size_override("font_size", 14)
	map_tab.reparent(build_tab)
	map_tab.show()
	var construction := VBoxContainer.new()
	construction_section = construction
	construction.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(construction)
	columns.move_child(construction, tabs.get_index())
	construction.hide()
	var build_scroll := ScrollContainer.new()
	build_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	construction.add_child(build_scroll)
	build_tab.reparent(build_scroll)
	build_tab.show()
	build_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.tabs_visible = false
	tabs.current_tab = 0
	layouts_page = VBoxContainer.new()
	layouts_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assets_tab.add_child(layouts_page)
	button("< Back to library", show_library_page, layouts_page)
	section("NEW MAP FROM LAYOUT", layouts_page)
	layouts_list = ItemList.new()
	layouts_list.custom_minimum_size.y = 200
	layouts_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layouts_list.fixed_icon_size = Vector2i(64, 48)
	layouts_page.add_child(layouts_list)
	for entry in room_layouts: layouts_list.add_item(entry.name, texture_for(entry.path, int(entry.frame)))
	layouts_list.item_selected.connect(select_layout)
	layout_preview = TextureRect.new()
	layout_preview.custom_minimum_size = Vector2(0, 44)
	layout_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layout_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layouts_page.add_child(layout_preview)
	layout_summary = Label.new()
	layout_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layouts_page.add_child(layout_summary)
	var layout_actions := HBoxContainer.new()
	layouts_page.add_child(layout_actions)
	create_layout_button = button("Create map from layout", create_layout_map, layout_actions)
	insert_layout_button = button("Insert map layout", begin_layout_insert, layout_actions)
	create_layout_button.modulate = Color("ffb766")
	insert_layout_button.modulate = Color("60e4dc")
	create_layout_button.tooltip_text = "Replace the entire current map."
	insert_layout_button.tooltip_text = "Position this layout in the current map, then click to insert."
	insert_layout_button.disabled = true
	create_layout_button.disabled = true
	layouts_page.hide()
	filter_catalog()
	play_lab_panel = PanelContainer.new()
	play_lab_panel.position = Vector2(1480, 44)
	play_lab_panel.size = Vector2(440, 1036)
	play_lab_panel.theme = window.theme
	add_child(play_lab_panel)
	var lab_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: lab_margin.add_theme_constant_override("margin_" + side, 10)
	play_lab_panel.add_child(lab_margin)
	play_lab = preload("res://scripts/ui/developer_lab.gd").new()
	play_lab.compact = true
	lab_margin.add_child(play_lab)
	play_lab_panel.hide()

func show_build_page() -> void:
	populate_build_atlas()
	if entity_page != null: entity_page.hide()
	if not game.editing: return
	sidebar_visible = true
	construction_section.show()
	tabs.hide()
	activate_select()
	game.status.text = "Select a floor, wall, door or drawing tool to start building."
	update_mode()

func activate_select() -> void:
	atlas_painting = false
	mode = "select"
	dragging = false
	game.painting = false
	game.rectangle_mode = false
	game.status.text = "Click an object to see its properties. Drag to move; Delete to remove."
	game.queue_redraw()

func update_mode() -> void:
	game.set_sidebar_visible(sidebar_visible)
	window.visible = game.editing and sidebar_visible
	if play_lab_panel != null:
		if not game.editing and sidebar_visible and not play_lab_panel.visible: play_lab.rebuild()
		play_lab_panel.visible = not game.editing and sidebar_visible
	if sidebar_button != null: sidebar_button.text = "Hide sidebar" if sidebar_visible else "Show sidebar"
	tabs.visible = game.editing and not construction_section.visible
	assets_nav.set_pressed_no_signal(not construction_section.visible)
	build_nav.set_pressed_no_signal(construction_section.visible)
	game.status.tooltip_text = game.status.text
	play_help.visible = not game.editing
	mode_badge.text = "PLAYTEST" if not game.editing else ("PLACE ASSET · Click map to stamp" if mode == "stamp" else ("SELECT · Drag an object to move" if mode == "select" else "BUILD · Paint with the active tool"))
	select_tool.set_pressed_no_signal(mode == "select")
	place_tool.set_pressed_no_signal(mode == "stamp")
	select_tool.disabled = not game.editing
	place_tool.disabled = draft.is_empty() or not game.editing or is_map_layout()
	build_layout_button.visible = is_map_layout()
	apply_button.visible = mode == "select"
	place_tool.visible = mode != "select"
	place_tool.text = "Placing - click the map" if mode == "stamp" else "Place on map"
	if mode == "insert_layout": mode_badge.text = "INSERT LAYOUT / Click to place; Esc cancels"
	if mode == "erase": mode_badge.text = "DELETE / Click something on the map"
	undo_button.disabled = game.history.is_empty() or not game.editing
	redo_button.disabled = game.future.is_empty() or not game.editing
	var valid_selection := selected >= 0 and selected < objects().size()
	delete_tool.disabled = not game.editing
	delete_tool.set_pressed_no_signal(mode == "erase")
	apply_button.disabled = not valid_selection or draft.is_empty()
	selection_actions.visible = valid_selection
	favorite_button.disabled = draft.is_empty()
	favorite_button.text = "Remove from favorites" if draft.get("asset", "") in favorites else "Add to favorites"

func reset_filters() -> void:
	search.text = ""
	category.select(0)
	browse_filter.select(0)
	filter_catalog()

func show_atlas_tiles() -> void:
	search.text = ""
	browse_filter.select(0)
	for i in category.item_count:
		if category.get_item_text(i) == "Atlas tiles (16 px)": category.select(i)
	filter_catalog()

func show_room_layouts() -> void:
	if entity_page != null: entity_page.hide()
	construction_section.hide()
	tabs.show()
	sync_navigation()
	if not game.editing: return
	activate_select()
	library_page.hide()
	detail_page.hide()
	layouts_page.show()
	if layouts_list.is_anything_selected(): return
	if not room_layouts.is_empty():
		layouts_list.select(0)
		select_layout(0)

func select_layout(index: int) -> void:
	var entry: Dictionary = room_layouts[index]
	generated_layout = game.Maps.from_layout(entry.path, int(entry.frame), int(metadata[entry.path].frames))
	var error: String = game.Maps.validate(generated_layout)
	var supported: bool = generated_layout.name != "Untitled floor" and error.is_empty()
	create_layout_button.disabled = not supported
	insert_layout_button.disabled = not supported
	layout_summary.text = "%s / %d doors / %d windows\nCreate replaces this floor. Undo restores it." % [entry.name, generated_layout.cells.count(5), generated_layout.objects.size()] if supported else "This frame has too little usable floor. Choose another layout."
	var image := Image.create(game.Maps.WIDTH * 8, game.Maps.HEIGHT * 8, false, Image.FORMAT_RGBA8)
	image.fill(Color("10222a"))
	for y in game.Maps.HEIGHT:
		for x in game.Maps.WIDTH:
			var tile: int = generated_layout.cells[y * game.Maps.WIDTH + x]
			var color := Color("a6baa2") if tile in [1, 3, 4] else (Color("fff1cb") if tile == 2 else Color("f179af"))
			if tile != 0: image.fill_rect(Rect2i(x * 8, y * 8, 8, 8), color)
	layout_preview.texture = ImageTexture.create_from_image(image)

func begin_layout_insert() -> void:
	if not game.editing or generated_layout.is_empty() or insert_layout_button.disabled: return
	insertion_layout = generated_layout.duplicate(true)
	game.Maps.ensure_floor_layer(insertion_layout)
	var low := Vector2i(game.Maps.WIDTH, game.Maps.HEIGHT)
	var high := Vector2i.ZERO
	for y in game.Maps.HEIGHT:
		for x in game.Maps.WIDTH:
			if insertion_layout.cells[y * game.Maps.WIDTH + x] != 0:
				low = low.min(Vector2i(x, y)); high = high.max(Vector2i(x + 1, y + 1))
	insertion_bounds = Rect2i(low, high - low)
	mode = "insert_layout"
	game.painting = false
	game.rectangle_mode = false
	game.status.text = "INSERT LAYOUT / Move preview, click to place. Red means out of bounds or an actor would be covered. Esc opens the pause menu."

func insertion_offset(point: Vector2) -> Vector2i:
	return Vector2i((point / game.SIZE).floor()) - insertion_bounds.position - insertion_bounds.size / 2

func insertion_valid(offset: Vector2i) -> bool:
	if insertion_layout.is_empty(): return false
	for y in range(insertion_bounds.position.y, insertion_bounds.end.y):
		for x in range(insertion_bounds.position.x, insertion_bounds.end.x):
			var tile: int = insertion_layout.cells[y * game.Maps.WIDTH + x]
			if tile == 0: continue
			var target := Vector2i(x, y) + offset
			if not game.inside(target): return false
			if not game.Maps.floor_tile(tile) and [target.x, target.y] in [game.map.spawn, game.map.exit] + game.map.enemies: return false
	if objects().size() + insertion_layout.objects.size() > EditorVisualsSettings.MAX_MAP_OBJECTS: return false
	return true

func insert_layout_at(point: Vector2) -> bool:
	var offset := insertion_offset(point)
	if not insertion_valid(offset):
		game.status.text = "Cannot insert here: keep the layout inside the map and clear of player/enemy/exit markers."
		return false
	game.snapshot()
	game.Maps.ensure_floor_layer(game.map)
	for y in range(insertion_bounds.position.y, insertion_bounds.end.y):
		for x in range(insertion_bounds.position.x, insertion_bounds.end.x):
			var source: int = y * game.Maps.WIDTH + x
			if insertion_layout.cells[source] == 0: continue
			var target := Vector2i(x, y) + offset
			var index: int = target.y * game.Maps.WIDTH + target.x
			game.map.get("floor_clips", {}).erase(str(index))
			game.map.get("floor_shapes", {}).erase(str(index))
			game.map.cells[index] = insertion_layout.cells[source]
			game.map.floors[index] = insertion_layout.floors[source]
	for original in insertion_layout.objects:
		var item: Dictionary = original.duplicate(true)
		item.pos = [item.pos[0] + offset.x * game.SIZE, item.pos[1] + offset.y * game.SIZE]
		objects().append(item)
	activate_select()
	game.status.text = "Layout inserted. Existing start, exit and enemies retained. Ctrl+Z undoes insertion."
	game.queue_redraw()
	return true

func create_layout_map() -> void:
	if not game.editing or generated_layout.is_empty() or create_layout_button.disabled: return
	game.replace_map(generated_layout.duplicate(true))
	activate_select()
	game.editor_center = Vector2(game.Maps.WIDTH, game.Maps.HEIGHT) * game.SIZE / 2.0
	game.editor_zoom = 1.0
	game.status.text = "Created " + game.map.name + ". Ctrl+Z restores the previous map."
	show_library_page()

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
	place(Vector2(draft.pos[0], draft.pos[1]) + Vector2.ONE * EditorVisualsSettings.OBJECT_SNAP_SIZE)

func filter_catalog() -> void:
	filtered.clear()
	var query := search.text.to_lower()
	var group := category.get_item_text(category.selected)
	for entry in catalog + atlas_tiles:
		if entry.category == "Floor Plans": continue
		if browse_filter.selected == 1 and entry.path not in favorites: continue
		if browse_filter.selected == 2 and entry.path not in recent: continue
		if category.selected != 0 and entry.category != group: continue
		if not query.is_empty() and not (entry.path + " " + entry.name).to_lower().contains(query): continue
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

var weapon_icon_cache: Dictionary = {}
func weapon_icon(kind: String) -> Texture2D:
	if weapon_icon_cache.has(kind): return weapon_icon_cache[kind]
	var weapons = preload("res://scripts/game/player_weapons.gd")
	var texture: Texture2D = texture_for(weapons.pickup_asset(kind), weapons.drop_frame(kind))
	if weapons.BIG_FRAMES.has(kind): texture = texture_for("Weapons/sprBigWeapons_strip23.png", weapons.BIG_FRAMES[kind])
	var image := texture.get_image()
	var bounds := image.get_used_rect()
	if bounds.has_area(): image = image.get_region(bounds)
	var factor := minf(100.0 / image.get_width(), 44.0 / image.get_height())
	image.resize(maxi(1, int(image.get_width() * factor)), maxi(1, int(image.get_height() * factor)), Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(110, 52, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), (canvas.get_size() - image.get_size()) / 2)
	var result := ImageTexture.create_from_image(canvas)
	weapon_icon_cache[kind] = result
	return result

func asset_label(raw: String) -> String:
	var label := raw.trim_prefix("spr").get_slice("_strip", 0)
	var words := RegEx.new()
	words.compile("([a-z])([A-Z])")
	return words.sub(label, "$1 $2", true).replace("_", " ").capitalize()

func sync_navigation() -> void:
	if assets_nav == null or build_nav == null: return
	assets_nav.set_pressed_no_signal(not construction_section.visible)
	build_nav.set_pressed_no_signal(construction_section.visible)

func refresh_page() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for i in range(page * PAGE_SIZE, mini(filtered.size(), (page + 1) * PAGE_SIZE)):
		var entry: Dictionary = filtered[i]
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(145, 80)
		tile.text = asset_label(entry.name)
		tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.tooltip_text = ("%s ? %s\nPlace on map ? E to pick up ? Left click to use ? Right click to throw" % [entry.name, preload("res://scripts/game/player_weapons.gd").family(entry.pickup_kind).capitalize()]) if entry.has("pickup_kind") else "%s\n%d frames | %d x %d" % [entry.path, entry.frames, entry.width / entry.frames, entry.height]
		tile.icon = weapon_icon(entry.pickup_kind) if entry.has("pickup_kind") else texture_for(entry.path, int(entry.get("frame", 0)), entry.get("crop", []))
		tile.expand_icon = true
		tile.add_theme_constant_override("icon_max_width", 110 if entry.has("pickup_kind") else 64)
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.focus_mode = Control.FOCUS_NONE
		tile.set_meta("asset_path", entry.path)
		tile.set_meta("asset_crop", entry.get("crop", [0, 0, 0, 0]))
		tile.modulate = Color("60e4dc") if (draft.get("pickup_kind", "") == entry.pickup_kind if entry.has("pickup_kind") else draft.get("asset", "") == entry.path) else Color.WHITE
		tile.pressed.connect(func(): choose_entry(entry))
		grid.add_child(tile)
	page_label.text = "  %d results | Page %d / %d" % [filtered.size(), page + 1, maxi(1, int(ceil(filtered.size() / float(PAGE_SIZE))))]
	previous_button.disabled = page == 0
	next_button.disabled = (page + 1) * PAGE_SIZE >= filtered.size()
	empty_results.visible = filtered.is_empty()

func choose_tile(entry: Dictionary) -> void:
	choose(entry.path)
	syncing_inspector = true
	for i in 4: crop_inputs[i].value = entry.crop[i]
	scale_input.value = float(game.SIZE) / ATLAS_CELL
	layer_input.select(0)
	syncing_inspector = false
	read_draft()
	update_preview()
	for tile in grid.get_children():
		tile.modulate = Color("60e4dc") if tile.get_meta("asset_crop", []) == entry.crop else Color.WHITE
	game.status.text = "%s / Click: place / Wheel: resize / Ctrl+wheel: zoom" % entry.name

func choose_entry(entry: Dictionary) -> void:
	if entry.has("crop"):
		choose_tile(entry)
		return
	choose(entry.path)
	if entry.has("frame"):
		frame_input.value = entry.frame
		read_draft()
		update_preview()
		game.status.text = "%s / Click to place." % entry.name
	if entry.has("pickup_kind"):
		draft["pickup_kind"] = entry.pickup_kind
		draft.solid = false
		draft.layer = 1
		scale_input.value = WeaponsSettings.WEAPON_SPRITE_SCALE * WeaponsSettings.DROP_PICKUP_SCALE
		frame_input.editable = false
		animate_input.disabled = true
		animate_input.button_pressed = false
		read_draft()
		update_preview()
		game.status.text = "%s / Place a usable pickup, then E to collect in playtest." % entry.name

func choose(path: String) -> void:
	frame_input.editable = true
	animate_input.disabled = false
	show_detail_page()
	selected = -1
	dragging = false
	recent.erase(path)
	recent.push_front(path)
	if recent.size() > 40: recent.pop_back()
	syncing_inspector = true
	draft = {"asset": path, "pos": [0.0, 0.0], "frame": 0, "scale": 1.0, "rotation": 0.0, "layer": 1, "animated": false, "solid": false, "crop": [0, 0, 0, 0]}
	var is_floor_plan: bool = metadata[path].category == "Floor Plans"
	var native_size := Vector2(float(metadata[path].width) / metadata[path].frames, metadata[path].height)
	scale_input.value = maxf(1.0, minf(EditorVisualsSettings.FLOOR_PLAN_DEFAULT_SCALE, EditorVisualsSettings.FLOOR_PLAN_TARGET_SIZE / maxf(native_size.x, native_size.y))) if is_floor_plan else EditorVisualsSettings.PROP_SCALE_OVERRIDES.get(path, 1.0)
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
	if (mode == "stamp" or is_map_layout()) and tiled_input != null: read_draft()
	preview.texture = texture_for(draft.asset, int(frame_input.value), current_crop())
	var size := preview.texture.get_size() * scale_input.value
	description.text = asset_label(draft.get("pickup_kind", draft.asset.get_file().get_basename()))
	description.tooltip_text = "%s / %.0f x %.0f px" % [draft.asset, size.x, size.y]
	frame_input.get_parent().visible = not draft.has("pickup_kind") and int(metadata[draft.asset].frames) > 1
	animate_input.visible = frame_input.get_parent().visible
	solid_input.visible = not draft.has("pickup_kind") and metadata[draft.asset].category != "Enemies that are alive"
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

func is_map_layout() -> bool:
	return not draft.is_empty() and metadata.get(draft.asset, {}).get("category", "") == "Floor Plans"

func build_selected_layout() -> void:
	if not is_map_layout() or not game.editing: return
	var generated: Dictionary = game.Maps.from_layout(draft.asset, int(draft.frame), int(metadata[draft.asset].frames))
	game.replace_map(generated)
	activate_select()
	game.editor_center = Vector2(game.Maps.WIDTH, game.Maps.HEIGHT) * game.SIZE / 2.0
	game.editor_zoom = 1.0
	game.status.text = "Layout built with editable floors, walls, doors and windows. Ctrl+Z restores the previous map."

func use_stamp() -> void:
	read_draft()
	if draft.is_empty(): return
	mode = "select" if is_map_layout() else "stamp"
	sidebar_visible = true
	window.show()
	game.painting = false
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null: focused.release_focus()
	game.status.text = "Click the map to place. Q / E: rotate. V: select objects."
	place_tool.disabled = false
	place_tool.set_pressed_no_signal(true)
	select_tool.set_pressed_no_signal(false)
	if is_floor_stamp(): game.status.text = "Click: place / Wheel: resize / Ctrl+wheel: zoom / Q,E: rotate / Esc: menu"
	if is_map_layout(): game.status.text = "Choose a layout frame, then Build this layout as a map. Ctrl+Z restores the old map."

func apply_selected() -> void:
	if selected < 0 or selected >= objects().size() or draft.is_empty(): return
	read_draft()
	var candidate := draft.duplicate(true)
	candidate.pos = objects()[selected].pos
	if candidate.asset == FLOOR_ATLAS: align_floor(candidate, floor_bounds(objects()[selected]).position + Vector2.ONE)
	if floor_overlap(candidate, selected):
		game.status.text = "That size overlaps another floor tile."
		return
	game.snapshot()
	objects()[selected] = candidate
	sync_inspector(candidate)
	window.release_focus()
	mode = "select"
	game.queue_redraw()

func sync_inspector(item: Dictionary) -> void:
	syncing_inspector = true
	draft = item.duplicate(true)
	frame_input.max_value = metadata[draft.asset].frames - 1
	frame_input.value = draft.frame
	scale_input.value = draft.scale
	rotation_input.value = wrapf(draft.rotation, -180, 180)
	layer_input.select(draft.layer)
	animate_input.button_pressed = draft.animated
	solid_input.button_pressed = draft.solid
	tiled_input.button_pressed = draft.get("tiled", false)
	width_input.value = draft.get("size", [224, 168])[0]
	height_input.value = draft.get("size", [224, 168])[1]
	for i in 4: crop_inputs[i].value = draft.crop[i]
	syncing_inspector = false
	rebuild_weapon_properties()
	update_preview()

func show_library_page() -> void:
	if entity_page != null: entity_page.hide()
	construction_section.hide()
	tabs.show()
	sync_navigation()
	if layouts_page != null: layouts_page.hide()
	library_page.show()
	detail_page.hide()

func show_detail_page() -> void:
	if entity_page != null: entity_page.hide()
	sidebar_visible = true
	window.show()
	game.set_sidebar_visible(true)
	if construction_section != null:
		construction_section.hide()
		sync_navigation()
	tabs.show()
	sync_navigation()
	if layouts_page != null: layouts_page.hide()
	library_page.hide()
	detail_page.show()

func open_browser() -> void:
	if not game.editing: return
	game.painting = false
	dragging = false
	sidebar_visible = true
	window.show()
	tabs.current_tab = 0
	show_library_page()
	search.grab_focus()

func inspect_selected() -> void:
	if selected < 0 or selected >= objects().size(): return
	mode = "select"
	sync_inspector(objects()[selected])
	open_browser()
	show_detail_page()
	search.release_focus()

# Floor stamps occupy whole grid cells; their edges share the same grid origin.
func align_floor(item: Dictionary, point: Vector2) -> void:
	if item.asset != FLOOR_ATLAS: return
	item.rotation = roundf(float(item.rotation) / 90.0) * 90.0
	item.scale = maxf(1.0, roundf(float(item.scale) * ATLAS_CELL / game.SIZE)) * game.SIZE / ATLAS_CELL
	var extent := object_size(item, texture_for(item.asset, item.frame, item.crop)) * float(item.scale)
	if int(absf(item.rotation)) % 180 == 90: extent = Vector2(extent.y, extent.x)
	var origin: Vector2 = (point / game.SIZE).floor() * game.SIZE
	item.pos = [origin.x + extent.x / 2, origin.y + extent.y / 2]

func floor_bounds(item: Dictionary) -> Rect2:
	var extent := object_size(item, texture_for(item.asset, item.frame, item.crop)) * float(item.scale)
	if int(absf(item.rotation)) % 180 == 90: extent = Vector2(extent.y, extent.x)
	return Rect2(Vector2(item.pos[0], item.pos[1]) - extent / 2, extent)

func floor_overlap(item: Dictionary, ignored: int = -1) -> bool:
	if item.asset != FLOOR_ATLAS: return false
	var bounds := floor_bounds(item).grow(-0.01)
	for i in objects().size():
		if i != ignored and objects()[i].asset == FLOOR_ATLAS and bounds.intersects(floor_bounds(objects()[i])): return true
	return false

func position_for(point: Vector2) -> Vector2:
	if not draft.is_empty() and draft.asset == FLOOR_ATLAS:
		# Atlas cells are centered on terrain cells, never on their corners.
		var aligned := draft.duplicate(true)
		align_floor(aligned, point)
		point = Vector2(aligned.pos[0], aligned.pos[1])
	elif snap_input.button_pressed:
		point = (point / EditorVisualsSettings.OBJECT_SNAP_SIZE).round() * EditorVisualsSettings.OBJECT_SNAP_SIZE
	return point.clamp(Vector2.ZERO, Vector2(game.Maps.WIDTH, game.Maps.HEIGHT) * game.SIZE - Vector2.ONE)

func place(point: Vector2) -> void:
	if not draft.is_empty() and metadata.get(draft.asset, {}).get("category", "") == "Enemies that are alive":
		var cell := Vector2i((point / game.SIZE).floor())
		var coordinate := [cell.x, cell.y]
		if not game.inside(cell) or not game.Maps.floor_tile(game.map.cells[cell.y * game.Maps.WIDTH + cell.x]): return
		if coordinate in game.map.enemies or coordinate == game.map.spawn or coordinate == game.map.exit or game.map.enemies.size() >= EditorVisualsSettings.MAX_ENEMIES: return
		snapshot_placement()
		game.map.enemies.append(coordinate)
		if not game.map.has("enemy_styles"): game.map.enemy_styles = {}
		game.map.enemy_styles["%d,%d" % [cell.x, cell.y]] = draft.asset
		game.status.text = "Living enemy placed. Playtest to activate its AI."
		game.queue_redraw()
		return
	if draft.is_empty() or is_map_layout() or objects().size() >= EditorVisualsSettings.MAX_MAP_OBJECTS: return
	align_floor(draft, point)
	var item := draft.duplicate(true)
	var position := position_for(point)
	item.pos = [position.x, position.y]
	# A floor cell has one atlas stamp: repaint replaces it instead of stacking.
	if item.asset == FLOOR_ATLAS:
		for i in objects().size():
			var existing: Dictionary = objects()[i]
			if existing.asset == FLOOR_ATLAS and floor_bounds(existing).is_equal_approx(floor_bounds(item)):
				if floor_overlap(item, i): return
				if existing == item: return
				snapshot_placement()
				objects()[i] = item
				selected = i
				game.queue_redraw()
				return
	if floor_overlap(item):
		game.status.text = "Floor already occupied. Place beside it or delete the existing tile first."
		return
	snapshot_placement()
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

func rotate_active(degrees: float) -> void:
	var item: Dictionary = draft if mode == "stamp" else (objects()[selected] if mode == "select" and selected >= 0 and selected < objects().size() else {})
	if item.is_empty(): return
	var previous := item.duplicate(true)
	if mode == "select": game.snapshot()
	item.rotation = wrapf(item.rotation + degrees, -180, 180)
	if mode == "select" and floor_overlap(item, selected):
		item.merge(previous, true)
	sync_inspector(item)
	game.queue_redraw()

func is_floor_stamp() -> bool:
	return not draft.is_empty() and metadata.get(draft.asset, {}).get("category", "") in ["Floor tiles", "Floor Plans"]

func handle_event(event: InputEvent) -> bool:
	if not game.editing: return false
	if mode == "insert_layout" and event is InputEventMouseButton and event.pressed and game.MAP_VIEW.has_point(event.position):
		if event.button_index == MOUSE_BUTTON_LEFT: insert_layout_at(game.screen_to_world(event.position)); return true
		if event.button_index == MOUSE_BUTTON_RIGHT: activate_select(); return true
	if event is InputEventMouseButton and event.pressed and game.MAP_VIEW.has_point(event.position) and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if mode == "stamp" and is_floor_stamp() and not event.ctrl_pressed:
			var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			draft.scale = clampf(draft.scale + direction * (float(game.SIZE) / ATLAS_CELL if draft.asset == FLOOR_ATLAS else EditorVisualsSettings.FLOOR_STAMP_SCALE_STEP), 0.1, 8.0)
			sync_inspector(draft)
			game.status.text = "Size: %.2fx / Wheel: resize / Ctrl+wheel: zoom / Click: place / Esc: menu" % draft.scale
			return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B: open_browser(); return true
		if event.keycode == KEY_V and not event.ctrl_pressed: activate_select(); return true
		if event.keycode == KEY_ESCAPE:
			activate_select(); selected = -1
			game.painting = false; game.rectangle_mode = false; game.layout_tool = "paint"
			return true
		if event.ctrl_pressed and event.keycode == KEY_V and not clipboard.is_empty():
			mode = "stamp"; sync_inspector(clipboard); return true
		if event.keycode == KEY_DELETE and selected < 0 and game.inside(selected_terrain):
			game.snapshot(); game.paint(selected_terrain, true); selected_terrain = Vector2i(-1, -1); return true
		if mode == "terrain": return false
		if event.keycode == KEY_ENTER: inspect_selected(); return true
		if event.keycode == KEY_DELETE and selected >= 0 and selected < objects().size():
			game.snapshot(); objects().remove_at(selected); selected = -1; return true
		if event.ctrl_pressed and event.keycode == KEY_C and selected >= 0 and selected < objects().size():
			clipboard = objects()[selected].duplicate(true); return true
		if event.ctrl_pressed and event.keycode == KEY_D and selected >= 0 and selected < objects().size():
			draft = objects()[selected].duplicate(true); place(Vector2(draft.pos[0], draft.pos[1]) + Vector2.ONE * EditorVisualsSettings.OBJECT_SNAP_SIZE); return true
		if event.keycode in [KEY_Q, KEY_E, KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
			var item: Dictionary = draft if mode == "stamp" else (objects()[selected] if selected >= 0 and selected < objects().size() else {})
			if item.is_empty(): return true
			var previous := item.duplicate(true)
			if mode == "select": game.snapshot()
			if event.keycode == KEY_Q: item.rotation -= 90 if is_floor_stamp() else EditorVisualsSettings.OBJECT_ROTATION_STEP
			if event.keycode == KEY_E: item.rotation += 90 if is_floor_stamp() else EditorVisualsSettings.OBJECT_ROTATION_STEP
			if event.keycode == KEY_BRACKETLEFT: item.scale = maxf(0.1, item.scale - 0.1)
			if event.keycode == KEY_BRACKETRIGHT: item.scale = minf(8, item.scale + 0.1)
			item.rotation = wrapf(item.rotation, -180, 180)
			if item.asset == FLOOR_ATLAS:
				var bounds := floor_bounds(previous)
				align_floor(item, bounds.position + Vector2.ONE)
				if mode == "select" and floor_overlap(item, selected): item.merge(previous, true)
			sync_inspector(item)
			return true
	# Manual-style gestures also allow grabbing a prop while a terrain tool is active.
	if event is InputEventMouseButton and event.pressed and game.MAP_VIEW.has_point(event.position) and event.button_index == MOUSE_BUTTON_LEFT and event.ctrl_pressed:
		mode = "select"
	if event is InputEventMouseMotion and atlas_painting:
		if mode != "stamp" or not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			atlas_painting = false
		elif game.MAP_VIEW.has_point(event.position):
			paint_atlas_to(game.screen_to_world(event.position))
		else:
			atlas_painting = false
		return true
	if mode == "terrain": return false
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if not event.pressed: dragging = false; atlas_painting = false; return true
		if not game.MAP_VIEW.has_point(event.position): return false
		var point: Vector2 = game.screen_to_world(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.shift_pressed and not draft.is_empty():
				if mode == "select" and selected >= 0 and selected < objects().size():
					game.snapshot()
					objects()[selected].rotation = wrapf(objects()[selected].rotation + 90, -180, 180)
					sync_inspector(objects()[selected])
				else:
					draft.rotation = wrapf(draft.rotation + 90, -180, 180)
					sync_inspector(draft)
			else:
				selected = hit_test(point)
				delete_selected()
			return true
		if mode == "erase":
			var target_cell := Vector2i((point / game.SIZE).floor())
			if game.inside(target_cell) and game.map.cells[target_cell.y * game.Maps.WIDTH + target_cell.x] in [2, 5, 6] and game.solid(point):
				game.snapshot(); game.paint(target_cell, true); return true
			selected = hit_test(point)
			if selected >= 0: delete_selected()
			else:
				var cell := Vector2i((point / game.SIZE).floor())
				if game.inside(cell): game.snapshot(); game.paint(cell, true)
			return true
		if mode == "stamp":
			if draft.get("asset", "") == FLOOR_ATLAS:
				atlas_painting = true
				atlas_stroke_saved = false
				atlas_visited.clear()
				atlas_previous = point
				paint_atlas_to(point)
			else: place(point)
			return true
		selected = hit_test(point)
		selected_terrain = Vector2i(-1, -1)
		var cell := Vector2i((point / game.SIZE).floor())
		if game.inside(cell) and (selected < 0 or objects()[selected].layer == 0):
			var tile: int = game.map.cells[cell.y * game.Maps.WIDTH + cell.x]
			if tile in [2, 5, 6] and game.solid(point):
				selected = -1
				selected_terrain = cell
				game.status.text = "Structure selected / Delete removes only the structure; floor stays."
		if selected < 0 and game.inside(cell) and selected_terrain.x < 0:
			selected_terrain = cell
			game.status.text = "Terrain selected / Delete removes the selected terrain."
		if game.inside(cell):
			var coordinate := [cell.x, cell.y]
			if coordinate in game.map.enemies or coordinate == game.map.spawn or coordinate == game.map.exit:
				selected = -1
				selected_terrain = cell
				show_cell_properties(cell)
				return true
		if selected < 0 and game.inside(cell): show_cell_properties(cell)
		if selected >= 0:
			sync_inspector(objects()[selected])
			show_detail_page()
			game.status.text = "%s / Properties on the right / Delete: remove" % objects()[selected].asset.get_file()
			if event.double_click: inspect_selected(); return true
			dragging = true
			drag_started = false
			drag_offset = Vector2(objects()[selected].pos[0], objects()[selected].pos[1]) - point
		return true
	return false

func tick(delta: float) -> void:
	clock += delta
	ui_refresh_time += delta
	if ui_refresh_time >= EditorVisualsSettings.EDITOR_UI_REFRESH_INTERVAL:
		ui_refresh_time = 0.0
		update_mode()
	if not game.editing or game.dialog.visible:
		atlas_painting = false
		dragging = false
		return
	if dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): dragging = false; return
		if selected < 0 or selected >= objects().size(): dragging = false; return
		if not game.MAP_VIEW.has_point(game.get_global_mouse_position()): return
		var position := position_for(game.mouse_world() + drag_offset)
		if objects()[selected].asset == FLOOR_ATLAS:
			var moved: Dictionary = objects()[selected].duplicate(true)
			align_floor(moved, game.mouse_world() + drag_offset - floor_bounds(moved).size / 2 + Vector2.ONE * game.SIZE / 2)
			position = Vector2(moved.pos[0], moved.pos[1])
		var candidate: Dictionary = objects()[selected].duplicate(true)
		candidate.pos = [position.x, position.y]
		if floor_overlap(candidate, selected): return
		if objects()[selected].pos != [position.x, position.y]:
			if not drag_started: game.snapshot(); drag_started = true
			objects()[selected].pos = [position.x, position.y]

func floor_patch_polygons(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon: bounds = bounds.expand(point)
	var first := Vector2i((bounds.position / game.SIZE).floor())
	var last := Vector2i((bounds.end / game.SIZE).floor())
	var result: Array[PackedVector2Array] = []
	for y in range(maxi(0, first.y), mini(game.Maps.HEIGHT - 1, last.y) + 1):
		for x in range(maxi(0, first.x), mini(game.Maps.WIDTH - 1, last.x) + 1):
			var cell := Vector2i(x, y)
			var tile: int = game.map.cells[y * game.Maps.WIDTH + x]
			if tile == 0: continue
			for rect in game.floor_regions(cell):
				if not rect.has_area(): continue
				var clip := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
				result.append_array(Geometry2D.intersect_polygons(polygon, clip))
	return result

func draw_floor_patch(texture: Texture2D, rect: Rect2, transform: Transform2D, tint: Color) -> void:
	var polygon := transform * PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var inverse := transform.affine_inverse()
	for clipped in floor_patch_polygons(polygon):
		var uv := PackedVector2Array()
		for point in clipped: uv.append((inverse * point - rect.position) / texture.get_size())
		game.draw_polygon(clipped, PackedColorArray([tint]), uv, texture)

func draw_item(item: Dictionary, ghost: bool = false) -> void:
	var frame: int = int(clock * EditorVisualsSettings.OBJECT_ANIMATION_FPS) + int(item.frame) if item.animated else int(item.frame)
	var texture := texture_for(item.asset, frame, item.crop)
	if texture == null: return
	var position := Vector2(item.pos[0], item.pos[1])
	game.draw_set_transform(game.render_origin + position * game.view_zoom, deg_to_rad(item.rotation), Vector2.ONE * item.scale * game.view_zoom)
	var tint := EditorVisualsSettings.PLACEMENT_PREVIEW_COLOR if ghost else Color.WHITE
	var floor_stamp: bool = item.asset == FLOOR_ATLAS
	var transform := Transform2D(deg_to_rad(item.rotation), Vector2.ONE * item.scale, 0.0, position)
	if floor_stamp: game.draw_set_transform(game.render_origin, 0, Vector2.ONE * game.view_zoom)
	if item.get("tiled", false):
		var extent := object_size(item, texture)
		var step := texture.get_size()
		for y in int(ceil(extent.y / step.y)):
			for x in int(ceil(extent.x / step.x)):
				var offset := Vector2(x, y) * step
				var clipped := (extent - offset).min(step)
				if floor_stamp: draw_floor_patch(texture, Rect2(-extent / 2 + offset, clipped), transform, tint)
				else: game.draw_texture_rect_region(texture, Rect2(-extent / 2 + offset, clipped), Rect2(Vector2.ZERO, clipped), tint)
	else:
		if floor_stamp: draw_floor_patch(texture, Rect2(-texture.get_size() / 2, texture.get_size()), transform, tint)
		else: game.draw_texture(texture, -texture.get_size() / 2, tint)
	if ghost:
		game.draw_set_transform(game.render_origin + position * game.view_zoom, deg_to_rad(item.rotation), Vector2.ONE * item.scale * game.view_zoom)
		var extent := object_size(item, texture)
		game.draw_rect(Rect2(-extent / 2, extent), EditorVisualsSettings.PLACEMENT_OUTLINE_COLOR, false, 2.0 / (item.scale * game.view_zoom))
	game.draw_set_transform(game.render_origin, 0, Vector2.ONE * game.view_zoom)

func draw_layer(layer: int) -> void:
	for item in game.map.get("objects", []):
		if item.layer == layer and (game.editing or not item.has("pickup_kind")): draw_item(item)

func draw_tools() -> void:
	if not game.editing or game.dialog.visible: return
	if mode == "insert_layout" and game.MAP_VIEW.has_point(game.get_global_mouse_position()):
		var offset := insertion_offset(game.mouse_world())
		var valid := insertion_valid(offset)
		for y in range(insertion_bounds.position.y, insertion_bounds.end.y):
			for x in range(insertion_bounds.position.x, insertion_bounds.end.x):
				var tile: int = insertion_layout.cells[y * game.Maps.WIDTH + x]
				if tile == 0: continue
				var tint := Color(0.3, 1, 0.6, 0.45) if valid else Color(1, 0.25, 0.3, 0.5)
				if tile in [2, 5]: tint.a = 0.85
				game.draw_rect(Rect2(Vector2(Vector2i(x, y) + offset) * game.SIZE, Vector2.ONE * game.SIZE), tint)
	if mode == "select" and selected < 0 and game.inside(selected_terrain):
		var tile: int = game.map.cells[selected_terrain.y * game.Maps.WIDTH + selected_terrain.x]
		if tile == 2:
			for segment in game.wall_segments(selected_terrain): game.draw_rect(segment.grow(1), Color("60e4dc"), false, 1)
		else: game.draw_rect(Rect2(Vector2(selected_terrain) * game.SIZE, Vector2.ONE * game.SIZE), Color("60e4dc"), false, 1)
	if mode == "stamp" and not draft.is_empty() and game.MAP_VIEW.has_point(game.get_global_mouse_position()):
		var item := draft.duplicate(true)
		align_floor(item, game.mouse_world())
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


# Grid entities are map data, not decorative props. Inspect them separately.
func show_cell_properties(cell: Vector2i) -> void:
	show_detail_page()
	detail_page.hide()
	if entity_page != null:
		entity_page.get_parent().remove_child(entity_page)
		entity_page.queue_free()
	entity_page = VBoxContainer.new()
	library_page.get_parent().add_child(entity_page)
	button("< Back to library", show_library_page, entity_page)
	var padding := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 16)
	entity_page.add_child(padding)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	padding.add_child(body)
	var coordinate := [cell.x, cell.y]
	var enemy_index: int = game.map.enemies.find(coordinate)
	selected_entity = "enemy" if enemy_index >= 0 else ("spawn" if coordinate == game.map.spawn else ("exit" if coordinate == game.map.exit else "terrain"))
	section(selected_entity.capitalize() + " properties", body)
	var x_input := number("Grid X", 0, game.Maps.WIDTH - 1, 1, cell.x, body)
	var y_input := number("Grid Y", 0, game.Maps.HEIGHT - 1, 1, cell.y, body)
	var style := OptionButton.new()
	style.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(style)
	var key := "%d,%d" % [cell.x, cell.y]
	if selected_entity == "enemy":
		var asset: String = game.map.get("enemy_styles", {}).get(key, "")
		if metadata.has(asset):
			var portrait := TextureRect.new()
			portrait.texture = texture_for(asset)
			portrait.custom_minimum_size.y = 64
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			body.add_child(portrait)
		style.hide()
	elif selected_entity == "terrain":
		for label in ["Empty", "Carpet", "Wall", "Wood", "Tile", "Door", "Sofa"]: style.add_item(label)
		style.select(game.map.cells[cell.y * game.Maps.WIDTH + cell.x])
		style.hide()
		section(style.get_item_text(style.selected), body)
		# Terrain position is its grid address, not a movable object.
		x_input.editable = false
		y_input.editable = false
	else: style.hide()
	var enemy_fields: Dictionary = {}
	if selected_entity == "enemy":
		var options: Dictionary = game.map.get("enemy_options", {}).get(key, {})
		var kind: String = game.EnemyWeapons.identify(game.map.get("enemy_styles", {}).get(key, ""))
		var active := CheckButton.new()
		active.name = "EnemyActive"
		active.button_pressed = options.get("active", not game.EnemiesSettings.ENEMIES_INACTIVE)
		active.text = "Active ? moves and attacks" if active.button_pressed else "Inactive ? stationary target"
		active.tooltip_text = "Applies immediately to this enemy for the next playtest. Inactive enemies can still be killed."
		body.add_child(active)
		body.move_child(active, 1)
		active.toggled.connect(func(enabled: bool):
			game.snapshot()
			if not game.map.has("enemy_options"): game.map.enemy_options = {}
			var saved: Dictionary = game.map.enemy_options.get(key, {}).duplicate()
			saved["active"] = enabled
			game.map.enemy_options[key] = saved
			active.text = "Active ? moves and attacks" if enabled else "Inactive ? stationary target"
			game.queue_redraw())
		enemy_fields.active = active
		enemy_fields.health = number("Health", 1, 10000, 1, options.get("health", game.EnemiesSettings.ENEMY_HEALTH), body)
		enemy_fields.damage = number("Attack damage", 0, 10000, 1, options.get("damage", game.EnemyWeapons.profile(kind).damage), body)
		var note := Label.new()
		note.text = "Applies to this enemy. Saved with the map."
		body.add_child(note)
	var entity_apply := button("Apply changes", func():
		var destination := [int(x_input.value), int(y_input.value)]
		if selected_entity != "terrain" and destination != coordinate:
			if not game.Maps.floor_tile(game.map.cells[destination[1] * game.Maps.WIDTH + destination[0]]) or destination in game.map.enemies or destination == game.map.spawn or destination == game.map.exit:
				game.status.text = "Choose an unoccupied floor cell."
				return
		game.snapshot()
		if selected_entity == "enemy":
			game.map.enemies[enemy_index] = destination
			if not game.map.has("enemy_styles"): game.map.enemy_styles = {}
			var chosen: String = game.map.enemy_styles.get(key, "")
			game.map.enemy_styles.erase(key)
			if not chosen.is_empty(): game.map.enemy_styles["%d,%d" % destination] = chosen
			if not game.map.has("enemy_options"): game.map.enemy_options = {}
			game.map.enemy_options.erase(key)
			game.map.enemy_options["%d,%d" % destination] = {"active": enemy_fields.active.button_pressed, "health": int(enemy_fields.health.value), "damage": int(enemy_fields.damage.value)}
		elif selected_entity == "terrain":
			var previous: int = game.brush
			game.brush = [0, 1, 2, 7, 8, 9, 10][style.selected]
			game.paint(cell, false)
			game.brush = previous
		else: game.map[selected_entity] = destination
		selected_terrain = Vector2i(destination[0], destination[1])
		show_cell_properties(selected_terrain)
		game.queue_redraw(), body)
	entity_apply.visible = selected_entity != "terrain"
	if selected_entity == "enemy":
		button("Delete enemy", func():
			game.snapshot()
			game.map.enemies.remove_at(enemy_index)
			game.map.get("enemy_styles", {}).erase(key)
			game.map.get("enemy_options", {}).erase(key)
			selected_terrain = Vector2i(-1, -1)
			show_library_page()
			game.queue_redraw(), body)

func rebuild_weapon_properties() -> void:
	if weapon_properties == null: return
	for child in weapon_properties.get_children():
		weapon_properties.remove_child(child)
		child.queue_free()
	var kind: String = draft.get("pickup_kind", "")
	if kind.is_empty(): return
	var weapons = preload("res://scripts/game/player_weapons.gd")
	if not weapons.is_gun(kind):
		section("COMBAT TUNING", weapon_properties)
		var settings := ["BAT_DAMAGE", "MELEE_INTERVAL"] if weapons.is_melee(kind) else (["MOLOTOV_DAMAGE", "MOLOTOV_BURN_TIME", "MOLOTOV_FIRE_RADIUS"] if kind == "MOLOTOV" else ["THROW_WEAPON_DAMAGE", "THROW_SPEED"])
		var note := Label.new()
		note.text = "These settings change all weapons in this group."
		weapon_properties.add_child(note)
		for setting in settings:
			var registry = preload("res://scripts/settings/game_settings.gd")
			var original: Variant = registry.read_value(setting)
			var field := number(setting.replace("_", " ").capitalize(), 0 if original is int else 0.01, 10000, 1 if original is int else 0.01, original, weapon_properties)
			field.value_changed.connect(func(value): preload("res://scripts/settings/live_tuning.gd").change(setting, int(value) if original is int else float(value)))
		if weapons.is_melee(kind):
			var interval := number("This weapon attack interval", 0.05, 10, 0.01, weapons.animation_duration(kind, true), weapon_properties)
			interval.value_changed.connect(func(value):
				var overrides: Dictionary = WeaponsSettings.MELEE_WEAPON_INTERVALS.duplicate(true)
				overrides[kind] = value
				preload("res://scripts/settings/live_tuning.gd").change("MELEE_WEAPON_INTERVALS", overrides))
		return
	weapon_properties.add_theme_constant_override("separation", 5)
	var warning := PanelContainer.new()
	var warning_style := StyleBoxFlat.new()
	warning_style.bg_color = Color("54471c")
	warning_style.set_corner_radius_all(5)
	warning_style.content_margin_left = 10
	warning_style.content_margin_right = 10
	warning_style.content_margin_top = 6
	warning_style.content_margin_bottom = 6
	warning.add_theme_stylebox_override("panel", warning_style)
	var hint := Label.new()
	hint.text = "Applies to all " + kind.replace("_", " ").to_lower() + " weapons"
	hint.add_theme_color_override("font_color", Color("ffe19a"))
	hint.add_theme_font_size_override("font_size", 13)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_child(hint)
	weapon_properties.add_child(warning)
	var magazines := number("Number of magazines", 1, 101, 1, WeaponsSettings.START_RESERVE_MAGAZINES + 1, weapon_properties)
	magazines.tooltip_text = "Includes the loaded magazine. Applies to newly spawned guns of all types."
	magazines.value_changed.connect(func(value): preload("res://scripts/settings/live_tuning.gd").change("START_RESERVE_MAGAZINES", int(value) - 1))
	var stats: Array = weapons.stats(kind).duplicate()
	var fields: Array[SpinBox] = []
	var names := ["Bullets per magazine", "Damage", "Range", "Shot interval (s)", "Reload time (s)", "Bullets per shot", "Spread (degrees)"]
	for i in 7:
		fields.append(number(names[i], 0 if i in [1, 6] else (0.01 if i in [3, 4] else 1), 32 if i == 5 else 10000, 0.01 if i in [3, 4] else 1, stats[i], weapon_properties))
	var explanations := ["How many bullets fit in the gun before reloading.", "Damage from each bullet that hits an enemy.", "How far a bullet travels, in map pixels.", "Lower numbers mean faster shooting.", "How long reloading takes.", "1 for a normal bullet; larger values fire several projectiles together, like a shotgun. Each shot still uses one round of ammo.", "How widely bullets scatter. 0 shoots straight."]
	for i in fields.size():
		fields[i].tooltip_text = explanations[i]
		fields[i].get_parent().tooltip_text = explanations[i]
	button("Apply weapon settings", func():
		var values: Array = []
		for i in 7: values.append(int(fields[i].value) if i in [0, 1, 5] else fields[i].value)
		var overrides: Dictionary = WeaponsSettings.WEAPON_STAT_OVERRIDES.duplicate(true)
		overrides[kind] = values
		var tuning = preload("res://scripts/settings/live_tuning.gd")
		if tuning.change("WEAPON_STAT_OVERRIDES", overrides):
			game.status.text = "Weapon settings applied. Save in Developer Lab to keep them after restarting."
		else: game.status.text = "Invalid weapon values. Check the fields."
	, weapon_properties)

func populate_build_atlas() -> void:
	if build_atlas_grid == null or build_atlas_grid.get_child_count() > 0: return
	var group := ButtonGroup.new()
	for entry in atlas_tiles:
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(42, 38)
		tile.toggle_mode = true
		tile.button_group = group
		tile.tooltip_text = entry.name
		tile.icon = texture_for(entry.path, 0, entry.crop)
		tile.expand_icon = true
		tile.add_theme_constant_override("icon_max_width", 28)
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.focus_mode = Control.FOCUS_NONE
		tile.pressed.connect(func():
			choose_tile(entry)
			detail_page.hide()
			library_page.hide()
			if entity_page != null: entity_page.hide()
			tabs.hide()
			construction_section.show()
			sync_navigation()
			game.layout_tool = "paint"
			game.status.text = "%s / Click the map to place. V: select." % entry.name)
		build_atlas_grid.add_child(tile)

func snapshot_placement() -> void:
	if atlas_painting:
		if atlas_stroke_saved: return
		atlas_stroke_saved = true
	game.snapshot()

func paint_atlas_to(point: Vector2) -> void:
	# Sample between mouse events so fast drags do not skip grid cells.
	var steps := maxi(1, int(ceil(atlas_previous.distance_to(point) / (game.SIZE * 0.25))))
	for i in range(steps + 1):
		var sample := atlas_previous.lerp(point, float(i) / steps)
		var cell := Vector2i((sample / game.SIZE).floor())
		if not game.inside(cell) or atlas_visited.has(cell): continue
		atlas_visited[cell] = true
		place(Vector2(cell) * game.SIZE + Vector2.ONE * game.SIZE * 0.5)
	atlas_previous = point
