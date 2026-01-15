# Planmap Review Proposal

## Errors

### 1. [PLANMAP_OVERVIEW.md:225] IUC-5 missing UC-GRID-6

**Problem:** UC-GRID-6 declares "Participates in: IUC-5" but is not listed in IUC-5's Module UCs.

```
IUC-5 Module UCs: UC-WAV-1, UC-WAV-2, UC-WAV-3, UC-WAV-6, UC-WAV-7, UC-WAV-8, UC-ENM-1, UC-UI-6, UC-UI-9, UC-SAV-4
```

UC-WAV-2 depends on UC-GRID-6, and UC-GRID-6 provides path waypoints needed for spawning enemies.

**Fix:**
```diff
- **Module UCs:** UC-WAV-1, UC-WAV-2, UC-WAV-3, UC-WAV-6, UC-WAV-7, UC-WAV-8, UC-ENM-1, UC-UI-6, UC-UI-9, UC-SAV-4
+ **Module UCs:** UC-WAV-1, UC-WAV-2, UC-WAV-3, UC-WAV-6, UC-WAV-7, UC-WAV-8, UC-ENM-1, UC-GRID-6, UC-UI-6, UC-UI-9, UC-SAV-4
```

**Why:** UC-GRID-6 is a dependency of UC-WAV-2 and provides essential functionality (waypoints) for the wave completion integration. The Modules line should also include Grid.

---

### 2. [PLANMAP_OVERVIEW.md:222] IUC-5 Modules missing Grid

**Problem:** IUC-5 Modules lists "Wave → Enemy → UI" but UC-GRID-6 participates in this IUC.

**Fix:**
```diff
- **Modules:** Wave → Enemy → UI
+ **Modules:** Wave → Enemy → Grid → UI
```

**Why:** Grid module provides UC-GRID-6 which is essential for wave spawning (provides waypoint paths).

---

### 3. [PLANMAP_ENEMY.md:136] UC-ENM-4 title contains "and"

**Problem:** UC title "Die and reward gold" violates sizing rule: titles should be ≤10 words without "and".

**Fix:**
```diff
- ### UC-ENM-4: Die and reward gold
+ ### UC-ENM-4: Handle enemy death
```

Update acceptance criteria reference accordingly.

**Why:** "and" in titles suggests the UC is doing multiple distinct things and should potentially be split. In this case, the UC is cohesive (death triggers gold reward), but the title should reflect a single concept.

---

### 4. [PLANMAP_OVERVIEW.md:74-82] GameState missing castle_hp field

**Problem:** GameState entity definition lacks `castle_hp` field, but UC-WAV-4 and UC-ENM-5 reference `GameState.castle_hp`.

```
UC-WAV-4: Side effects: `GameState.castle_hp -= damage`
UC-ENM-5: Side effects: `GameState.castle_hp -= damage_to_castle`
```

**Fix:**
```diff
 | Field | Type | Notes |
 |-------|------|-------|
 | gold | int | Player currency |
 | wave | int | Current wave (1-20) |
 | phase | GamePhase | `build`, `combat` |
+| castle_hp | int | Castle health (max 100) |
 | towers | Array[Tower] | Placed towers |
 | enemies | Array[Enemy] | Active enemies |
```

**Why:** The Castle entity is defined separately (lines 68-72) but never referenced in UCs. All UC code references `GameState.castle_hp` instead of `Castle.hp`, so castle_hp should be in GameState.

---

### 5. [PLANMAP_OVERVIEW.md:220] IUC-4 acceptance uses lowercase enum

**Problem:** Acceptance criterion uses `material == `scrap_wood`` with lowercase, inconsistent with enum definition.

```gdscript
enum MaterialTier { WOOD = 1, SCRAP_WOOD = 2, SOLID_METAL = 3 }
```

**Fix:**
```diff
- **Acceptance:** Upgrade Wood tower, verify material == `scrap_wood`
+ **Acceptance:** Upgrade Wood tower, verify material == MaterialTier.SCRAP_WOOD
```

**Why:** Consistency with code. The acceptance criteria should use actual GDScript enum values (MaterialTier.SCRAP_WOOD) not lowercase string representations.

---

### 6. [PLANMAP_OVERVIEW.md:231] IUC-5 acceptance uses lowercase enum

**Problem:** Acceptance criterion uses `phase == build` without enum qualification.

**Fix:**
```diff
- **Acceptance:** Clear wave 1, verify `GameState.wave == 2` and `phase == build`
+ **Acceptance:** Clear wave 1, verify `GameState.wave == 2` and `GameState.phase == GamePhase.BUILD`
```

**Why:** Consistency with GDScript enum definition. GamePhase values should be qualified.

---

### 7. [PLANMAP_UI.md:169] UC-UI-4 acceptance not executable

**Problem:** Acceptance uses descriptive text "tower becomes Scrap Wood" instead of verifiable code.

**Fix:**
```diff
- **Acceptance:** Tap Upgrade with 100 gold, tower becomes Scrap Wood
+ **Acceptance:** Tap Upgrade with 100 gold, verify tower.material == MaterialTier.SCRAP_WOOD
```

**Why:** Acceptance criteria should be executable/verifiable code that can be tested programmatically, not just descriptions of expected behavior.

---

### 8. [PLANMAP_GRID.md:182] UC-GRID-6 contract missing spawn point 2

**Problem:** Contract lists `spawn_id: int` as (0 = west, 1 = east) but OVERVIEW defines 3 spawn points (west, east, north).

OVERVIEW specifies waves 13-20 use 3 spawn points including north.

**Fix:**
```diff
- Input: `spawn_id: int` (0 = west, 1 = east)
+ Input: `spawn_id: int` (0 = west, 1 = east, 2 = north)
```

