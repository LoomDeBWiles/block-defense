# Planmap: Tower

> Handles tower placement, enemy targeting, weapon firing, and material upgrades.

## Key Insight

**Tier 3 offers a weapon choice.** Tiers 1-2 have fixed weapons (Slingshot, Bow). Tier 3 lets player choose Ballista (single-target) or Trebuchet (AoE). This choice is permanent for that tower.

## Internal Flow

```
Tower Spawned
    │
    ▼
Set material (Wood) + weapon (Slingshot)
    │
    ▼
┌─────────────────────────────────────────┐
│  Combat Loop (_physics_process):        │
│  1. If no target → find_target()        │
│  2. If target out of range → clear      │
│  3. If target valid → rotate toward     │
│  4. If fire_cooldown <= 0 → fire()      │
└─────────────────────────────────────────┘
    │
    ▼
fire() → spawn projectile → reset cooldown
```

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `spawn_tower` | `(grid_pos: Vector2i) -> Tower` | Create tower at position |
| `upgrade_tower` | `(tower: Tower, weapon?: WeaponType) -> bool` | Upgrade tier |
| `get_upgrade_cost` | `(tower: Tower) -> int` | Cost for next tier |
| `can_upgrade` | `(tower: Tower) -> bool` | Check if upgradeable |
| `get_weapon_choices` | `(tier: MaterialTier) -> Array[WeaponType]` | Weapons for tier |

## Types

```gdscript
enum MaterialTier { WOOD = 1, SCRAP_WOOD = 2, SOLID_METAL = 3 }
enum WeaponType { SLINGSHOT, BOW, BALLISTA, TREBUCHET }

class_name Tower extends Node3D

var grid_pos: Vector2i
var material: MaterialTier = MaterialTier.WOOD
var weapon: WeaponType = WeaponType.SLINGSHOT
var target: Enemy = null
var fire_cooldown: float = 0.0

# Derived from weapon type
var damage: int
var range_radius: float
var fire_rate: float
var aoe_radius: float  # 0 for single-target
```

## Weapon Stats

| Weapon | Tier | Damage | Range | Fire Rate | AoE |
|--------|------|--------|-------|-----------|-----|
| Slingshot | 1 | 10 | 3.0 | 1.0/s | 0 |
| Bow | 2 | 15 | 4.0 | 1.5/s | 0 |
| Ballista | 3 | 40 | 5.0 | 0.5/s | 0 |
| Trebuchet | 3 | 25 | 6.0 | 0.3/s | 2.0 |

## Tier → Weapon Mapping

| Tier | Default Weapon | Choice? |
|------|----------------|---------|
| 1 (Wood) | Slingshot | No |
| 2 (Scrap Wood) | Bow | No |
| 3 (Solid Metal) | — | Yes: Ballista OR Trebuchet |

## Upgrade Costs

| From | To | Cost |
|------|----|------|
| — | Wood | 50 (place) |
| Wood | Scrap Wood | 75 |
| Scrap Wood | Solid Metal | 150 |

## Module Use Cases

### UC-TWR-1: Spawn tower

**Participates in:** IUC-1
**Touches:** `tower.gd`
**Depends:** UC-GRID-2, UC-GRID-3
**Priority:** P0

**Given:** Valid grid position, player has 50 gold
**When:** `spawn_tower(grid_pos)` called
**Then:** Tower instance created, positioned, added to scene

**Contract:**
- Input: `grid_pos: Vector2i`
- Output: `Tower` — new tower instance
- Side effects: Tower added to Towers container, grid marked occupied
- Errors: returns null if position invalid

**Acceptance:** `var t = spawn_tower(Vector2i(5,5)); assert(t != null and t.material == MaterialTier.WOOD)`

### UC-TWR-2: Find target enemy

**Participates in:** IUC-2
**Touches:** `tower.gd`
**Depends:** none
**Priority:** P0

**Given:** Tower exists, enemies in scene
**When:** `_find_target()` called (internal)
**Then:** Nearest enemy within range assigned to `target`

**Contract:**
- Input: none (uses tower position and range)
- Output: none (sets `self.target`)
- Logic: Query all enemies, filter by distance < range, pick nearest
- Errors: none (target = null if no valid enemies)

**Acceptance:** Place tower, spawn enemy in range, verify `tower.target != null`

### UC-TWR-3: Rotate toward target

**Participates in:** IUC-2
**Touches:** `tower.gd`
**Depends:** UC-TWR-2
**Priority:** P1

**Given:** Tower has target
**When:** `_physics_process()` runs
**Then:** Tower rotates to face target (Y-axis only)

