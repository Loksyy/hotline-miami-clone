extends SceneTree
## Run after adding/removing PNGs: godot --headless --path . --script tools/rebuild_asset_catalog.gd
const Categories = preload("res://scripts/editor/asset_categories.gd")
var entries: Array = []
var pattern := RegEx.new()

func _initialize() -> void:
	pattern.compile("_strip([0-9]+)$")
	scan("res://HLM1 Files/", "")
	entries.sort_custom(func(a, b): return a.path < b.path)
	var file := FileAccess.open("res://assets/catalog.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write asset catalog")
		quit(1)
		return
	file.store_string(JSON.stringify(entries, "\t"))
	print("Catalogued %d textures" % entries.size())
	quit()

func scan(root_path: String, relative: String) -> void:
	var directory := DirAccess.open(root_path + relative)
	if directory == null: return
	for child in directory.get_directories(): scan(root_path, relative + child + "/")
	for filename in directory.get_files():
		if filename.get_extension().to_lower() != "png": continue
		var image := Image.load_from_file(root_path + relative + filename)
		if image == null: continue
		var result := pattern.search(filename.get_basename())
		var frames := int(result.get_string(1)) if result else 1
		entries.append({"path": relative + filename, "category": Categories.category_for(relative + filename), "name": filename.get_basename(), "width": image.get_width(), "height": image.get_height(), "frames": frames})
