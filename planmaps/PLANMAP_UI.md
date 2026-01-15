# Planmap: UI

> Handles HUD elements, tower selection, upgrade popup, and game state display. Touch-first for iPad browser.

## Key Insight

**Touch-first means larger targets and drag gestures.** All interactive elements min 44x44 CSS pixels. Tower placement uses drag-drop (not click-click). Long-press for tooltips instead of hover.

## Layout

```
┌──────────────────────────────────────────────────┐
│                 BLOCK DEFENSE                    │
│                                                  │
│                                                  │
│            [3D GAME VIEW]                        │
│         (tap tower = select)                     │
│                                                  │
├──────────────────────────────────────────────────┤
│ [T1][T2][T3]  [START]  🪙 500  ❤️ 100  WAVE 5/20│
└──────────────────────────────────────────────────┘
         ↑         ↑
    Drag to    Tap to start
     place       wave

Tower Bar (bottom-left):
├─ 3 tower slots (one per tier)
├─ Drag tower icon to grid to place
├─ Long-press = show stats tooltip
└─ Grayed out if insufficient gold

Upgrade Popup (appears above tapped tower):
┌─────────────────────┐
│ [BALLISTA] [TREBU]  │  ← Tier 3 choice (if applicable)
│ Scrap Wood → 75🪙   │  ← Next tier + cost
│    [UPGRADE]        │  ← Big touch button
│    [CANCEL]         │
└─────────────────────┘
```

## Touch Targets

| Element | Min Size | Notes |
|---------|----------|-------|
| Tower slot | 64x64 px | Draggable |
| Start Wave button | 80x44 px | Prominent |
| Upgrade button | 120x48 px | Easy to tap |
| Cancel/close | 44x44 px | Standard |

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `start_drag` | `(tier: MaterialTier) -> void` | Begin drag from toolbar |
| `end_drag` | `(grid_pos: Vector2i) -> void` | Drop tower on grid |
| `cancel_drag` | `() -> void` | Drag released off-grid |
| `show_upgrade_popup` | `(tower: Tower) -> void` | Display upgrade options |
| `hide_upgrade_popup` | `() -> void` | Close popup |
| `show_weapon_choice` | `(tower: Tower) -> void` | Tier 3 weapon picker |
| `update_gold` | `(amount: int) -> void` | Refresh gold display |
| `update_wave` | `(wave: int) -> void` | Refresh wave display |
| `update_castle_hp` | `(hp: int) -> void` | Refresh castle HP display |
| `show_game_over` | `() -> void` | Display defeat screen |
| `show_victory` | `(stats: GameStats) -> void` | Display win screen |

## Types

```gdscript
class_name UIManager extends CanvasLayer

var dragging_tier: MaterialTier = null
var drag_preview: Node3D = null  # Ghost tower during drag
var selected_tower: Tower = null

# Child nodes
var tower_bar: TowerBar
var gold_label: Label
var wave_label: Label
var castle_hp_label: Label
var start_button: Button
var upgrade_popup: UpgradePopup
var weapon_choice_popup: WeaponChoicePopup
var game_over_screen: Control
var victory_screen: Control

class_name GameStats
var waves_survived: int
var towers_built: int
var gold_earned: int
```

## Module Use Cases

### UC-UI-1: Start drag from tower bar

**Participates in:** IUC-1
**Touches:** `ui/tower_bar.gd`
**Depends:** none
**Priority:** P0

**Given:** Player touches tower slot in bar
**When:** Touch begins on slot
**Then:** Drag preview appears, follows finger

**Contract:**
- Input: touch event on tower slot
- Output: none
- Side effects: `dragging_tier` set, ghost tower spawned at touch position
- Errors: none (no drag if insufficient gold)

**Acceptance:** Touch Wood slot, ghost tower follows finger

### UC-UI-2: Drop tower on grid (touch release)

**Participates in:** IUC-1
**Touches:** `ui/tower_bar.gd`, `game_state.gd`
**Depends:** UC-UI-1, UC-GRID-2, UC-TWR-1
**Priority:** P0

