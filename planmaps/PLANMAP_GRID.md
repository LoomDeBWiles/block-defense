# Planmap: Grid

> Manages map tiles and validates tower placement positions.

## Key Insight

**Grid is data, GridMap is visuals.** The `Grid` class tracks logical tile state (grass, path, occupied). Godot's `GridMap` node renders the 3D tiles. They stay in sync but serve different purposes.

## Internal Flow

```
Map Load
    │
    ▼
Parse tile data (from .tscn or JSON)
    │
    ▼
Initialize grid[x][y] = TileType
    │
    ▼
┌─────────────────────────────────┐
│  Runtime queries:               │
│  - can_place(pos) → bool        │
│  - mark_occupied(pos)           │
│  - get_tile(pos) → TileType     │
└─────────────────────────────────┘
```

## Map Layout

MVP uses a fixed 15x15 grid with:
- Castle at center (7,7)
- Dirt path from 2 entry points to castle
- Grass tiles for tower placement
- Off-map tiles marked `blocked`

```
Entry points: (0, 7) west, (14, 7) east
Path: Straight lines with 2-3 turns each
Castle: 3x3 area at (6,6) to (8,8)
```

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `init_grid` | `(width: int, height: int) -> void` | Create empty grid |
| `load_map` | `(map_data: Dictionary) -> void` | Load tile layout |
| `get_tile` | `(pos: Vector2i) -> TileType` | Query tile type |
| `can_place` | `(pos: Vector2i) -> bool` | Check if tower can be placed |
| `mark_occupied` | `(pos: Vector2i) -> void` | Mark tile as having tower |
| `clear_occupied` | `(pos: Vector2i) -> void` | Remove tower mark |
| `grid_to_world` | `(pos: Vector2i) -> Vector3` | Convert grid → world coords |
| `world_to_grid` | `(pos: Vector3) -> Vector2i` | Convert world → grid coords |

## Types

```gdscript
enum TileType {
    GRASS,      # Can place tower
    PATH,       # Enemy walks here
    CASTLE,     # Protected area
    BLOCKED,    # Off-map / obstacle
    OCCUPIED    # Tower already here
}

class_name Grid
var width: int
var height: int
var tiles: Array[Array]  # 2D array of TileType
var cell_size: float = 1.0  # World units per cell
```

## Module Use Cases

### UC-GRID-1: Initialize grid from map data

**Participates in:** IUC-1
**Touches:** `grid.gd`
**Depends:** none
**Priority:** P0

**Given:** Game starting, map data available
**When:** `load_map(map_data)` called
**Then:** Grid populated with tile types

**Contract:**
- Input: `map_data: Dictionary` with keys `width`, `height`, `tiles` (flat array)
- Output: none
- Side effect: `tiles` array populated
- Errors: none (invalid data = all BLOCKED)

**Acceptance:** `print(grid.get_tile(Vector2i(7,7)))` outputs `CASTLE`

### UC-GRID-2: Validate placement position

**Participates in:** IUC-1
**Touches:** `grid.gd`
**Depends:** UC-GRID-1
**Priority:** P0

**Given:** Grid initialized
**When:** `can_place(pos)` called
**Then:** Returns true only if tile is GRASS

**Contract:**
- Input: `pos: Vector2i`
- Output: `bool` — true if tile == GRASS
- Errors: none (out of bounds = false)

**Acceptance:** `assert(grid.can_place(Vector2i(5,5)) == true)`

### UC-GRID-3: Mark tile occupied

**Participates in:** IUC-1
**Touches:** `grid.gd`
**Depends:** UC-GRID-2
**Priority:** P1

**Given:** Tower placed at position
**When:** `mark_occupied(pos)` called
**Then:** Tile type changes to OCCUPIED

**Contract:**
- Input: `pos: Vector2i`
- Output: none
- Side effect: `tiles[pos.x][pos.y] = TileType.OCCUPIED`
- Errors: none (no-op if invalid)

**Acceptance:** `grid.mark_occupied(Vector2i(5,5)); assert(grid.can_place(Vector2i(5,5)) == false)`

### UC-GRID-4: Convert grid to world coordinates

**Participates in:** IUC-1, IUC-2
**Touches:** `grid.gd`
**Depends:** none
**Priority:** P1

**Given:** Grid position known
**When:** `grid_to_world(pos)` called
**Then:** Returns Vector3 world position (center of cell)

**Contract:**
- Input: `pos: Vector2i`
- Output: `Vector3` — world position at cell center
- Formula: `Vector3(pos.x * cell_size + cell_size/2, 0, pos.y * cell_size + cell_size/2)`
- Errors: none

**Acceptance:** `assert(grid.grid_to_world(Vector2i(0,0)) == Vector3(0.5, 0, 0.5))`

### UC-GRID-5: Convert world to grid coordinates

**Participates in:** IUC-1
**Touches:** `grid.gd`
**Depends:** none
**Priority:** P1

**Given:** Mouse click on world
**When:** `world_to_grid(world_pos)` called
**Then:** Returns grid cell containing that position

**Contract:**
- Input: `pos: Vector3`
- Output: `Vector2i` — grid coordinates
- Formula: `Vector2i(floor(pos.x / cell_size), floor(pos.z / cell_size))`
- Errors: none (out of bounds returns negative or overflow)

**Acceptance:** `assert(grid.world_to_grid(Vector3(5.5, 0, 5.5)) == Vector2i(5, 5))`

### UC-GRID-6: Get path waypoints

**Participates in:** IUC-5
**Touches:** `grid.gd`
**Depends:** UC-GRID-1
**Priority:** P1

**Given:** Map loaded with path tiles
**When:** Enemy needs path
**Then:** Returns ordered array of waypoints from spawn to castle

**Contract:**
- Input: `spawn_id: int` (0 = west, 1 = east, 2 = north)
- Output: `Array[Vector3]` — world positions
- Errors: none (empty array if invalid spawn_id)

**Note:** Waypoints are pre-defined in map data, not computed at runtime.

**Acceptance:** `assert(grid.get_path_waypoints(0).size() > 0)`
