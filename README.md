# Project Gagugaga

A Godot 4.4 top-down action prototype and map workshop. Uses the supplied HLM1 Files texture collection, with synthesized sound effects.

## Run

Import [project.godot](project.godot) in Godot 4.4 or newer and press **F5**. The project opens in the map editor with the furnished Night Shift Apartment. **Tab** switches between editing and playing without modifying the map.

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
3. Clicking a thumbnail immediately selects its placement stamp. Click the map to place it; right-click an object to erase it. **Esc** switches to Select.
4. **V** selects objects; **Ctrl+click** grabs an object even from terrain mode. Drag to move; **Q/E** rotates; **Shift+right-click** rotates 90 degrees; **[/]** scales; **Delete** removes. **Ctrl+C/V** copies and creates a paste stamp, including from terrain mode; **Ctrl+D** duplicates. **Enter** or double-click opens properties; **Apply to Selected** commits changes. Selection and rotation shortcuts keep the inspector synchronized.

Enable **Repeat texture as room surface** and set area width/height to fill a room with a cropped material, independent of the terrain grid. Use the floor layer for these surfaces. Grid snapping can be disabled for free placement. Undo/redo and JSON save/load include every object, crop, transform, collision flag, and layer. Old maps without objects still load.

Before placement, the stamp follows the cursor as a translucent green preview with an outline showing its footprint. For **Floor tiles** and **Floor Plans / Room layouts**, scroll over the map to make the preview larger or smaller; **Ctrl+wheel** zooms the camera. Other objects retain wheel-to-zoom. Click to place at the preview size, or Esc to switch to Select. Preview colors and the wheel size increment are configurable in [scripts/game_settings.gd](scripts/game_settings.gd).

Artwork placement does not automatically create gameplay logic: use the existing enemy/spawn/door tools for behavior. Solid props block movement and shots; their collision is their rotated image rectangle, not a pixel-perfect outline. Room surfaces and decorative floor plans do not generate walls or navigation automatically.

Library metadata lives in [assets/catalog.json](assets/catalog.json). After adding PNG files, rebuild it with `godot --headless --path . --script tools/rebuild_asset_catalog.gd`, then restart. The originals remain untouched. Object limits, snap spacing, rotation increments, and animation speed are in [scripts/game_settings.gd](scripts/game_settings.gd).

## 1080p editor layout

The game uses a **1920 x 1080** viewport. The persistent right dock holds terrain, file, history, and playtest controls, plus searchable thumbnails and a scrollable inspector. Selecting a stamp keeps the library open for direct placement. **B** focuses the library search. During playtest the dock shows gameplay help and a return button. Smaller windows scale the interface through Godot's canvas-items stretch mode.

### Unified right-hand editor dock

All editing controls live on the right. Save, Load, Undo, Redo, and Playtest remain at the top. **Build** contains terrain and actor tools, with new/demo layouts and route checks under **Map options & help**. **Items** contains the asset library and collapsed object properties. The top bar holds map name, Save, Load, Undo, Redo, Grid, Fit map, and Playtest.

Click any asset thumbnail to immediately select it for placement; inspector changes update the active preview. Small Floor Plans frames default to enlarged map-section scale on the floor layer. FLOOR_PLAN_DEFAULT_SCALE and FLOOR_PLAN_TARGET_SIZE control their initial sizing. Floor-plan artwork still needs terrain walls and entities for gameplay behavior.

### Wall, door, and tool improvements

The demo now has single-cell doorways without gaps beside the doors. Walls use the full horizontal/vertical wall artwork. Doors orient to adjacent walls and show their swing direction while editing. In play, walk into a closed door to push it open, or press Space to kick it open/close it. Doors block movement, sight, and shots when closed, and cannot close on a living actor. Restart restores closed doors.

The dock has always-visible Select / move and Paint terrain buttons, illustrated build tools, and task-specific hints. The Erase tool and terrain right-click remove an enemy or restore a floor cell. New demo layouts are available through Build > Map options & help > Load demo layout; saved layouts retain their original geometry.

### Individual floor-atlas tiles

In Items, click **Floor tiles** to browse the non-empty 16 x 16 cells from `HLM1 Files/Floor tiles/bacground0.png`. Tiles are labeled by column and row. Clicking one activates a floor-layer stamp with its crop already selected. Enable **Advanced > Repeat texture as room surface** to repeat it across an area. Larger motifs span multiple cells; use the crop width/height controls to include adjacent cells. The source PNG is unchanged, and maps save the crop coordinates.

### Room layouts and thin walls

**Items > Room layouts** lists every individual frame from the Floor Plans folder. Click a thumbnail to place that specific layout at map-section scale on the floor layer. These are visual templates; use Build to add working walls and doors, and its Enemy tool to add opponents.

Build walls now use the supplied horizontal and vertical sprites at **8 pixels thick**, with connected corners and matching collision, rather than stretching across a whole 28-pixel cell. Adjust WALL_THICKNESS in the settings file. Closed-door collision follows the visible door leaf; movement uses smaller collision steps to prevent passing through it.

### Manual-inspired editor