**Given:** Dragging tower, finger over valid grass tile
**When:** Touch released
**Then:** Tower placed, gold deducted, drag ends

**Contract:**
- Input: touch release position
- Output: none
- Side effects: raycast to grid, `spawn_tower()` if valid, ghost removed
- Invalid drop: ghost snaps back, no tower placed
- Errors: none

**Acceptance:** Drag Wood to grass, release, tower appears

### UC-UI-3: Show upgrade popup on tower tap

**Participates in:** IUC-4
**Touches:** `ui/upgrade_popup.gd`
**Depends:** UC-TWR-7
**Priority:** P1

**Given:** Tower exists, not in drag mode
**When:** Player taps tower
**Then:** Popup shows next tier and cost

**Contract:**
- Input: tap on tower
- Output: none
- Side effects: Popup visible above tower, shows upgrade info
- Max tier: shows "MAX LEVEL" instead of upgrade button
- Errors: none

**Acceptance:** Tap Wood tower, popup shows "Scrap Wood - 75🪙"

### UC-UI-4: Execute upgrade from popup

**Participates in:** IUC-4
**Touches:** `ui/upgrade_popup.gd`
**Depends:** UC-UI-3, UC-TWR-5
**Priority:** P1

**Given:** Upgrade popup open, player has gold
**When:** Player taps Upgrade button
**Then:** Tower upgraded, gold deducted, popup closes

**Contract:**
- Input: tap on Upgrade button
- Output: none
- Side effects: `upgrade_tower(selected_tower)`, gold reduced, popup hidden
- Insufficient gold: button disabled (grayed)
- Errors: none

**Acceptance:** Tap Upgrade with 100 gold, verify tower.material == MaterialTier.SCRAP_WOOD

### UC-UI-5: Update gold display

**Participates in:** IUC-3, IUC-4
**Touches:** `ui_manager.gd`
**Depends:** none
**Priority:** P0

**Given:** Gold amount changes
**When:** `gold_changed` signal received
**Then:** Gold label updated

**Contract:**
- Input: `amount: int`
- Output: none
- Side effects: `gold_label.text = "🪙 " + str(amount)`
- Errors: none

**Acceptance:** Kill enemy, gold display increases

### UC-UI-6: Update wave display

**Participates in:** IUC-5
**Touches:** `ui_manager.gd`
**Depends:** none
**Priority:** P0

**Given:** Wave changes
**When:** `wave_started` or `wave_complete` signal received
**Then:** Wave label updated

**Contract:**
- Input: `wave: int`
- Output: none
- Side effects: `wave_label.text = "WAVE " + str(wave) + "/20"`
- Errors: none

**Acceptance:** Complete wave 1, display shows "WAVE 2/20"

### UC-UI-7: Show game over screen

**Participates in:** IUC-7
**Touches:** `ui_manager.gd`
**Depends:** none
**Priority:** P1

**Given:** Castle destroyed
**When:** `game_over` signal received
**Then:** Defeat screen displayed with retry button

**Contract:**
- Input: none
- Output: none
- Side effects: `game_over_screen.visible = true`, game paused
- Retry button: resets game state
- Errors: none

**Acceptance:** Let castle HP reach 0, see "GAME OVER" + retry

### UC-UI-8: Show victory screen

**Participates in:** IUC-8
**Touches:** `ui_manager.gd`
**Depends:** none
**Priority:** P1

**Given:** Wave 20 cleared
**When:** `victory` signal received
**Then:** Victory screen with stats displayed

**Contract:**
- Input: `stats: GameStats`
- Output: none
- Side effects: `victory_screen.visible = true`, shows stats
- Stats shown: waves, towers built, gold earned
- Errors: none

**Acceptance:** Complete wave 20, see "VICTORY" + stats

### UC-UI-9: Start wave button

**Participates in:** IUC-5
**Touches:** `ui_manager.gd`
**Depends:** UC-WAV-1
**Priority:** P0

**Given:** Build phase active
**When:** Player taps "Start Wave" button
**Then:** Wave begins, button changes state

