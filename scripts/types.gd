## Shared type definitions for Block Defense
class_name Types
extends RefCounted

enum GamePhase { BUILD, COMBAT }
enum MaterialTier { WOOD = 1, SCRAP_WOOD = 2, SOLID_METAL = 3 }
enum WeaponType { SLINGSHOT, BOW, BALLISTA, TREBUCHET }
enum EnemyType { ZOMBIE, SKELETON, SLIME, TANK_BOSS }
enum TileType { GRASS, PATH, CASTLE, BLOCKED, OCCUPIED }
