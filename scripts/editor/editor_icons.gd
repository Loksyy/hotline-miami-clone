extends RefCounted
## Small vector icons, drawn locally; no font glyph or asset import dependency.
static var cache: Dictionary = {}
const PATHS := {
 "exit": "M10 3 H3 V21 H10 M8 12 H22 M17 7 L22 12 L17 17",
 "gear": "M9 3 H15 L16 6 L19 7 L22 10 V14 L19 15 L18 18 L15 19 L14 22 H10 L9 19 L6 18 L5 15 L2 14 V10 L5 9 L6 6 Z M16 12 A4 4 0 1 1 8 12 A4 4 0 1 1 16 12",
 "sidebar": "M3 3 H21 V21 H3 Z M15 3 V21",
 "next": "M13 4 L21 12 L13 20 M3 12 H21",
 "settings": "M3 6 H21 M3 12 H21 M3 18 H21 M8 3 V9 M16 9 V15 M10 15 V21",
 "star": "M12 2 L15 8 L22 9 L17 14 L18 21 L12 18 L6 21 L7 14 L2 9 L9 8 Z",
 "select": "M5 3 L19 12 L12 14 L9 21 Z",
 "stamp": "M8 14 V10 C4 2 20 2 16 10 V14 M5 14 H19 V19 H5 Z M4 22 H20",
 "library": "M3 3 H10 V10 H3 Z M14 3 H21 V10 H14 Z M3 14 H10 V21 H3 Z M14 14 H21 V21 H14 Z",
 "save": "M4 3 H18 L21 6 V21 H3 V3 Z M8 3 V9 H16 V3 M7 21 V14 H17 V21",
 "load": "M3 7 V4 H10 L13 7 H21 V20 H3 Z M3 11 H21",
 "undo": "M9 4 L3 10 L9 16 M3 10 H14 C23 10 23 21 15 21",
 "redo": "M15 4 L21 10 L15 16 M21 10 H10 C1 10 1 21 9 21",
 "play": "M6 3 L21 12 L6 21 Z",
 "grid": "M3 3 H21 V21 H3 Z M9 3 V21 M15 3 V21 M3 9 H21 M3 15 H21",
 "fit": "M3 9 V3 H9 M15 3 H21 V9 M21 15 V21 H15 M9 21 H3 V15",
 "build": "M3 4 H21 V20 H3 Z M3 12 H21 M11 4 V12 M15 12 V20",
 "delete": "M3 6 H21 M8 6 V3 H16 V6 M6 6 V21 H18 V6 M10 10 V17 M14 10 V17",
 "copy": "M8 8 H21 V21 H8 Z M4 16 H3 V3 H16 V4",
 "back": "M11 4 L3 12 L11 20 M3 12 H21",
 "check": "M3 12 L9 19 L21 4",
 "brush": "M5 16 L16 3 L21 8 L9 20 L3 21 Z",
 "fill": "M4 10 L12 2 L21 11 L12 20 Z M4 10 H20 M3 16 V21",
 "rotate": "M5 8 A8 8 0 1 1 4 16 M5 2 V8 H11"
}
static func get_icon(key: String) -> Texture2D:
 if cache.has(key): return cache[key]
 var image := Image.new()
 var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><path d="%s" fill="none" stroke="#eee4f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>' % PATHS[key]
 if image.load_svg_from_string(svg) != OK: return null
 cache[key] = ImageTexture.create_from_image(image)
 return cache[key]
