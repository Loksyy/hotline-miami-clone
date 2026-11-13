# Development guide

## Folder guide

- `scenes/`: Godot scenes; the project starts at `main.tscn` here.
- `scripts/settings/`: developer tuning and saved player preferences.
- `scripts/game/`: gameplay simulation and scene coordination.
- `scripts/editor/`: asset library, placement tools and editor icons.
- `scripts/maps/`: map format, validation and layout conversion.
- `scripts/rendering/`: textures, animation frames and wall geometry.
- `scripts/audio/`: sound effects and audio voice pooling.
- `scripts/ui/`: pause menu and settings interface.
- `tests/`: automated checks; `tools/`: asset catalog maintenance.

## Where to change things

| File | Responsibility |
| --- | --- |
| [settings/](../scripts/settings/) | Tune `player_settings`, `weapons_settings`, `enemies_settings`, `world_settings`, and `editor_visuals_settings`. `game_settings` registers settings for Developer Lab; gameplay imports the groups directly; `live_tuning` validates and saves Developer Lab overrides. |
| [runtime_settings.gd](../scripts/settings/runtime_settings.gd) | Player preferences in `user://preferences.cfg`; independent of map saves. |
| [main.gd](../scripts/game/main.gd) | Scene coordinator, gameplay simulation, editor terrain input and drawing. |
| [pause_menu.gd](../scripts/ui/pause_menu.gd) | Escape handling, pause navigation and settings controls. |
| [asset_workshop.gd](../scripts/editor/asset_workshop.gd) | Library, object properties, object placement, layout browser/insertion. |
| [map_data.gd](../scripts/maps/map_data.gd) | Map validation, legacy normalization and public map helpers. |
| [map_format.gd](../scripts/maps/map_format.gd) | Shared dimensions, tile types and map/object constructors. |
| [layout_importer.gd](../scripts/maps/layout_importer.gd) | Source-image conversion and isolated cached layout templates. |
| [wall_geometry.gd](../scripts/rendering/wall_geometry.gd) | Cached rectangles shared by wall drawing and collision. |
| [game_art.gd](../scripts/rendering/game_art.gd) | Texture/sprite mappings and atlas frames. |
| [sound.gd](../scripts/audio/sound.gd) | Synthesized effects and bounded reusable audio voices. |

## Map model

Maps are 96 ? 66 cells, each 28 pixels. `cells` stores the gameplay surface/structure; `floors` preserves floor material beneath structures. `objects` contains separate sprite props and windows. Spawn, exit and enemies use cell coordinates. Edit through the existing snapshot/undo path, and validate before playtesting or loading.

Layout insertion copies non-empty terrain, stored floors and props. It preserves existing player/enemy/exit markers, rejects out-of-bounds placement and replaces terrain beneath its footprint. One undo restores the complete previous map.

## Performance and pause

Wall shape caches key on position, neighboring connections and thickness. Wall outline caches invalidate when map geometry changes. Layout templates are deep-copied from cache so edits cannot corrupt future layouts. UI status refreshes at 10 Hz; FPS at 4 Hz. Sound uses a fixed voice pool. Runtime frame limit defaults to 120 and is configurable.

Pause uses `SceneTree.paused`; only the pause menu processes while paused. Opening it cancels pending editor gestures. Returning to the editor restores the editable map rather than storing playtest damage.

## Verify

```sh
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/pause_settings.gd
```

The suite covers map validation, layout generation, collision, doors, combat, save/load, undo, editor controls and viewport bounds. Headless tests do not establish GPU frame rates or visual quality: also check the editor and playtest in a real window.

Rebuild asset metadata with [rebuild_asset_catalog.gd](../tools/rebuild_asset_catalog.gd). Rebuild unique layout representatives with [curate_layouts.gd](../tools/curate_layouts.gd). Source PNGs remain untouched; windows are currently non-breakable.

## Repeatable rendering check

Run `godot --path . --script tests/performance.gd` in a real window. It temporarily disables the FPS cap and VSync without saving preferences, warms up, then samples 360 frames in the starter editor and a stationary playtest with enemies removed. It reports average FPS and drawing-script CPU time; this isolates rendering, not combat performance. Compare runs with the same Godot version and desktop workload. Floors use cached repeatable textures; sofa geometry rebuilds only when map geometry changes.

Settings split check: `godot --headless --path . --script tests/settings_split.gd` verifies the registry and shared values.
