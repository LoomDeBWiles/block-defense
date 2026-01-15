# Open Questions for Block Defense Planmaps

> Answer these to refine the planmaps. Current assumptions noted in brackets.

## Architecture

### Q1: Path Type
Is this pre-defined path TD or maze-building TD?
- **Pre-defined**: Enemies follow fixed dirt paths, towers placed only on grass
- **Maze-building**: Towers block paths, enemies recalculate routes

**[Assumed: Pre-defined]** — Image shows clear dirt path, simpler to implement.

a: i want predefind

### Q2: Spawn Points
Single spawn or multiple entry points?
- **Single**: One spawn, one path to castle
- **Multiple**: 2-4 entry points converging on castle

**[Assumed: Multiple (2-4)]** — Image shows enemies from multiple directions.

a: start from single and go to multiple, up to 3

### Q3: Tower Placement Rules
Where can towers be placed?
- **Grass only**: Pre-designated build spots on grass tiles
- **Any grass tile**: Any grass tile is valid
- **Path-adjacent**: Only tiles adjacent to the path

**[Assumed: Any grass tile]** — Most flexibility, standard TD approach.

a: standard approach

## Scope (MVP)

### Q4: Tower Tiers for MVP
How many material tiers for initial release?
- Full 8 tiers (ambitious)
- First 4 tiers (Wood → Copper)
- First 3 tiers (Wood → Solid Metal)

**[Assumed: First 4 tiers]** — Gives weapon variety without overwhelming scope.

-first 3

### Q5: Weapons Per Tier for MVP
Implement all weapons or subset?
- **All weapons**: 2 per tier = 8 weapons for 4 tiers
- **One per tier**: 4 weapons total, simpler
- **Staggered**: 1 weapon tiers 1-2, 2 weapons tiers 3-4

**[Assumed: One per tier initially]** — Slingshot, Bow, Ballista, Cannon.

a:staggered 

### Q6: Enemy Types for MVP
Which enemies to include?
- **Basic only**: Zombie, Skeleton, Slime (3 types)
- **Basic + advanced**: Add Spider, Iron Golem (5 types)
- **Full roster**: All 6 mob types + 2 bosses

**[Assumed: Basic only + Wave 10 boss]** — Core loop first.

a:basic only

### Q7: Endless Mode
Include endless mode in MVP?
- **Yes**: After wave 20, continue with scaling difficulty
- **No**: Game ends at wave 20 (win state)

**[Assumed: No]** — Post-MVP feature, focus on 20-wave experience first.

a:no

## Technical

### Q8: Scene Structure
How to organize Godot scenes?
- **Single scene**: Everything in main.tscn
- **Modular**: Separate scenes for Tower, Enemy, Projectile, UI

**[Assumed: Modular]** — Standard Godot practice, easier testing.

a:modular

### Q9: Grid Implementation
Use Godot's GridMap or custom grid?
- **GridMap**: Built-in 3D tile system
- **Custom**: Array-based grid with manual placement

**[Assumed: GridMap]** — Per spec recommendation, faster development.

a:yes

### Q10: Pathfinding
Use NavigationServer3D or pre-defined waypoints?
- **NavigationServer3D**: Dynamic pathfinding
- **Waypoints**: Predefined path points enemies follow

**[Assumed: Waypoints]** — Simpler for pre-defined paths, less overhead.

a:yes

### Q11: Asset Source
Create custom or use existing?
- **Kenney only**: Use Kenney Voxel Pack as-is
- **Kenney + custom**: Supplement with MagicaVoxel models
- **All custom**: Create everything in MagicaVoxel

**[Assumed: Kenney + custom]** — Kenney for base, custom for unique towers/enemies.

a:yes

### Q12: Audio
Priority for MVP?
- **Essential**: Shoot sounds, hit sounds, UI clicks
- **Full**: Music, ambient, all sound effects
- **None**: Silent MVP, audio post-MVP

**[Assumed: Essential]** — Minimum viable feedback.

a:essential

### Q13: Persistence
Save/load game state?
- **None**: Game resets on refresh
- **Session**: Save during active game (pause/resume)
- **Full**: Save progress, unlock towers, etc.

**[Assumed: None]** — MVP plays in one session.

a:full

## UI/UX

### Q14: Tower Selection Flow
How do players place towers?
- **Toolbar click**: Click tower in bar → click grid tile
- **Drag-drop**: Drag tower from bar to grid
- **Quick-keys**: 1-6 keys select tower type

**[Assumed: Toolbar click + quick-keys]** — Standard TD controls.

a:touchscreen through browser on ipad, drag/drop or touch/place

### Q15: Upgrade Flow
How do players upgrade tower tiers?
- **Click tower → popup menu**: Shows available upgrades
- **Auto-upgrade button**: One-click upgrade to next tier
- **Upgrade all button**: Mass upgrade visible towers

**[Assumed: Click tower → popup]** — Standard approach.

a:standard

### Q16: Tower Info
Show tower stats?
- **Minimal**: Just cost in toolbar
- **Hover tooltip**: Range, damage, fire rate
- **Side panel**: Detailed stats when selected

**[Assumed: Hover tooltip]** — Informative without cluttering.

a:hover tooltip

## Balance

### Q17: Starting Gold
How much gold to start?
- **Low (100-200)**: Careful early placement
- **Medium (400-600)**: Place 2-4 towers initially
- **High (800-1000)**: Experiment freely early

**[Assumed: 500]** — Per image, medium start.

a:medium

### Q18: Wave Count
Total waves for MVP?
- **10 waves**: Quick testing, rapid iteration
- **20 waves**: Full experience per spec
- **30+ waves**: Extended gameplay

**[Assumed: 20]** — Per spec.

a: yes

### Q19: Difficulty Scaling
How do waves increase difficulty?
- **More enemies**: Same types, higher count
- **Tougher enemies**: Same count, higher HP
- **Mixed**: Both + new enemy types introduced

**[Assumed: Mixed]** — Standard TD progression.

a:mixed

---

## How to Answer

Reply with answers like:
```
Q1: Pre-defined (correct)
Q2: Multiple, 2 spawn points from opposite corners
Q4: Start with 3 tiers, add more post-MVP
Q12: Silent MVP, audio post-MVP
...
```

I'll update the planmaps based on your answers.

