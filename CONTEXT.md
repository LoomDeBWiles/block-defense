# Context

## Commands

| Task | Command |
|------|---------|
| Open in Godot | `godot project.godot` |
| Run game | `godot --path . scenes/main.tscn` |
| Export web | `godot --headless --export-release "Web"` |

## Architecture

Isometric tower defense game built with Godot 4.3 (GDScript, WebGL target).

**Modules:**
- **Grid** - Map tiles, placement validation (`scripts/grid.gd`)
- **Tower** - Placement, targeting, firing, upgrades (`scripts/tower.gd`)
- **Enemy** - Waypoint movement, damage, death (`scripts/enemy.gd`)
- **Wave** - Spawning, progression, win/lose (`scripts/wave.gd`)
- **UI** - HUD, popups, touch handling (`scripts/ui/*.gd`)
- **Save** - localStorage persistence (`scripts/save.gd`)

**Autoloads:** `GameState`, `Save`

**Scene tree:**
```
Main
├── World (Node3D)
│   ├── Grid, GridMap, Castle
│   ├── Towers, Enemies, Projectiles
│   └── WaveManager
├── Camera3D (isometric)
└── UI (CanvasLayer)
```

## Gotchas

- `wave.gd:_spawn_wave()`: Uses await for spawn intervals - don't call during _ready
- `save.gd`: Only works with `OS.has_feature("web")` - test in browser
- `tower.gd`: Combat loop only runs when `GameState.phase == COMBAT`

## Patterns

- **Type enums**: All in `scripts/types.gd` - import via `Types.GamePhase`, etc.
- **Signals over polling**: GameState emits signals, UI listens
- **Static helpers on entities**: `Enemy.get_enemies_in_radius()`, `Tower.get_weapon_choices()`
