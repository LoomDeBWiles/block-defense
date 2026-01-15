# Block Defense Task Beads Summary

All use cases from the planmaps have been converted to task beads.

## Summary

- **Total beads created:** 51 task beads + 6 epic parents = 57 total
- **No dependency cycles detected**
- **10 beads ready to work immediately** (P0 tasks with no blockers)

## Beads by Module

### Grid Module (BD-obf) - 6 tasks
- BD-obf.1: UC-GRID-1: Initialize grid from map data (P0)
- BD-obf.2: UC-GRID-2: Validate placement position (P0)
- BD-obf.3: UC-GRID-3: Mark tile occupied (P1)
- BD-obf.4: UC-GRID-4: Convert grid to world coordinates (P1)
- BD-obf.5: UC-GRID-5: Convert world to grid coordinates (P1)
- BD-obf.6: UC-GRID-6: Get path waypoints (P1)

### Enemy Module (BD-djl) - 7 tasks
- BD-djl.1: UC-ENM-1: Spawn enemy (P0)
- BD-djl.2: UC-ENM-2: Move along path (P0)
- BD-djl.3: UC-ENM-3: Take damage (P0)
- BD-djl.4: UC-ENM-4: Handle enemy death (P0)
- BD-djl.5: UC-ENM-5: Reach castle (P0)
- BD-djl.6: UC-ENM-6: Slime split on death (P2)
- BD-djl.7: UC-ENM-7: Query enemies in radius (for AoE) (P2)

### Tower Module (BD-9qs) - 9 tasks
- BD-9qs.1: UC-TWR-1: Spawn tower (P0)
- BD-9qs.2: UC-TWR-2: Find target enemy (P0)
- BD-9qs.3: UC-TWR-3: Rotate toward target (P1)
- BD-9qs.4: UC-TWR-4: Fire projectile (P0)
- BD-9qs.5: UC-TWR-5: Upgrade material tier (tiers 1→2) (P1)
- BD-9qs.6: UC-TWR-6: Upgrade to tier 3 with weapon choice (P1)
- BD-9qs.7: UC-TWR-7: Get upgrade cost (P2)
- BD-9qs.8: UC-TWR-8: Handle AoE damage (Trebuchet) (P2)
- BD-9qs.9: UC-TWR-9: Get weapon choices for tier (P2)

### Wave Module (BD-xxf) - 8 tasks
- BD-xxf.1: UC-WAV-1: Start wave (P0)
- BD-xxf.2: UC-WAV-2: Spawn enemies from wave data (P0)
- BD-xxf.3: UC-WAV-3: Detect wave complete (P0)
- BD-xxf.4: UC-WAV-4: Handle castle destruction (P0)
- BD-xxf.5: UC-WAV-5: Victory condition (P1)
- BD-xxf.6: UC-WAV-6: Provide wave data (P1)
- BD-xxf.7: UC-WAV-7: Get active spawn points (P1)
- BD-xxf.8: UC-WAV-8: Trigger tier unlock on wave clear (P1)

### Save Module (BD-bli) - 6 tasks
- BD-bli.1: UC-SAV-1: Load save on startup (P0)
- BD-bli.2: UC-SAV-2: Save progress on victory/game over (P0)
- BD-bli.3: UC-SAV-3: Check tier unlock (P1)
- BD-bli.4: UC-SAV-4: Unlock new tier (P1)
- BD-bli.5: UC-SAV-5: Reset save data (P2)
- BD-bli.6: UC-SAV-6: Migrate save version (P2)

### UI Module (BD-dl9) - 15 tasks
- BD-dl9.1: UC-UI-1: Start drag from tower bar (P0)
- BD-dl9.2: UC-UI-2: Drop tower on grid (touch release) (P0)
- BD-dl9.3: UC-UI-3: Show upgrade popup on tower tap (P1)
- BD-dl9.4: UC-UI-4: Execute upgrade from popup (P1)
- BD-dl9.5: UC-UI-5: Update gold display (P0)
- BD-dl9.6: UC-UI-6: Update wave display (P0)
- BD-dl9.7: UC-UI-7: Show game over screen (P1)
- BD-dl9.8: UC-UI-8: Show victory screen (P1)
- BD-dl9.9: UC-UI-9: Start wave button (P0)
- BD-dl9.10: UC-UI-10: Load unlocked tiers on startup (P1)
- BD-dl9.11: UC-UI-11: Show weapon choice popup (tier 3) (P1)
- BD-dl9.12: UC-UI-12: Select weapon in choice popup (P1)
- BD-dl9.13: UC-UI-13: Long-press tooltip on tower slot (P2)
- BD-dl9.14: UC-UI-14: Cancel drag (off-grid release) (P1)
- BD-dl9.15: UC-UI-15: Update castle HP display (P1)

## Priority Distribution
- **P0 (Critical):** 24 tasks
- **P1 (Core):** 19 tasks
- **P2 (Standard):** 8 tasks

## Key Dependencies Mapped

All UC dependencies from planmaps have been mapped to bead IDs:
- Grid → Enemy (waypoints)
- Grid → Tower (validation, occupation)
- Enemy → Tower (damage, AoE)
- Wave → Enemy (spawn)
- Wave → Save (unlocks)
- UI → All modules (visualization and control)

## Ready to Start

Immediate work available (no blockers):
1. BD-obf.1: Initialize grid from map data
2. BD-djl.3: Take damage
3. BD-9qs.2: Find target enemy
4. BD-bli.1: Load save on startup
5. BD-dl9.1: Start drag from tower bar
6. BD-dl9.5: Update gold display
7. BD-dl9.6: Update wave display
8. BD-obf.4: Convert grid to world coordinates
9. BD-obf.5: Convert world to grid coordinates
10. BD-9qs.7: Get upgrade cost

## Commands

View ready work:
```bash
bd ready
```

Check specific module:
```bash
bd list --parent BD-obf
```

View dependency tree:
```bash
bd dep tree BD-obf.1
```

Analyze work plan:
```bash
bv --robot-plan
```

## Completeness Verification

### All UCs Converted
- GRID: 6/6 ✓
- ENEMY: 7/7 ✓
- TOWER: 9/9 ✓
- WAVE: 8/8 ✓
- SAVE: 6/6 ✓
- UI: 15/15 ✓

**Total: 51/51 use cases converted to beads**

### Dependency Analysis
- No dependency cycles detected
- Key bottlenecks identified:
  - BD-djl.1 (Enemy spawn): 10 dependents
  - BD-obf.6 (Path waypoints): 7 dependents
  - BD-djl.2 (Enemy movement): 6 dependents
  - BD-xxf.3 (Wave complete): 4 dependents

### Cross-Module Dependencies Mapped
- Grid → Enemy (BD-obf.6 → BD-djl.1)
- Grid → Tower (BD-obf.2,3 → BD-9qs.1)
- Enemy → Tower (BD-djl.3 → BD-9qs.8)
- Wave → Save (BD-bli.4 → BD-xxf.8)
- All modules → UI

## Next Steps

1. Start with P0 no-blocker tasks:
   - BD-obf.1 (Grid init)
   - BD-djl.3 (Enemy damage)
   - BD-bli.1 (Save load)
   - BD-dl9.5/6 (UI displays)

2. Use `bv --robot-plan` for optimized work order

3. Track progress with `bd ready` and `bd list --status in_progress`

