# Planmap: Block Defense Overview

> Isometric tower defense game where players upgrade floor materials to unlock weapons.

## Game Loop

```
Start (500 gold)
     │
     ▼
┌─────────────────────────────────────────────┐
│  BUILD PHASE (between waves)                │
│  Player: drag tower from bar to grid        │
│  Player: tap tower → upgrade material       │
│  Player: tap "Start Wave"                   │
└─────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────┐
│  WAVE PHASE                                 │
│  Wave spawns enemies at entry points        │
│  Enemies follow path to castle              │
│  Towers auto-target and fire                │
│  Enemy dies → player earns gold             │
│  Enemy reaches castle → castle takes damage │
└─────────────────────────────────────────────┘
     │
     ├── Castle HP > 0 AND wave < 20 → loop
     ├── Wave == 20 complete → WIN
     └── Castle HP <= 0 → LOSE
```

## Entities

**Tower:** Defensive structure placed on grid.

| Field | Type | Notes |
|-------|------|-------|
| id | int | Godot instance_id |
| grid_pos | Vector2i | Grid coordinates |
| material | MaterialTier | Current tier (1-3) |
| weapon | WeaponType | Equipped weapon |
| target | Enemy \| null | Current target |

**Enemy:** Hostile unit moving toward castle.

| Field | Type | Notes |
|-------|------|-------|
| id | int | Godot instance_id |
| enemy_type | EnemyType | Zombie, Skeleton, etc. |
| hp | int | Current health |
| max_hp | int | Starting health |
| speed | float | Movement speed |
| gold_value | int | Gold on death |
| damage_to_castle | int | Damage dealt when reaching castle |
| path_index | int | Current waypoint |

**Projectile:** Shot fired by tower toward enemy.

| Field | Type | Notes |
|-------|------|-------|
| source | Tower | Which tower fired |
| target | Enemy | Target enemy |
| damage | int | Damage to apply |
| speed | float | Travel speed |

**GameState:** Runtime game state (singleton).

| Field | Type | Notes |
|-------|------|-------|
| gold | int | Player currency |
| wave | int | Current wave (1-20) |
| phase | GamePhase | `build`, `combat` |
| castle_hp | int | Castle health (max 100) |
| towers | Array[Tower] | Placed towers |
| enemies | Array[Enemy] | Active enemies |

**SaveData:** Persisted player progress.

| Field | Type | Notes |
|-------|------|-------|
| unlocked_tiers | Array[MaterialTier] | Available for purchase |
| highest_wave | int | Best progress |
| total_gold_earned | int | Lifetime stat |
| games_won | int | Victory count |

## Modules

| Module | Purpose | Planmap |
|--------|---------|---------|
| Grid | Map tiles, placement validation | `PLANMAP_GRID.md` |
| Tower | Tower placement, targeting, firing | `PLANMAP_TOWER.md` |
| Enemy | Enemy movement, damage, death | `PLANMAP_ENEMY.md` |
| Wave | Wave spawning, progression | `PLANMAP_WAVE.md` |
| UI | HUD, tower bar, upgrade popup | `PLANMAP_UI.md` |
| Save | Persistence, unlock progression | `PLANMAP_SAVE.md` |

## Module Dependencies

| Module | Depends On | Depended On By |
|--------|------------|----------------|
| Grid | — | Tower, Enemy, Wave, UI |
| Tower | Grid, Enemy | UI |
| Enemy | Grid | Tower, Wave |
| Wave | Enemy, Grid, Save | UI |
| UI | Grid, Tower, Wave, Save | — |
| Save | — | UI, Wave |

## Constants

| Constant | Values | Used By |
|----------|--------|---------|
| GamePhase | `BUILD`, `COMBAT` | Wave, UI |
| MaterialTier | `WOOD` (1), `SCRAP_WOOD` (2), `SOLID_METAL` (3) | Tower, UI, Save |
| WeaponType | `SLINGSHOT`, `BOW`, `BALLISTA`, `TREBUCHET` | Tower |
| EnemyType | `ZOMBIE`, `SKELETON`, `SLIME`, `TANK_BOSS` | Enemy, Wave |
| TileType | `GRASS`, `PATH`, `CASTLE`, `BLOCKED`, `OCCUPIED` | Grid |

