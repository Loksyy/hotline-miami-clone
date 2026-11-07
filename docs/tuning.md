# Tuning Project Gagugaga

For live changes, open **Esc ? Developer Lab**. Search by name, adjust a field, then resume. Text/list fields apply with Enter. **Save tuning** writes `user://developer_tuning.cfg`; saved overrides take priority over source defaults. **Reset to source defaults**, then **Save tuning**, restores the source values persistently. Starting health/ammo and enemy composition need a fresh playtest; layout settings affect new layouts.

To change source defaults, edit [game_settings.gd](../scripts/settings/game_settings.gd), then stop and run the game again. Distances are world pixels, speeds are pixels/second, and times are seconds unless a comment says otherwise. Existing values are preserved; the extra settings expose behavior that previously lived in code.

| Change | Settings to search for |
| --- | --- |
| Player movement, body size, health | `PLAYER_SPEED`, `PLAYER_COLLISION_RADIUS`, `PLAYER_HIT_RADIUS`, `PLAYER_HEALTH` |
| Starting weapon and ammo | `START_WEAPON`, `MAGAZINE_SIZE`, `START_RESERVE_AMMO` |
| Pistol fire rate, reload, damage, range | `FIRE_INTERVAL`, `RELOAD_TIME`, `SHOT_DAMAGE`, `SHOT_RANGE` |
| Melee range, damage, stun | `PUNCH_RANGE`, `BAT_RANGE`, `BAT_DAMAGE`, `FINISHER_DAMAGE`, `STUN_DURATION` |
| Throw distance and speed | `THROW_SPEED`, `THROW_LIFETIME`, `THROW_HIT_RADIUS` |
| Enemy health and body size | `ENEMY_HEALTH`, `ENEMY_COLLISION_RADIUS`, `ENEMY_HIT_RADIUS` |
| Enemy movement and awareness | `ENEMY_GUN_SPEED`, `ENEMY_MELEE_SPEED`, `ENEMY_SIGHT_RANGE`, `ENEMY_VISION_DOT`, `ENEMY_REACTION_TIME` |
| Enemy attacks | `ENEMY_BULLET_DAMAGE`, `ENEMY_MELEE_DAMAGE`, `ENEMY_FIRE_INTERVAL`, `ENEMY_MELEE_INTERVAL` |
| Enemy weapons and loot | `ENEMY_WEAPON_PATTERN`, `ENEMIES_DROP_WEAPONS`, `DROPPED_PISTOL_AMMO` |
| New layout dimensions and enemies | `LAYOUT_MAX_WIDTH`, `LAYOUT_MAX_HEIGHT`, `LAYOUT_ENEMY_POSITIONS` |
| New layout windows | `LAYOUT_MAX_WINDOWS`, `LAYOUT_WINDOW_SPACING` |
| Starting layout | `DEFAULT_LAYOUT_ASSET`, `DEFAULT_LAYOUT_FRAME`, `DEFAULT_LAYOUT_FRAMES` |
| Wall and door thickness | `WALL_THICKNESS`, `DOOR_LEAF_THICKNESS` |
| Character and furniture artwork size | `ACTOR_SPRITE_SCALE`, `PROP_SCALE_OVERRIDES` |
| Camera and editor zoom | `PLAY_CAMERA_ZOOM`, `PLAY_CAMERA_FOLLOW_SPEED`, `EDITOR_DEFAULT_ZOOM`, `EDITOR_MIN_ZOOM`, `EDITOR_MAX_ZOOM` |
| Blood, particles, shake and animation | `BLOOD_*`, `PARTICLE_*`, `*_SHAKE`, `*_ANIMATION_*` |
| Map/editor limits | `MAP_WIDTH_CELLS`, `MAP_HEIGHT_CELLS`, `CELL_SIZE`, `MAX_ENEMIES`, `MAX_MAP_OBJECTS`, `UNDO_LIMIT` |
| Initial volume, fullscreen and FPS cap | `DEFAULT_VOLUME`, `DEFAULT_FULLSCREEN`, `DEFAULT_FRAME_LIMIT`, `FRAME_LIMIT_OPTIONS` |

## Examples

- Faster pistol: change `FIRE_INTERVAL` from `0.18` to `0.12`. Shots per second are approximately `1 / FIRE_INTERVAL`.
- Larger magazine: set `MAGAZINE_SIZE = 12`; reserve ammo and dropped-weapon ammo have separate settings.
- All melee enemies: set `ENEMY_WEAPON_PATTERN = [false]`. `[true, false, true]` repeats pistol, melee, pistol in spawn order.
- Four enemies in newly generated layouts: set `LAYOUT_ENEMY_POSITIONS = [0.2, 0.4, 0.6, 0.8]`. Values select positions along reachable floor. Duplicated positions and start/exit cells are skipped. `[]` generates none.
- Smaller couch: change its entry in `PROP_SCALE_OVERRIDES`. This sets the scale for newly placed props; existing props retain their saved scale and can be edited in the inspector.

## What updates when

Combat settings apply on the next run/playtest. Layout-generation settings apply when creating or inserting a newly generated layout, not to terrain already saved in a map. Enemy positions already in a map are edited in the editor.

Saved pause-menu preferences override `DEFAULT_*` preferences. Change them through Settings to update your current profile; developer defaults are for first use.

Visual sprite scale does not change actor collision size. Tune body radius and hit radius separately. Wall and door thickness should remain smaller than `CELL_SIZE`. Durations and collision steps should be positive; counts should be nonnegative. The weapon pattern uses booleans, and layout fractions should be between 0 and 1.

Canvas dimensions and cell size are advanced format settings: changing dimensions can invalidate saves made at a different size; changing cell size does not rescale saved prop positions. Original 32x22 saves have an explicit migration path. Prefer layout dimensions for making a building larger or smaller.

Frame counts, sprite crop coordinates, tile IDs and UI geometry remain in their owning modules: those describe the source art or file format rather than gameplay balance. See the [developer guide](development.md) for those modules.
