# Planmap: Save

> Handles persistent storage of player progress using browser localStorage.

## Key Insight

**Save progress, not game state.** We persist unlocked tiers and lifetime stats. We do NOT save mid-game state (towers placed, current wave). Each session starts fresh, but unlocks carry over.

## Storage Structure

```
localStorage key: "block_defense_save"

{
  "version": 1,
  "unlocked_tiers": [1, 2, 3],     // MaterialTier values
  "highest_wave": 20,
  "total_gold_earned": 15420,
  "games_played": 12,
  "games_won": 3,
  "towers_built": 156
}
```

## Unlock Progression

| Achievement | Unlocks |
|-------------|---------|
| Start game | Tier 1 (Wood) |
| Clear wave 5 | Tier 2 (Scrap Wood) |
| Clear wave 10 | Tier 3 (Solid Metal) |

Unlocks persist across sessions. Once unlocked, always available.

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `load_save` | `() -> SaveData` | Load from localStorage |
| `save_progress` | `(data: SaveData) -> void` | Write to localStorage |
| `is_tier_unlocked` | `(tier: MaterialTier) -> bool` | Check availability |
| `unlock_tier` | `(tier: MaterialTier) -> void` | Mark tier as unlocked |
| `record_game_end` | `(won: bool, wave: int, gold: int, towers: int) -> void` | Update stats |
| `reset_save` | `() -> void` | Clear all progress |

## Types

```gdscript
class_name SaveData

var version: int = 1
var unlocked_tiers: Array[int] = [1]  # Tier 1 always unlocked
var highest_wave: int = 0
var total_gold_earned: int = 0
var games_played: int = 0
var games_won: int = 0
var towers_built: int = 0

func to_json() -> String:
    return JSON.stringify({
        "version": version,
        "unlocked_tiers": unlocked_tiers,
        "highest_wave": highest_wave,
        "total_gold_earned": total_gold_earned,
        "games_played": games_played,
        "games_won": games_won,
        "towers_built": towers_built
    })

static func from_json(json: String) -> SaveData:
    # Parse and return SaveData, with defaults for missing fields
```

## Module Use Cases

### UC-SAV-1: Load save on startup

**Participates in:** IUC-9
**Touches:** `save.gd`
**Depends:** none
**Priority:** P0

**Given:** Game starting
**When:** `load_save()` called
**Then:** SaveData returned from localStorage (or defaults if none)

**Contract:**
- Input: none
- Output: `SaveData`
- Logic: Read `localStorage["block_defense_save"]`, parse JSON
- Missing key: return default SaveData (tier 1 unlocked, zeros)
- Corrupted data: return default, log warning
- Errors: none (always returns valid SaveData)

**Acceptance:** Clear localStorage, load game, only tier 1 available

### UC-SAV-2: Save progress on victory/game over

**Participates in:** IUC-8
**Touches:** `save.gd`
**Depends:** UC-SAV-1
**Priority:** P0

**Given:** Game ended (win or loss)
**When:** `record_game_end(won, wave, gold, towers)` called
**Then:** Stats updated, localStorage written

**Contract:**
- Input: `won: bool`, `wave: int`, `gold: int`, `towers: int`
- Output: none
- Side effects:
  - `games_played += 1`
  - `games_won += 1` if won
  - `highest_wave = max(highest_wave, wave)`
  - `total_gold_earned += gold`
  - `towers_built += towers`
  - Write to localStorage
- Errors: none

**Acceptance:** Win game, refresh browser, stats preserved

### UC-SAV-3: Check tier unlock

**Participates in:** IUC-9
**Touches:** `save.gd`
**Depends:** UC-SAV-1
**Priority:** P1

**Given:** SaveData loaded
**When:** `is_tier_unlocked(tier)` called
**Then:** Returns true if tier in unlocked list

**Contract:**
- Input: `tier: MaterialTier`
- Output: `bool`
- Logic: `tier.value in unlocked_tiers`
- Errors: none

**Acceptance:** `assert(is_tier_unlocked(MaterialTier.WOOD) == true)`

### UC-SAV-4: Unlock new tier

**Participates in:** IUC-5 (wave milestone)
**Touches:** `save.gd`
**Depends:** UC-SAV-1
**Priority:** P1

**Given:** Player reaches wave milestone
**When:** `unlock_tier(tier)` called
**Then:** Tier added to unlocked list, saved

**Contract:**
- Input: `tier: MaterialTier`
- Output: none
- Side effects: Add to `unlocked_tiers` if not present, save
- Duplicate: no-op
- Errors: none

**Unlock triggers:**
| Wave | Unlocks |
|------|---------|
| 5 | Tier 2 |
| 10 | Tier 3 |

**Acceptance:** Clear wave 5, verify tier 2 now in unlocked_tiers

### UC-SAV-5: Reset save data

**Participates in:** standalone (settings menu)
**Touches:** `save.gd`
**Depends:** none
**Priority:** P2

**Given:** Player wants fresh start
**When:** `reset_save()` called
**Then:** localStorage cleared, default SaveData active

**Contract:**
- Input: none
- Output: none
- Side effects: Remove `block_defense_save` from localStorage
- Errors: none

**Acceptance:** Reset save, only tier 1 available

### UC-SAV-6: Migrate save version

**Participates in:** IUC-9
**Touches:** `save.gd`
**Depends:** UC-SAV-1
**Priority:** P2

**Given:** Save data from older version
**When:** `load_save()` detects version mismatch
**Then:** Data migrated to current version

**Contract:**
- Input: none (internal to load_save)
- Output: migrated SaveData
- Logic: Check `version` field, apply migrations sequentially
- Current version: 1 (no migrations yet)
- Missing fields: use defaults
- Errors: none

**Acceptance:** Old save with missing field loads successfully with default

## Signals

| Signal | Emitted When | Payload |
|--------|--------------|---------|
| `tier_unlocked` | New tier becomes available | `tier: MaterialTier` |
| `progress_saved` | After successful save | none |

## Storage Limits

Browser localStorage typically allows 5-10 MB. Our save is <1 KB.

No quota handling needed — save is tiny.