## Material → Weapon Mapping (Staggered)

| Tier | Material | Weapons Available | Notes |
|------|----------|-------------------|-------|
| 1 | Wood | Slingshot | Single weapon |
| 2 | Scrap Wood | Bow | Single weapon |
| 3 | Solid Metal | Ballista, Trebuchet | Choose one |

## Weapon Stats

| Weapon | Tier | Damage | Range | Fire Rate (shots/s) | Special |
|--------|------|--------|-------|---------------------|---------|
| Slingshot | 1 | 10 | 3 | 1.0 | — |
| Bow | 2 | 15 | 4 | 1.5 | — |
| Ballista | 3 | 40 | 5 | 0.5 | High single-target |
| Trebuchet | 3 | 25 | 6 | 0.3 | AoE (radius 2.0) |

## Initial Values

| Field | Value | Notes |
|-------|-------|-------|
| gold | 500 | Starting currency |
| wave | 1 | First wave |
| castle_hp | 100 | Max castle health |
| phase | BUILD | Start in build phase |

## Tower Costs

| Action | Cost |
|--------|------|
| Place Wood tower | 50 |
| Upgrade Wood → Scrap Wood | 75 |
| Upgrade Scrap Wood → Solid Metal | 150 |

## Enemy Stats

| Type | HP | Speed | Gold | Introduced |
|------|----|----|------|------------|
| Zombie | 30 | 1.0 | 10 | Wave 1 |
| Skeleton | 20 | 1.5 | 8 | Wave 3 |
| Slime | 50 | 0.8 | 15 | Wave 5 |
| Tank Boss | 500 | 0.5 | 200 | Wave 10 |

## Spawn Points (Progressive)

| Wave Range | Spawn Points |
|------------|--------------|
| 1-5 | 1 (west only) |
| 6-12 | 2 (west + east) |
| 13-20 | 3 (west + east + north) |

## User Workflows

| ID | Workflow | Validates |
|----|----------|-----------|
| WF-1 | Drag tower, tower kills enemy, earn gold | Core loop |
| WF-2 | Upgrade tower, verify damage increase | Upgrade system |
| WF-3 | Survive 20 waves, see win screen | Full game |
| WF-4 | Close game, reopen, progress preserved | Persistence |

## Integration Use Cases

### IUC-1: Tower Placement

**Modules:** UI → Grid → Tower
**Module UCs:** UC-UI-1, UC-UI-2, UC-UI-14, UC-GRID-1, UC-GRID-2, UC-GRID-3, UC-GRID-4, UC-GRID-5, UC-TWR-1

**Given:** Player has sufficient gold, valid grass tile
**When:** Player drags tower to tile (touch)
**Then:** Gold deducted, tower appears, grid cell marked occupied

**Acceptance:** Drag tower to (5,5), verify `GameState.gold` decreased by 50

### IUC-2: Tower Combat

**Modules:** Tower → Enemy
**Module UCs:** UC-TWR-2, UC-TWR-3, UC-TWR-4, UC-TWR-8, UC-ENM-2, UC-ENM-3, UC-ENM-7, UC-GRID-4

**Given:** Tower placed, enemy in range
**When:** Combat phase active
**Then:** Tower targets enemy, fires projectile, enemy takes damage

**Acceptance:** Tower fires at enemy within range, enemy HP decreases

### IUC-3: Enemy Death Reward

**Modules:** Enemy → Tower → UI
**Module UCs:** UC-ENM-3, UC-ENM-4, UC-ENM-6, UC-UI-5

**Given:** Enemy HP reaches 0
**When:** Enemy dies
**Then:** Enemy removed, gold added to player, UI updated

**Acceptance:** Kill zombie, verify gold increases by 10

### IUC-4: Tower Upgrade

**Modules:** UI → Tower → Grid
**Module UCs:** UC-UI-3, UC-UI-4, UC-UI-5, UC-TWR-5, UC-TWR-6, UC-TWR-7, UC-GRID-2

**Given:** Tower selected, player has gold for upgrade
**When:** Player taps upgrade
**Then:** Material tier increases, weapon changes, gold deducted

