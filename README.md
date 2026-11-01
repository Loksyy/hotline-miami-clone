# Project Gagugaga

A Godot 4.4 top-down action prototype and map workshop. Uses the supplied HLM1 Files texture collection, with synthesized sound effects.

## Run

Import [project.godot](project.godot) in Godot 4.4 or newer and press **F5**. The project opens in the map editor with the furnished After Hours demo. **Tab** switches between editing and playing without modifying the map.

## All gameplay settings in one file

Edit **[scripts/game_settings.gd](scripts/game_settings.gd)**, then stop and run the project again. Settings are grouped and commented. Times use seconds, distances use pixels, and speeds use pixels per second.

```gdscript
const PLAYER_SPEED := 245.0
const FIRE_INTERVAL := 0.18  # Seconds between shots
const RELOAD_TIME := 1.1
const MAGAZINE_SIZE := 8
const START_RESERVE_AMMO := 24
const PLAYER_HEALTH := 1
const ENEMY_REACTION_TIME := 0.7
const SCREEN_SHAKE_SCALE := 0.0  # Disable shake
```

The file also controls damage, enemy movement and health, vision and hearing, bullet speed, melee range, stun duration, throwing, pickup range, scoring, combo timing, sound volume, blood effects, and editor limits. Keep durations positive and MELEE_ARC_DOT between -1 and 1. Rendering geometry and the fixed 32 x 22 map format remain implementation details.

## Controls

| Action | Input |
| --- | --- |
| Move / aim | WASD / mouse |
| Shoot or use held melee weapon | Left mouse |
| Throw weapon to stun | Right mouse |
| Pick up / swap nearby weapon | E |
| Melee attack | F |
| Open/kick adjacent door | Space |
| Reload pistol | R |
| Restart | T; R also works after death or victory |
| Editor / playtest | Tab |
| Mute effects | M |

Pistols have limited magazines and reserve ammunition. Reloading blocks attacks; throwing or swapping weapons cancels it. Fists knock enemies down; another close attack finishes them. Bats are lethal by default. Thrown weapons and kicked doors stun enemies. Enemies drop recoverable weapons.

Enemies use vision, hearing, last-known positions, and grid pathfinding. White-jacket enemies fire dodgeable bullets; pink-jacket enemies rush with melee attacks. A ring shows shooting windup, and a cyan ring indicates a stunned enemy. Consecutive kills within the combo window multiply score. Clear everyone and reach the green exit.

## Map workshop

- **1-3:** void, carpet, wall.
- **4-6:** spawn, enemy, exit.
- **7 / right mouse:** erase enemies; move spawn and exit with their placement tools.
- **8 / 9 / 0 / minus:** wood floor, tiled floor, door, sofa.
- **Drag:** paint; **Shift+drag:** filled rectangle for terrain and furniture.
- **Ctrl+Z / Ctrl+Y:** undo/redo, including new-map and load operations.
- **Check Routes:** checks reachability of enemies and exit, treating doors as openable.
- **Save JSON / Load JSON:** portable maps with validation. Previous basic maps still load.

Entities require an unoccupied floor tile. Walls, sofas, void, and closed doors block movement and shots. Save before closing; there is no autosave yet. Doors, defeated enemies, dropped weapons, and damage reset when leaving playtest.

## Verification and scope

Run `godot --headless --path . --script tests/smoke.gd` for map validation, JSON and disk round trips, undo/redo, playtest isolation, collision, sight, navigation, doors, melee, throwing, pickups, damage, reload behavior, and victory checks.

This remains a prototype: graphics use the supplied sprite sheets, sound is synthesized, maps have a fixed size, and there is no campaign, music, gamepad support, or export package yet.

## Texture integration

The map panel uses a zoomable camera: **mouse wheel** zooms around the cursor, **middle-mouse drag** pans, **Home** fits the full map, and **G** toggles the grid. Playtesting uses a closer camera that follows the player; returning to editing restores the editor view. Floors repeat in world space at a consistent pixel density across room boundaries rather than stretching into each grid cell. Wall edges connect and horizontal sofa runs render as a single furnishing. Camera defaults and floor density are adjustable in the settings file.

