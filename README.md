# Project Gagugaga

A Godot top-down action game with a built-in map editor.

## Run

Open [project.godot](project.godot) in Godot 4.4 or newer and press **F5**.

## Controls

- **WASD** move, mouse aim, **left-click** attack.
- **R** reload, **E** pick up, **F** melee, **right-click** throw.
- **Space** operate doors, **T** restart, **Tab** editor/playtest.
- **Esc** pause: Resume, Settings, Editor, or Exit.

## Editor

Select assets from the right panel and click to place. **Select** moves existing objects; **Delete** erases them. **Ctrl+Z / Ctrl+Y** undo/redo.

Use **Layouts** to create a new map or insert a movable layout into the current one. Expand **Floors, walls & gameplay** for construction tools. **Q/E** rotate; the wheel resizes floor tiles, **Ctrl+wheel** zooms, and middle-drag pans. Save maps with **Save**; there is no autosave.

## Customize

- [game_settings.gd](scripts/game_settings.gd): movement, weapons, reloads, enemies, editor and rendering defaults.
- Pause **Settings**: volume, fullscreen, VSync, FPS limit/counter and screen shake.
- [Developer guide](docs/development.md): code organization and verification.