**Contract:**
- Input: none
- Output: none
- Side effect: `look_at()` called with target position
- Errors: none

**Acceptance:** Tower faces enemy, rotation.y changes as enemy moves

### UC-TWR-4: Fire projectile

**Participates in:** IUC-2
**Touches:** `tower.gd`, `projectile.gd`
**Depends:** UC-TWR-2
**Priority:** P0

**Given:** Tower has target, cooldown expired
**When:** Fire condition met
**Then:** Projectile spawned, moves toward target

**Contract:**
- Input: none
- Output: none
- Side effects: Projectile instantiated, cooldown reset to `1.0 / fire_rate`
- Errors: none

**Acceptance:** Tower fires, projectile visible moving toward enemy

### UC-TWR-5: Upgrade material tier (tiers 1→2)

**Participates in:** IUC-4
**Touches:** `tower.gd`
**Depends:** none
**Priority:** P1

**Given:** Tower at tier 1 or 2, player has gold
**When:** `upgrade_tower(tower)` called (no weapon param)
**Then:** Material increases, weapon auto-assigned

**Contract:**
- Input: `tower: Tower`
- Output: `bool` — true if upgraded
- Side effects: `material` incremented, `weapon` set to default for tier
- Errors: returns false if max tier or insufficient gold

**Tier → Weapon (auto):**
| MaterialTier.WOOD | WeaponType.SLINGSHOT |
| MaterialTier.SCRAP_WOOD | WeaponType.BOW |

**Acceptance:** `upgrade_tower(t); assert(t.material == MaterialTier.SCRAP_WOOD and t.weapon == WeaponType.BOW)`

### UC-TWR-6: Upgrade to tier 3 with weapon choice

**Participates in:** IUC-4, IUC-10
**Touches:** `tower.gd`
**Depends:** UC-TWR-5
**Priority:** P1

**Given:** Tower at tier 2, player has gold, weapon choice made
**When:** `upgrade_tower(tower, weapon)` called with weapon param
**Then:** Material set to SOLID_METAL, chosen weapon equipped

**Contract:**
- Input: `tower: Tower`, `weapon: WeaponType` (BALLISTA or TREBUCHET)
- Output: `bool` — true if upgraded
- Side effects: `material = SOLID_METAL`, `weapon = chosen`
- Errors: returns false if wrong tier, insufficient gold, or invalid weapon

**Acceptance:** `upgrade_tower(t, WeaponType.TREBUCHET); assert(t.weapon == WeaponType.TREBUCHET)`

### UC-TWR-7: Get upgrade cost

**Participates in:** IUC-4
**Touches:** `tower.gd`
**Depends:** none
**Priority:** P2

**Given:** Tower instance
**When:** `get_upgrade_cost(tower)` called
**Then:** Returns gold cost for next tier

**Contract:**
- Input: `tower: Tower`
- Output: `int` — cost, or -1 if max tier
- Errors: none

**Cost table:**
| Current | Next | Cost |
|---------|------|------|
| WOOD | SCRAP_WOOD | 75 |
| SCRAP_WOOD | SOLID_METAL | 150 |
| SOLID_METAL | — | -1 |

**Acceptance:** `assert(get_upgrade_cost(wood_tower) == 75)`

### UC-TWR-8: Handle AoE damage (Trebuchet)

**Participates in:** IUC-2
**Touches:** `tower.gd`, `projectile.gd`
**Depends:** UC-TWR-4, UC-ENM-3
**Priority:** P2

**Given:** Trebuchet fires
**When:** Projectile reaches target
**Then:** All enemies within AoE radius take damage

**Contract:**
- Input: `impact_pos: Vector3`, `aoe_radius: float`, `damage: int`
- Output: none
- Side effect: All enemies in radius take damage via `enemy.take_damage()`
- Errors: none

**Acceptance:** Fire trebuchet at cluster, multiple enemies take damage

### UC-TWR-9: Get weapon choices for tier

**Participates in:** IUC-10
**Touches:** `tower.gd`
**Depends:** none
**Priority:** P2

**Given:** Tier with weapon choice
**When:** `get_weapon_choices(tier)` called
**Then:** Returns available weapons for that tier

**Contract:**
- Input: `tier: MaterialTier`
- Output: `Array[WeaponType]`
- Returns:
  - SOLID_METAL → [BALLISTA, TREBUCHET]
  - Others → empty array (no choice)
- Errors: none

**Acceptance:** `assert(get_weapon_choices(MaterialTier.SOLID_METAL).size() == 2)`