**Contract:**
- Input: tap event
- Output: none
- Side effects: `start_wave()` called, button shows "WAVE X" during combat
- During combat: button disabled/hidden
- Errors: none

**Acceptance:** Tap Start Wave, enemies spawn

### UC-UI-10: Load unlocked tiers on startup

**Participates in:** IUC-9
**Touches:** `ui/tower_bar.gd`
**Depends:** UC-SAV-1
**Priority:** P1

**Given:** Game starting, save data exists
**When:** UI initializes
**Then:** Tower bar shows only unlocked tiers

**Contract:**
- Input: none (reads from Save)
- Output: none
- Side effects: Locked tiers show lock icon or hidden
- Default: Tier 1 always unlocked
- Errors: none

**Acceptance:** New game shows only Wood. After winning, refresh shows all tiers.

### UC-UI-11: Show weapon choice popup (tier 3)

**Participates in:** IUC-10
**Touches:** `ui/weapon_choice.gd`
**Depends:** UC-TWR-9
**Priority:** P1

**Given:** Player upgrading to Solid Metal
**When:** Upgrade initiated from tier 2
**Then:** Popup shows Ballista vs Trebuchet choice

**Contract:**
- Input: `tower: Tower`
- Output: none
- Side effects: WeaponChoicePopup visible with two weapon buttons
- Each button shows: icon, name, key stat (damage vs AoE)
- Errors: none

**Acceptance:** Upgrade Scrap Wood tower, see two weapon options

### UC-UI-12: Select weapon in choice popup

**Participates in:** IUC-10
**Touches:** `ui/weapon_choice.gd`
**Depends:** UC-UI-11, UC-TWR-6
**Priority:** P1

**Given:** Weapon choice popup open
**When:** Player taps weapon button
**Then:** Tower upgraded with chosen weapon, popup closes

**Contract:**
- Input: tap on Ballista or Trebuchet button
- Output: none
- Side effects: `upgrade_tower(tower, weapon)`, gold deducted, popup hidden
- Errors: none

**Acceptance:** Choose Trebuchet, tower gains AoE weapon

### UC-UI-13: Long-press tooltip on tower slot

**Participates in:** standalone
**Touches:** `ui/tower_bar.gd`
**Depends:** none
**Priority:** P2

**Given:** Player wants tower info
**When:** Long-press (500ms) on tower slot
**Then:** Tooltip shows stats

**Contract:**
- Input: long-press event
- Output: none
- Side effects: Tooltip appears showing damage, range, fire rate
- Release: tooltip hides
- Errors: none

**Acceptance:** Long-press Wood slot, see "Slingshot: 10 dmg, 3 range"

### UC-UI-14: Cancel drag (off-grid release)

**Participates in:** IUC-1
**Touches:** `ui/tower_bar.gd`
**Depends:** UC-UI-1
**Priority:** P1

**Given:** Dragging tower
**When:** Touch released over invalid area (not grass)
**Then:** Drag cancelled, no tower placed

**Contract:**
- Input: touch release off-grid or on invalid tile
- Output: none
- Side effects: Ghost removed, no state change
- Errors: none

**Acceptance:** Drag tower, release over UI bar, no tower placed

### UC-UI-15: Update castle HP display

**Participates in:** IUC-6
**Touches:** `ui_manager.gd`
**Depends:** none
**Priority:** P1

**Given:** Castle HP changes
**When:** `castle_damaged` signal received
**Then:** Castle HP label/bar updated in UI

**Contract:**
- Input: `hp: int` via signal
- Output: none
- Side effects: Update castle HP label (e.g., "❤️ 100" → "❤️ 90")
- Errors: none

**Acceptance:** Let enemy reach castle, verify castle HP display decreases

## Signals (listened)

| Signal | From | Handler |
|--------|------|---------|
| `gold_changed` | GameState | `update_gold()` |
| `wave_started` | Wave | `update_wave()`, hide start button |
| `wave_complete` | Wave | `update_wave()`, show start button |
| `castle_damaged` | Wave | `update_castle_hp()` |
| `game_over` | Wave | `show_game_over()` |
| `victory` | Wave | `show_victory()` |