**Why:** All three spawn points should be documented. UC-WAV-7 mentions getting active spawn points which can return [0, 1, 2] for waves 13-20.

---

## Warnings

### 1. [PLANMAP_OVERVIEW.md:115-123] Enum values use lowercase

**Problem:** Constants table lists enum values in lowercase (e.g., `wood`, `scrap_wood`) while code definitions use uppercase (WOOD, SCRAP_WOOD).

```
| MaterialTier | `wood` (1), `scrap_wood` (2), `solid_metal` (3) |
```

vs.

```gdscript
enum MaterialTier { WOOD = 1, SCRAP_WOOD = 2, SOLID_METAL = 3 }
```

**Recommendation:** Use uppercase enum values in OVERVIEW constants table to match code:

```diff
- | MaterialTier | `wood` (1), `scrap_wood` (2), `solid_metal` (3) | Tower, UI, Save |
+ | MaterialTier | `WOOD` (1), `SCRAP_WOOD` (2), `SOLID_METAL` (3) | Tower, UI, Save |
```

Apply similar changes to GamePhase, WeaponType, EnemyType, and TileType.

**Why:** Reduces confusion between display names (for UI) and code values (for implementation). Developers will copy-paste from planmaps, so values should match actual enum definitions.

---

### 2. [PLANMAP_UI.md] Many manual acceptance criteria

**Problem:** Multiple UCs have manual test descriptions instead of executable acceptance criteria.

Examples:
- UC-UI-1: "Touch Wood slot, ghost tower follows finger"
- UC-UI-3: "Tap Wood tower, popup shows 'Scrap Wood - 75🪙'"
- UC-UI-7: "Let castle HP reach 0, see 'GAME OVER' + retry"

**Recommendation:** Consider adding automated test equivalents where feasible:

```gdscript
# UC-UI-1
var slot = get_node("TowerBar/WoodSlot")
var touch = InputEventScreenTouch.new()
# ... simulate drag, assert ghost exists

# UC-UI-5
kill_enemy()
await get_tree().process_frame
assert(gold_label.text == "🪙 510")
```

**Why:** Manual tests are harder to verify during code review and cannot be run in CI. UI integration tests using Godot's input simulation would provide better confidence.

---

### 3. [PLANMAP_OVERVIEW.md:68-72] Castle entity never referenced

**Problem:** Castle entity is defined with hp and max_hp fields, but no UC references `Castle.hp`. All UCs use `GameState.castle_hp` instead.

**Recommendation:** Either:
1. Remove Castle entity and document castle_hp directly in GameState (simpler), or
2. Change all references to use `GameState.castle.hp` with `castle: Castle` field in GameState

**Why:** Unused entity definitions create confusion about the actual data model.

---

## Questions

### 1. [PLANMAP_UI.md:12-21] Castle HP display missing from UI

**Context:** UI layout mockup shows gold and wave display but no castle HP indicator:

```
│ [T1][T2][T3]  [START]     🪙 500    WAVE 5/20   │
```

Castle can be destroyed (IUC-6, IUC-7) and HP is tracked in GameState, but there's no UC for displaying it.

**Question:** Should there be a castle HP display in the UI (e.g., "❤️ 100")? If yes, which UC should handle updating it when castle takes damage?

**Suggested UC:** UC-UI-15: Update castle HP display
- Participates in: IUC-6
- When: `castle_damaged` signal received
- Then: Update HP label/bar

---

### 2. [PLANMAP_OVERVIEW.md] Initial gold amount inconsistency

**Context:** Game loop shows "Start (500 gold)" but GameState doesn't specify initial gold value.

**Question:** Should GameState entity definition include a note about initial values (gold = 500, wave = 1, castle_hp = 100)?

---

### 3. [PLANMAP_TOWER.md:68] Fire rate units ambiguous

**Context:** Weapon stats table shows fire rate as "1.0/s" which could mean:
- 1.0 shots per second (0.5s cooldown), or
- 1.0 second cooldown between shots (1.0/s rate)

UC-TWR-4 clarifies: "cooldown reset to `1.0 / fire_rate`"

**Question:** Would it be clearer to specify cooldown directly in the weapon stats table instead of fire rate? Or add explicit unit clarification (e.g., "Fire Rate (shots/sec)")?

---

## Missing UCs

### 1. UC-UI-15: Update castle HP display

**Needed by:** IUC-6 (castle damage), IUC-7 (game over)

**Contract:**
- Input: `hp: int` via signal
- Output: none
- Side effects: Update castle HP label/bar in UI

**Rationale:** Castle can take damage and be destroyed, but there's no feedback mechanism in the UI. Players need to see castle health to make strategic decisions.

---

## Summary

**7 planmaps reviewed:**
- PLANMAP_OVERVIEW.md
- PLANMAP_GRID.md
- PLANMAP_TOWER.md
- PLANMAP_ENEMY.md
- PLANMAP_WAVE.md
- PLANMAP_UI.md
- PLANMAP_SAVE.md

**Findings:**
- 8 errors (IUC consistency, entity definitions, enum usage, naming)
- 3 warnings (style consistency, test automation, unused entities)
- 3 questions (missing UI element, initial values, unit clarity)
- 1 missing UC (castle HP display)

**Overall assessment:** The planmaps are well-structured with comprehensive UC coverage and clear integration flows. Main issues are:
1. IUC-5 missing UC-GRID-6 (critical for wave spawning)
2. GameState entity incomplete (missing castle_hp)
3. Enum value representation inconsistent between overview and code

All dependency relationships are valid (no cycles detected). Module boundaries are clear and appropriate.