**Acceptance:** Upgrade Wood tower, verify material == MaterialTier.SCRAP_WOOD

### IUC-5: Wave Completion

**Modules:** Wave → Enemy → Grid → UI
**Module UCs:** UC-WAV-1, UC-WAV-2, UC-WAV-3, UC-WAV-6, UC-WAV-7, UC-WAV-8, UC-ENM-1, UC-GRID-6, UC-UI-6, UC-UI-9, UC-SAV-4

**Given:** All enemies in wave killed
**When:** Last enemy dies
**Then:** Wave counter increments, phase changes to build

**Acceptance:** Clear wave 1, verify `GameState.wave == 2` and `GameState.phase == GamePhase.BUILD`

### IUC-6: Castle Damage

**Modules:** Enemy → Wave → UI
**Module UCs:** UC-ENM-5, UC-WAV-4, UC-UI-15

**Given:** Enemy reaches castle
**When:** Enemy touches castle
**Then:** Castle HP reduced, enemy removed, UI updated

**Acceptance:** Let zombie reach castle, verify castle HP decreased

### IUC-7: Game Over (Loss)

**Modules:** Wave → UI
**Module UCs:** UC-WAV-4, UC-UI-7

**Given:** Castle HP <= 0
**When:** Castle destroyed
**Then:** Game pauses, loss screen displayed

**Acceptance:** Reduce castle HP to 0, verify loss screen shown

### IUC-8: Victory

**Modules:** Wave → UI → Save
**Module UCs:** UC-WAV-5, UC-UI-8, UC-SAV-2

**Given:** Wave 20 cleared
**When:** Last enemy of wave 20 dies
**Then:** Victory screen displayed, progress saved

**Acceptance:** Complete wave 20, verify victory screen + save updated

### IUC-9: Load Saved Progress

**Modules:** Save → UI
**Module UCs:** UC-SAV-1, UC-SAV-3, UC-SAV-6, UC-UI-10

**Given:** Player has previous save
**When:** Game loads
**Then:** Unlocked tiers available, stats displayed

**Acceptance:** Win game, refresh browser, unlocked tiers still available

### IUC-10: Tier 3 Weapon Choice

**Modules:** UI → Tower
**Module UCs:** UC-UI-11, UC-UI-12, UC-TWR-6, UC-TWR-9

**Given:** Player upgrading to Solid Metal
**When:** Upgrade initiated
**Then:** Popup shows Ballista vs Trebuchet choice

**Acceptance:** Upgrade to tier 3, see weapon selection popup

## Scene Structure

```
Main.tscn
├── World (Node3D)
│   ├── GridMap
│   ├── Castle
│   ├── Towers (container)
│   ├── Enemies (container)
│   └── Projectiles (container)
├── Camera3D (isometric)
└── UI (CanvasLayer)
    ├── TowerBar
    ├── GoldDisplay
    ├── WaveDisplay
    ├── UpgradePopup
    └── WeaponChoicePopup
```

## File Layout

```
block-defense/
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── tower.tscn
│   ├── enemy.tscn
│   └── projectile.tscn
├── scripts/
│   ├── game_state.gd
│   ├── grid.gd
│   ├── tower.gd
│   ├── enemy.gd
│   ├── wave.gd
│   ├── save.gd
│   └── ui/
│       ├── tower_bar.gd
│       ├── upgrade_popup.gd
│       └── weapon_choice.gd
├── assets/
│   ├── models/
│   └── sounds/
└── planmaps/
```

## Platform Target

**Primary:** iPad browser (touch-first)
- Drag-drop tower placement
- Tap to select/upgrade
- No keyboard shortcuts
- Touch-friendly button sizes (min 44x44 px)

## MVP Scope

**In scope:**
- 3 material tiers with 4 weapons (staggered)
- 3 enemy types + 1 boss
- 20 waves, 1→3 spawn points
- Single map
- Full save/load (localStorage)
- Essential audio (shoot, hit, UI)
- Touch-first UI

**Out of scope (post-MVP):**
- Tiers 4-8 (Copper → Obsidian)
- Advanced enemies (Spider, Enderman)
- Endless mode
- Multiple maps
- Music
