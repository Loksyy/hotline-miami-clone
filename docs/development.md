# Development guide

## Where to change things

| File | Responsibility |
| --- | --- |
| [game_settings.gd](../scripts/game_settings.gd) | Developer tuning: movement, damage, reload times, camera and editor defaults. |
| [runtime_settings.gd](../scripts/runtime_settings.gd) | Player preferences in `user://preferences.cfg`; independent of map saves. |
| [main.gd](../scripts/main.gd) | Scene coordinator, gameplay simulation, editor terrain input and drawing. |
| [pause_menu.gd](../scripts/ui/pause_menu.gd) | Escape handling, pause navigation and settings controls. |
| [asset_workshop.gd](../scripts/asset_workshop.gd) | Library, object properties, object placement, layout browser/insertion. |
| [map_data.gd](../scripts/map_data.gd) | Map validation, legacy normalization and public map helpers. |
| [map_format.gd](../scripts/maps/map_format.gd) | Shared dimensions, tile types and map/object constructors. |
| [layout_importer.gd](../scripts/maps/layout_importer.gd) | Source-image conversion and isolated cached layout templates. |
| [wall_geometry.gd](../scripts/rendering/wall_geometry.gd) | Cached rectangles shared by wall drawing and collision. |
| [game_art.gd](../scripts/game_art.gd) | Texture/sprite mappings and atlas frames. |
| [sound.gd](../scripts/sound.gd) | Synthesized effects and bounded reusable audio voices. |

## Map model

Maps are 32 ? 22 cells, each 28 pixels. `cells` stores the gameplay surface/structure; `floors` preserves floor material beneath structures. `objects` contains separate sprite props and windows. Spawn, exit and enemies use cell coordinates. Edit through the existing snapshot/undo path, and validate before playtesting or loading.

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
