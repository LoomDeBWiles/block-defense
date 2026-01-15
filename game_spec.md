# GAME SPECIFICATION: BLOCK DEFENSE

## 1. Game Overview
**Title:** Block Defense
**Genre:** 3D Isometric Tower Defense (Web/Browser based .io style)
**Visual Style:** Voxel-based, low-poly aesthetic (MagicaVoxel style). Bright, cheerful colors.
**Objective:** Defend a central "Castle Core" from incoming waves of blocky enemies by constructing and upgrading defensive towers along pre-defined paths.

---

## 2. Core Gameplay Loop
1.  **Build:** Place base "Wooden Floor" towers on the grid.
2.  **Defend:** Towers automatically attack enemies traveling along the path.
3.  **Earn:** Killing enemies grants Gold.
4.  **Upgrade:** Spend Gold to upgrade the **Material Tier** of the floor. Higher tiers improve durability and unlock heavy weaponry.
5.  **Win:** Survive 20 Waves (or endless mode).

---

## 3. The Tower System (Material Tiers)

**Core Mechanic:** You do not buy weapons directly. You upgrade the **Floor Material**. The material determines which weapons can be mounted.

**Modified Progression:**
* *Change:* Copper is now Tier 4 (Lower), Iron Plates is now Tier 5 (Higher).

| Tier | Material Name | Visual Description | Weapon Unlocks |
| :--- | :--- | :--- | :--- |
| **1** | **Wood** | Basic oak planks. | **Slingshot:** Low dmg, cheap.<br>**Spears:** Short range, pierce 1 enemy. |
| **2** | **Scrap Wood** | Wood reinforced with rusty nails/wire. | **Bow & Arrow:** Faster fire rate.<br>**Catapult:** Small splash damage. |
| **3** | **Solid Metal** | Wood fully encased in a metal band. | **Ballista:** High single-target dmg.<br>**Trebuchet:** Massive AoE, very slow. |
| **4** | **Copper** | Polished orange/brown metal blocks. | **Cannon:** Standard explosive round.<br>**Exploding Shells:** Leaves burning ground effect. |
| **5** | **Iron Plates** | Heavy, dark grey riveted plates. | **Artillery:** Extreme range mortar.<br>**Machine Gun:** Rapid fire, low dmg/shot. |
| **6** | **Steel** | Shiny, clean silver metal. | **Grenade Launcher:** Bouncing explosives.<br>**Bazooka:** High dmg, slow projectile. |
| **7** | **Diamond** | Translucent light blue blocks. | **Missiles:** Homing projectiles (no miss).<br>**Railgun:** Instant-hit beam line damage. |
| **8** | **Obsidian** | Deep purple/black, glowing edges. | **Laser:** Continuous melting beam.<br>**Nuclear Bomb:** Screen-clearing ultimate. |

---

## 4. Mob List (Enemies)

### Basic Mobs
* **Green Zombie:** Standard health/speed.
* **Skeleton:** Fast, low health.
* **Slime Cluster:** Splits into smaller slimes on death.

### Advanced Mobs
* **Iron Golem:** High armor (resists machine gun/arrows). Needs explosives.
* **Spider:** Fast, jumps over corners of the track.
* **Enderman:** Teleports forward when hit, dodging shots.

### Bosses
* **Wave 10 Boss:** The Tank (Massive HP, slow).
* **Wave 20 Boss:** Nether Dragon (Flying, spawns minions, high HP).

---

## 5. Recommended Tech Stack & Repositories
*Goal: Shortest development time to high-quality .io release.*

### A. The Engine: Godot 4.x (Recommended)
**Why:** Completely free (MIT license), lightweight, excellent WebGL 2.0 export (crucial for .io games), and has a node structure that fits grid-based games perfectly.
* **Language:** GDScript (very fast to learn, similar to Python).

### B. Essential Assets & Tools (Speed Boosters)

**1. 3D Models (Voxel Art)**
* **Tool:** [MagicaVoxel](https://ephtracy.github.io/) (Free). The industry standard for creating the "Minefun" look.
* **Asset Pack:** [Kenney "Voxel Pack"](https://www.kenney.nl/assets/voxel-pack) (CC0 Public Domain).
    * *Why:* Contains pre-made turrets, tanks, landscapes, and castle blocks. You can use these immediately without modeling anything yourself.

**2. Grid & Tower Defense Logic**
* **Repository:** [Godot Tower Defense Tutorial/Demo](https://github.com/godotengine/godot-demo-projects/tree/master/3d/tower_defense) (Official Godot Demo).
    * *Why:* Provides the base code for path following, turret look-at logic, and spawning waves.
* **GridMap:** Use Godot's built-in `GridMap` node. It is specifically designed to paint 3D tiles (like Minecraft blocks) directly into the level editor.

**3. Pathfinding (Enemy Movement)**
* **Built-in:** Godot `NavigationServer3D`.
    * *Implementation:* Bake a "NavigationMesh" onto your dirt paths. Enemies will automatically calculate the shortest route to the castle, even if you change the map layout.

**4. UI & Polish**
* **Library:** [Godot-UI-Sound-System](https://github.com/NathanLovato/godot-ui-sound-system).
    * *Why:* Pre-built sounds for clicking, upgrading, and hovering.
* **Tweening:** Godot built-in `create_tween()`.
    * *Use for:* The "bouncy" animation when a tower is placed or upgrades (scale up from 0 to 1 with an elastic bounce). This is key to the "Minefun" feel.

### C. Development Roadmap (MVP)
1.  **Day 1:** Download Godot. Import Kenney Voxel assets. Set up a `GridMap` with Grass and Dirt tiles.
2.  **Day 2:** Implement `NavigationServer3D` on the Dirt tiles. Create a simple Enemy Cube that follows the path.
3.  **Day 3:** Create the "Tower Base" script. Implement `look_at()` logic so it tracks the Enemy Cube.
4.  **Day 4:** Implement the "Upgrade" UI. Clicking a tower replaces the mesh with the next Tier mesh and changes the projectile scene.
5.  **Day 5:** Add the Wave Spawner logic and Health/Gold variables.