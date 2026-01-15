# Planmap: Enemy

> Handles enemy spawning, waypoint movement, damage, death, and castle collision.

## Key Insight

**Enemies follow waypoints, not navigation mesh.** For pre-defined paths, waypoints are simpler and faster than real-time pathfinding. Enemy moves to waypoint[0], then waypoint[1], etc.

## Internal Flow

```
Enemy Spawned
    │
    ▼
Receive waypoints array from spawner
    │
    ▼
┌─────────────────────────────────────────┐
│  Movement Loop (_physics_process):      │
│  1. Move toward current waypoint        │
│  2. If reached → advance path_index     │
│  3. If path_index >= waypoints.size()   │
│     → reached castle → deal damage      │
└─────────────────────────────────────────┘
    │
    ├── take_damage() called → reduce HP
    │       └── HP <= 0 → die()
    │
    └── reached_castle() → damage castle → remove self
```

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `spawn_enemy` | `(type: EnemyType, waypoints: Array[Vector3]) -> Enemy` | Create enemy |
| `take_damage` | `(amount: int) -> void` | Apply damage to enemy |
| `die` | `() -> void` | Handle death (gold, cleanup) |
| `get_enemies_in_radius` | `(pos: Vector3, radius: float) -> Array[Enemy]` | For AoE |

## Types

```gdscript
enum EnemyType { ZOMBIE, SKELETON, SLIME, TANK_BOSS }

class_name Enemy extends Node3D

var enemy_type: EnemyType
var hp: int
var max_hp: int
var speed: float
var gold_value: int
var damage_to_castle: int

var waypoints: Array[Vector3]
var path_index: int = 0
```

## Enemy Stats

| Type | HP | Speed | Gold | Castle Dmg |
|------|----|----|------|------------|
| Zombie | 30 | 1.0 | 10 | 10 |
| Skeleton | 20 | 1.5 | 8 | 5 |
| Slime | 50 | 0.8 | 15 | 15 |
| Tank Boss | 500 | 0.5 | 200 | 50 |

## Slime Split Mechanic

When Slime dies, spawn 2 smaller slimes at death position. Mini-slimes have:
- HP: 15 (30% of parent)
- Speed: 1.2 (150% of parent)
- Gold: 5 each
- No further splitting

## Module Use Cases

### UC-ENM-1: Spawn enemy

**Participates in:** IUC-5
**Touches:** `enemy.gd`
**Depends:** UC-GRID-6
**Priority:** P0

**Given:** Wave spawning enemies
**When:** `spawn_enemy(type, waypoints)` called
**Then:** Enemy created with stats, positioned at waypoints[0]

**Contract:**
- Input: `type: EnemyType`, `waypoints: Array[Vector3]`
- Output: `Enemy` — new instance
- Side effects: Enemy added to Enemies container
- Errors: none

**Acceptance:** `var e = spawn_enemy(EnemyType.ZOMBIE, waypoints); assert(e.hp == 30)`

### UC-ENM-2: Move along path

**Participates in:** IUC-2
**Touches:** `enemy.gd`
**Depends:** UC-ENM-1
**Priority:** P0

**Given:** Enemy spawned with waypoints
**When:** `_physics_process(delta)` runs
**Then:** Enemy moves toward current waypoint at `speed` units/sec

**Contract:**
- Input: `delta: float`
- Output: none
- Side effects: `position` updated, `path_index` incremented when waypoint reached
- Logic: `position = position.move_toward(waypoints[path_index], speed * delta)`
- Waypoint reached when distance < 0.1

**Acceptance:** Enemy visually moves along path

### UC-ENM-3: Take damage

**Participates in:** IUC-2, IUC-3
**Touches:** `enemy.gd`
**Depends:** none
**Priority:** P0

**Given:** Enemy exists with HP > 0
**When:** `take_damage(amount)` called
**Then:** HP reduced, death triggered if HP <= 0

**Contract:**
- Input: `amount: int`
- Output: none
- Side effects: `hp -= amount`, calls `die()` if hp <= 0
- Errors: none (negative damage heals — don't do that)

**Acceptance:** `e.take_damage(10); assert(e.hp == 20)`

### UC-ENM-4: Handle enemy death

**Participates in:** IUC-3
**Touches:** `enemy.gd`
**Depends:** UC-ENM-3
**Priority:** P0

**Given:** Enemy HP reaches 0
**When:** `die()` called
**Then:** Gold added to GameState, enemy removed from scene

**Contract:**
- Input: none
- Output: none
- Side effects: `GameState.gold += gold_value`, emits `enemy_died` signal, `queue_free()`
- Errors: none

**Acceptance:** Kill zombie, verify gold increased by 10

### UC-ENM-5: Reach castle

**Participates in:** IUC-6
**Touches:** `enemy.gd`
**Depends:** UC-ENM-2
**Priority:** P0

**Given:** Enemy reaches final waypoint
**When:** `path_index >= waypoints.size()`
**Then:** Castle takes damage, enemy removed

**Contract:**
- Input: none
- Output: none
- Side effects: `GameState.castle_hp -= damage_to_castle`, emits `reached_castle` signal, `queue_free()`
- Errors: none

**Acceptance:** Let enemy reach castle, verify castle HP decreased

### UC-ENM-6: Slime split on death

**Participates in:** IUC-3
**Touches:** `enemy.gd`
**Depends:** UC-ENM-4
**Priority:** P2

**Given:** Slime enemy dies
**When:** `die()` called on Slime
**Then:** 2 mini-slimes spawned at death position

**Contract:**
- Input: none (type check internal)
- Output: none
- Side effects: 2 new enemies spawned with reduced stats, inherit remaining waypoints
- Logic: Mini-slimes start at current `path_index`, continue parent's path
- Errors: none

**Acceptance:** Kill slime, verify 2 mini-slimes appear

### UC-ENM-7: Query enemies in radius (for AoE)

**Participates in:** IUC-2
**Touches:** `enemy.gd`
**Depends:** none
**Priority:** P2

**Given:** AoE damage needs targets
**When:** `get_enemies_in_radius(pos, radius)` called
**Then:** Returns all enemies within radius of position

**Contract:**
- Input: `pos: Vector3`, `radius: float`
- Output: `Array[Enemy]`
- Logic: Check distance for each enemy in scene
- Errors: none (empty array if none)

**Acceptance:** `var targets = get_enemies_in_radius(Vector3(5,0,5), 2.0)`

## Signals

| Signal | Emitted When | Payload |
|--------|--------------|---------|
| `enemy_died` | Enemy HP <= 0 | `enemy: Enemy` |
| `reached_castle` | Enemy completes path | `damage: int` |
