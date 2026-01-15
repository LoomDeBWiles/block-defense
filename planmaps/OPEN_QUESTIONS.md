# Open Questions from Planmap Review

The following questions require human input before proceeding with implementation.

---

## 1. Initial gold amount inconsistency

**Context:** Game loop shows "Start (500 gold)" but GameState entity definition doesn't specify initial values.

**Question:** Should GameState entity definition include a note about initial values (gold = 500, wave = 1, castle_hp = 100)?

**Suggested fix:** Add a note in the GameState entity table or add an initialization section to PLANMAP_OVERVIEW.md specifying all initial values.

---

## 2. Fire rate units ambiguous

**Context:** Weapon stats table shows fire rate as "1.0/s" which could mean:
- 1.0 shots per second (0.5s cooldown), or
- 1.0 second cooldown between shots (1.0/s rate)

UC-TWR-4 clarifies: "cooldown reset to `1.0 / fire_rate`"

**Question:** Would it be clearer to specify cooldown directly in the weapon stats table instead of fire rate? Or add explicit unit clarification (e.g., "Fire Rate (shots/sec)")?

**Current interpretation:** Fire rate is shots per second (e.g., 1.0/s = 1 shot per second = 1.0s cooldown).

**Suggested clarification options:**
1. Add column header: "Fire Rate (shots/s)"
2. Replace with "Cooldown (s)" column showing direct cooldown values
3. Add note under table explaining the conversion

---

## Notes

- These questions were identified during the planmap review process
- Once answered, update the relevant planmaps and delete this file
- This file triggers Phase 1 loop for planmap refinement
