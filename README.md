# Project Gagugaga

A Godot top-down action game with a built-in map editor.

## Run

Open [project.godot](project.godot) in Godot 4.4 or newer and press **F5**.

## Controls

- **WASD** move, mouse aim, **left-click** attack.
- **R** reload, **E** pick up, **F** melee, **right-click** throw.
- **Space** operate doors, **T** restart, **Tab** editor/playtest.
- Hold **Shift** to look farther toward the cursor without changing zoom; tune **Shift Look** in Developer Lab.
- **Esc** pause: Resume, Settings, Editor, or Exit.

## Editor

Select assets from the right panel and click to place. **Select** moves existing objects; **Delete** erases them. **Ctrl+Z / Ctrl+Y** undo/redo.

Use **Layouts** to create a new map or insert a movable layout into the current one. Expand **Floors, walls & gameplay** for construction tools. **Q/E** rotate; the wheel resizes floor tiles, **Ctrl+wheel** zooms, and middle-drag pans. Save maps with **Save**; there is no autosave.

## Customize

- [game_settings.gd](scripts/settings/game_settings.gd): gameplay, sizes, enemies and editor settings. [Tuning reference](docs/tuning.md).
- Pause **Settings**: volume, fullscreen, VSync, FPS limit/counter and screen shake.
- [Developer guide](docs/development.md): code organization and verification.

**Developer Lab** appears in the right sidebar during playtests (also available through **Esc**). It lets you search and tweak settings live. **Save tuning** keeps overrides between sessions; **Reset to source defaults** restores source values. Starting stats need a new playtest; map dimensions are read-only.

## Find or fix something

- [scripts/](scripts/): `game` runs gameplay, `editor` handles editing, `maps` handles layouts/saves, `rendering` draws art, `audio` plays sounds, and `ui` contains the pause menu.
- [scenes/main.tscn](scenes/main.tscn): startup scene. Keep [HLM1 Files/](HLM1%20Files/) in place; the game loads its textures directly.
- Missing scripts after moving files? Reopen the project in Godot and let its filesystem scan finish. Check **Debugger → Errors** for the failing file and line.
- Layout preview red? Keep it inside the canvas boundary and away from player/enemy/exit markers. Use **Fit map**, zoom or pan to find space.
- Check changes with `godot --headless --path . --script tests/smoke.gd` from the project folder (use your Godot executable path if `godot` is not on PATH). Pause/settings checks are listed in the [developer guide](docs/development.md).
