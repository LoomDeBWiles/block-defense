# Planmap: Wave

> Manages wave spawning, progression, unlock triggers, and win/lose conditions.

## Key Insight

**Spawn points unlock progressively.** Waves 1-5 use one spawn (west). Waves 6-12 add east spawn. Waves 13-20 add north. This teaches players to expand defense gradually.

## Internal Flow

```
Player taps "Start Wave"
    │
    ▼
Load wave_data[current_wave]
    │
    ▼
GamePhase = COMBAT
    │
    ▼
┌─────────────────────────────────────────┐
│  Spawn Loop:                            │
│  For each active spawn_point:           │
│    For each enemy in spawn_list:        │
│      spawn_enemy(type, waypoints)       │
│      wait(spawn_interval)               │
└─────────────────────────────────────────┘
    │
    ▼
Monitor: enemies_remaining == 0
    │
    ├── Yes + wave < 20 → next wave, check unlocks, GamePhase = BUILD
    ├── Yes + wave == 20 → VICTORY
    └── Castle HP <= 0 → DEFEAT
```

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `start_wave` | `() -> void` | Begin current wave |
| `get_wave_data` | `(wave: int) -> WaveData` | Get spawn info |
| `is_wave_complete` | `() -> bool` | Check if all enemies dead |
| `advance_wave` | `() -> void` | Increment wave counter |
| `get_active_spawns` | `(wave: int) -> Array[int]` | Which spawns are active |

## Types

```gdscript
class_name WaveData
var spawns: Array[SpawnGroup]  # One per active spawn point
var spawn_interval: float      # Seconds between spawns

class_name SpawnGroup
var spawn_point: int           # 0=west, 1=east, 2=north
var enemies: Array[SpawnEntry]

class_name SpawnEntry
var enemy_type: EnemyType
var count: int
```

## Spawn Point Progression

| Wave Range | Active Spawns | Notes |
|------------|---------------|-------|
| 1-5 | West (0) | Single front, learn basics |
| 6-12 | West + East (0, 1) | Two fronts, split defense |
| 13-20 | West + East + North (0, 1, 2) | Three fronts, full challenge |

## Wave Definitions (MVP)

| Wave | West | East | North | Special |
|------|------|------|-------|---------|
| 1 | 5 Zombie | — | — | Tutorial |
| 2 | 8 Zombie | — | — | — |
| 3 | 6 Zombie, 3 Skeleton | — | — | Intro skeleton |
| 4 | 8 Zombie, 4 Skeleton | — | — | — |
| 5 | 4 Slime, 4 Skeleton | — | — | Intro slime, **unlock T2** |
| 6 | 6 Zombie | 4 Zombie | — | Two fronts begin |
| 7 | 5 Skeleton | 5 Zombie | — | — |
| 8 | 4 Slime | 4 Slime | — | — |
| 9 | 6 Zombie, 4 Skeleton | 6 Zombie | — | — |
| 10 | 8 Zombie, Tank Boss | 6 Zombie, 4 Skeleton | — | **Boss wave, unlock T3** |
| 11-12 | Mix | Mix | — | Increasing counts |
| 13 | 6 Zombie | 6 Zombie | 4 Zombie | Three fronts begin |
| 14-19 | Mix | Mix | Mix | Escalating |
| 20 | Heavy mix | Heavy mix | Heavy mix + Tank Boss | **Final wave** |

## Spawn Intervals

| Wave Range | Interval |
|------------|----------|
| 1-5 | 1.5s |
| 6-10 | 1.2s |
| 11-15 | 1.0s |
| 16-20 | 0.8s |

## Unlock Triggers

| Wave Cleared | Unlocks | Signal |
|--------------|---------|--------|
| 5 | Tier 2 (Scrap Wood) | `tier_unlocked(2)` |
| 10 | Tier 3 (Solid Metal) | `tier_unlocked(3)` |

## Module Use Cases

### UC-WAV-1: Start wave

**Participates in:** IUC-5
**Touches:** `wave.gd`
**Depends:** UC-ENM-1
**Priority:** P0

**Given:** Player in build phase, taps Start Wave
**When:** `start_wave()` called
**Then:** Phase changes, spawning begins

**Contract:**
- Input: none
- Output: none
- Side effects: `GameState.phase = GamePhase.COMBAT`, spawn coroutine started
- Errors: none (no-op if already in combat)

**Acceptance:** Tap Start Wave, enemies begin spawning

### UC-WAV-2: Spawn enemies from wave data

