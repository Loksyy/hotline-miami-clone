extends SceneTree
const Maps = preload("res://scripts/maps/map_data.gd")
func _initialize() -> void:
 var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/catalog.json").trim_prefix("\ufeff"))
 var kept: Array = []
 var signatures: Array = []
 var total := 0
 for entry in catalog:
  if entry.category != "Floor Plans": continue
  for frame in int(entry.frames):
   total += 1
   var map := Maps.from_layout(entry.path, frame, int(entry.frames))
   if map.name == "Untitled floor": continue
   var signature: Array = map.cells.duplicate()
   for i in signature.size():
    if Maps.floor_tile(signature[i]): signature[i] = 1
    elif signature[i] == 5: signature[i] = 2
   var duplicate := false
   for existing in signatures:
    var differences := 0
    var occupied := 0
    for i in signature.size():
     if signature[i] != 0 or existing[i] != 0: occupied += 1
     if signature[i] != existing[i]: differences += 1
    if differences <= maxi(10, int(occupied * 0.30)): duplicate = true; break
   if duplicate: continue
   signatures.append(signature)
   var item: Dictionary = entry.duplicate(true)
   item.category = "Room layouts"
   item.name = entry.name.trim_prefix("spr").get_slice("_strip", 0) + " / " + str(frame + 1)
   item.frame = frame
   kept.append(item)
 var file := FileAccess.open("res://assets/layouts.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(kept, "\t"))
 print("Unique layouts: %d / %d" % [kept.size(), total])
 quit()
