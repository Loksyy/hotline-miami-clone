extends RefCounted
## Shared library classification used at runtime and when rebuilding the catalog.
static func category_for(path: String) -> String:
	var name := path.get_file().to_lower()
	if path.begins_with("Combat/Enemy/"):
		for marker in ["dead", "die", "kill", "back", "front", "ground", "exploded", "kicked", "bashed", "crawl", "getup", "giveup", "headstomp"]:
			if marker in name: return "Enemies / death and damage"
		if "legs" in name or "hat" in name or name.begins_with("sprite"): return "Enemies / parts and other"
		for marker in ["attack", "walk", "search", "idle", "sneak", "standguard", "taunt", "drinking", "phone", "sit", "rise", "pickup", "crouching", "reading", "talk", "point", "tinker"]:
			if marker in name: return "Enemies that are alive"
		return "Enemies / parts and other"
	if path.begins_with("Weapons/"):
		for marker in ["explode", "flame", "breaking"]:
			if marker in name: return "Weapons / effects"
		return "Weapons / guns and melee"
	return path.get_slice("/", 0)