**Participates in:** IUC-5
**Touches:** `wave.gd`
**Depends:** UC-WAV-1, UC-ENM-1, UC-GRID-6
**Priority:** P0

**Given:** Wave started
**When:** Spawn coroutine running
**Then:** Enemies spawned from active spawn points

**Contract:**
- Input: none (uses `get_wave_data(GameState.wave)`)
- Output: none
- Side effects: Enemies created at each active spawn point
- Logic: For each SpawnGroup, spawn enemies with interval
- Errors: none

**Acceptance:** Wave 6 spawns from both west and east

### UC-WAV-3: Detect wave complete

**Participates in:** IUC-5
**Touches:** `wave.gd`
**Depends:** UC-ENM-4
**Priority:** P0

**Given:** Combat phase, enemies exist
**When:** Last enemy dies
**Then:** Wave marked complete, unlocks checked

**Contract:**
- Input: none (monitors Enemies container)
- Output: none
- Side effects: `advance_wave()`, check unlock triggers, emit `wave_complete`
- Logic: Connect to `enemy_died`, check if Enemies empty
- Errors: none

**Acceptance:** Kill all wave 5 enemies, verify tier 2 unlocked

### UC-WAV-4: Handle castle destruction

**Participates in:** IUC-6, IUC-7
**Touches:** `wave.gd`
**Depends:** UC-ENM-5
**Priority:** P0

**Given:** Enemy reaches castle
**When:** `reached_castle` signal received
**Then:** Castle HP reduced, check for game over

**Contract:**
- Input: `damage: int`
- Output: none
- Side effects: `GameState.castle_hp -= damage`, emit `game_over` if HP <= 0
- Errors: none

**Acceptance:** Let enemies reach castle until HP = 0, verify game_over emitted

### UC-WAV-5: Victory condition

**Participates in:** IUC-8
**Touches:** `wave.gd`
**Depends:** UC-WAV-3
**Priority:** P1

**Given:** Wave 20 complete
**When:** Last enemy dies
**Then:** Victory triggered, save updated

**Contract:**
- Input: none
- Output: none
- Side effects: Emit `victory`, call `record_game_end(true, ...)`
- Logic: After `advance_wave()`, check if wave > 20
- Errors: none

**Acceptance:** Complete wave 20, verify victory signal + save updated

### UC-WAV-6: Provide wave data

**Participates in:** IUC-5
**Touches:** `wave.gd`
**Depends:** none
**Priority:** P1

**Given:** Wave number known
**When:** `get_wave_data(wave)` called
**Then:** Returns spawn configuration for that wave

**Contract:**
- Input: `wave: int`
- Output: `WaveData`
- Errors: returns empty WaveData for invalid wave

**Note:** Wave data stored as Dictionary constant or JSON resource.

**Acceptance:** `var data = get_wave_data(6); assert(data.spawns.size() == 2)`

### UC-WAV-7: Get active spawn points

**Participates in:** IUC-5
**Touches:** `wave.gd`
**Depends:** none
**Priority:** P1

**Given:** Wave number
**When:** `get_active_spawns(wave)` called
**Then:** Returns array of spawn point indices

**Contract:**
- Input: `wave: int`
- Output: `Array[int]`
- Returns:
  - Wave 1-5: [0]
  - Wave 6-12: [0, 1]
  - Wave 13-20: [0, 1, 2]
- Errors: none

**Acceptance:** `assert(get_active_spawns(13) == [0, 1, 2])`

### UC-WAV-8: Trigger tier unlock on wave clear

**Participates in:** IUC-5
**Touches:** `wave.gd`
**Depends:** UC-WAV-3, UC-SAV-4
**Priority:** P1

**Given:** Wave cleared that has unlock
**When:** `advance_wave()` completes
**Then:** Appropriate tier unlocked

**Contract:**
- Input: none (uses current wave)
- Output: none
- Side effects: Call `unlock_tier()` for milestone waves
- Unlock map:
  - Wave 5 cleared → unlock tier 2
  - Wave 10 cleared → unlock tier 3
- Errors: none

**Acceptance:** Clear wave 5, tier 2 becomes available in toolbar

## Signals

| Signal | Emitted When | Payload |
|--------|--------------|---------|
| `wave_started` | Combat begins | `wave: int` |
| `wave_complete` | All enemies dead | `wave: int` |
| `game_over` | Castle HP <= 0 | none |
| `victory` | Wave 20 cleared | none |
| `spawn_activated` | New spawn point enabled | `spawn_id: int` |