The original PNGs in [HLM1 Files](HLM1%20Files/) are loaded directly. [scripts/game_art.gd](scripts/game_art.gd) maps strips and atlas regions to the existing game objects. Player and enemy walking use separate body/leg layers, attacks use their own strips, and corpses, floors, walls, sofas, doors, weapons, blood, cursor, and exit use supplied textures. Nearest-neighbor sampling preserves pixel edges. Sprite scale and animation speed live in [scripts/game_settings.gd](scripts/game_settings.gd). Unused assets remain available for future objects.

## Full asset workshop

**B** or **Asset Library** opens all **1,431 supplied PNGs** with category filters, search, paged thumbnails, a large preview, and frame selection. Strip frames can represent animation poses or object variants; enable animation only when desired. The browser loads textures as needed.

1. Pick an asset and frame. For an atlas, enter crop X/Y/width/height to isolate a material or prop.
2. Set scale, rotation, and layer (floor, prop, or overlay). Optionally enable animation or a rectangular solid collider.
3. Choose **Use as Stamp**, then click the map to place it. Right-click switches to selection; Esc returns to terrain painting.
4. **V** selects objects. Drag to move; **Q/E** rotates; **[/]** scales; **Delete** removes. **Ctrl+C/V** copies and creates a paste stamp; **Ctrl+D** duplicates. **Enter** or double-click opens properties; **Apply to Selected** commits changes.

Enable **Repeat texture as room surface** and set area width/height to fill a room with a cropped material, independent of the terrain grid. Use the floor layer for these surfaces. Grid snapping can be disabled for free placement. Undo/redo and JSON save/load include every object, crop, transform, collision flag, and layer. Old maps without objects still load.

Artwork placement does not automatically create gameplay logic: use the existing enemy/spawn/door tools for behavior. Solid props block movement and shots; their collision is their rotated image rectangle, not a pixel-perfect outline. Room surfaces and decorative floor plans do not generate walls or navigation automatically.

Library metadata lives in [assets/catalog.json](assets/catalog.json). After adding PNG files, rebuild it with `godot --headless --path . --script tools/rebuild_asset_catalog.gd`, then restart. The originals remain untouched. Object limits, snap spacing, rotation increments, and animation speed are in [scripts/game_settings.gd](scripts/game_settings.gd).

## 1080p editor layout

The game now uses a **1920 x 1080** viewport. The asset library is a persistent, non-modal dock on the right, with searchable thumbnails above a scrollable inspector. Selecting a stamp keeps the library open so you can place it directly on the map. Terrain, file, history, and playtest controls sit below the map. **B** focuses the library search. The dock hides during playtesting and returns when editing resumes. Smaller windows scale the interface through Godot's canvas-items stretch mode.

### Unified right-hand editor dock

All editing controls now live on the right. Save, Load, Undo, Redo, and Playtest remain at the top. **Map** contains new/demo layouts, route checks, camera controls, and help. **Build** contains terrain and gameplay placement tools. **Assets** contains thumbnails and object properties. The bottom button rows are removed, giving the map more vertical space. The dock remains available during playtest with a return button and gameplay controls.

Click any asset thumbnail to immediately select it for placement; inspector changes update the active preview. Small Floor Plans frames default to enlarged map-section scale on the floor layer. FLOOR_PLAN_DEFAULT_SCALE and FLOOR_PLAN_TARGET_SIZE control their initial sizing. Floor-plan artwork still needs terrain walls and entities for gameplay behavior.

### Wall, door, and tool improvements

The demo now has single-cell doorways without gaps beside the doors. Walls use the full horizontal/vertical wall artwork. Doors orient to adjacent walls and show their swing direction while editing. In play, walk into a closed door to push it open, or press Space to kick it open/close it. Doors block movement, sight, and shots when closed, and cannot close on a living actor. Restart restores closed doors.

The dock now has always-visible Select / move and Paint terrain buttons, illustrated build tools, and task-specific hints. The Erase tool and terrain right-click remove an enemy or restore a floor cell. New demo layouts are available through Map > Load demo layout; saved layouts retain their original geometry.