The editor takes visual cues from [Dennaton's official manual](https://dennaton.blogspot.com/2015/12/level-editor-manual-basics.html), with a single tab-free asset library. **Build tools** in the top bar opens Room, Outline, Fill, Sample, terrain and actor tools. The right panel gives most of its space to thumbnails; Clicking an asset opens a dedicated detail page: a large preview above its object properties. **Back to library** returns to the same search and page. Selecting a placed object opens its details too.

Room layouts and floor tiles rotate in quarter turns with **Q/E**, or the visible **Rotate left / Rotate right** buttons. The green preview turns before placement, and placed objects retain that rotation. Other objects keep fine Q/E rotation; exact angles remain available in Object properties.

The interface uses square purple panels, a dark teal grid, monospaced labels, and neon trim inspired by reference screenshots. Appearance colors are configurable in the settings file. This is a visual and workflow adaptation, not a feature-complete reproduction: campaigns, multi-floor transitions, cutscenes, and faction editing are not implemented.

### Tile placement

Atlas tiles default to one 28-pixel terrain cell and snap to cell centers, so the green preview matches placement. Clicking the same tile again does nothing; painting another atlas tile into that cell replaces the old one in a single undoable edit. Dragging an atlas tile onto an occupied atlas cell is blocked. Furniture and room layouts retain their separate object placement behavior. The empty Build tab has been removed; use **Build tools** in the top bar.

### Asset detail page

Click a library thumbnail to open its own page in the right panel, with a large preview and object properties underneath. Placement stays active on the map. Use **Back to library** (or B) to browse again without losing filters or pagination. Selecting an existing object also shows its detail page; use **Apply changes to selected object** to commit property edits.

### Editor tools

The toolbar uses labeled vector icons for important actions, inspired by [Tiled's object selection and placement workflow](https://doc.mapeditor.org/en/latest/manual/objects/).

- **Select [V]**: click an existing object to inspect it; drag to move it.
- **Place asset**: stamp copies of the chosen asset. This is unavailable until an asset is chosen.
- **Library [B]**: browse assets; clicking a thumbnail activates placement and opens its detail page.
- **Build tools**: choose floors, walls, doors, enemies or room-building tools.
- **Escape**: cancel placement and switch to Select without painting terrain.

The current tool is highlighted and described above the panel. Save, Load, Undo, Redo, Playtest, rotation, duplication and deletion have icons alongside their labels. Selection-only apply controls are hidden while placing assets.

### Default layout map

The default is generated from frame 9 of the supplied Apartment 1 layout. The old furnished apartment and its floating reference diagram are removed. Floor-plan silhouettes and internal divisions are traced into basic floor and wall cells, connected with working doors. Exterior windows use glass artwork over blocking structural walls; they are not breakable windows.

In **Room layouts**, select a frame and choose **Build this layout as a map**. This replaces the current floor in one undoable action. Layouts are no longer placed as decorative image stamps. The conversion adapts the diagram to the fixed terrain grid, so very small details are approximated. Floors and walls are editable through Build tools; window artwork is selectable.

### Object proportions and door collision

Starter furniture and newly selected matching assets use shared `PROP_SCALE_OVERRIDES` in [scripts/game_settings.gd](scripts/game_settings.gd). The couch, table, bed and desk use native scale; the unusually long drawer asset uses 0.4. Existing saved object scales are preserved. Reload the demo to see corrected starter furniture.

Door opening/closing changes state instantly. Closing is blocked only when an actor overlaps the door leaf plus their collision radius, rather than the entire surrounding tile. Yellow hinge/swing guides are removed. Actor collision checks include edge midpoints and center to catch thin obstacles.

### Wall rendering and erasing

Thin walls and doors inherit the surrounding floor material on each side rather than drawing a carpet square beneath every segment. Wall artwork repeats at a consistent scale inside the collision segments. **Delete** beside Select is an eraser tool: activate it and click a placed object or terrain cell. Ctrl+Z restores the edit; Esc returns to Select. Spawn and exit markers remain protected and can be moved with Build tools.

### Layout perimeter correction

Layout conversion no longer adds a second exterior wall row around walls already present in the source diagram. Rebuild a layout (or start a new session) to replace earlier generated geometry. Erasing walls, doors or floor cells now leaves empty space rather than inserting carpet. Spawn and exit floors are protected until their markers are moved; undo restores erased terrain.

### Independent floors and structures

Maps now save a separate floor layer. Painting a wall preserves its floor; repainting that floor preserves the wall. Deleting a wall, door or terrain furniture reveals the stored material instead of clearing it or inserting carpet. Select can target structures as well as asset objects. Older maps without a floor layer infer materials from neighboring floors once on load; previously deleted floor information cannot be recovered automatically. New layout perimeters stay inside the sampled footprint, and isolated wall cells render as small posts rather than protruding full-cell bars.

### Dedicated layout browser

Open **Layouts** in the top bar. This is separate from assets: choose a named layout/frame, inspect its generated terrain preview and door/window counts, then press **Create map from layout**. The preview and creation use the same map data; creation returns to editing and can be undone. Frames with too little usable floor are disabled with an explanation. Floor-plan diagrams are excluded from asset browsing.

Walls now render their texture interior with an outline only on exposed geometry edges, avoiding baked sprite borders across L/T junctions.

### Layout conversion and performance

Layout conversion now floods background from the image boundary, preserving green interiors inside enclosed outlines. It crops unused margins and samples source areas rather than single pixels. Currently 340 of 345 frames generate usable maps; the remaining frames stay disabled with an explanation.

Wall outlines are cached until terrain or wall dimensions change, and contiguous exposed edges are merged into lines instead of issuing per-pixel drawing commands each frame. The top-right FPS counter updates four times per second in both editing and gameplay.

### Curated layouts and inline construction tools

The layout browser contains **63 distinct representatives** instead of 345 frames. Generated maps are compared after normalizing floor finishes; variants differing by at most ten terrain cells are grouped. Source images are not deleted. Rebuild the curated list after changing the converter or adding layouts with `godot --headless --path . --script tools/curate_layouts.gd`.

The Build tools popup is removed. Expand **Floors, walls & gameplay** in the right panel for floor materials, walls, doors, actors, room/fill tools, new/demo maps and route checking. Collapse the same heading to return the space to the library. Grid/Fit remain in the top bar, Delete remains beside Select, and furniture comes from the asset library; duplicate controls are removed.
