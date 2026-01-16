## Tower entity - targets enemies, fires projectiles, upgradeable
class_name Tower
extends Node3D

@export var grid_pos: Vector2i = Vector2i.ZERO
@export var material_tier: Types.MaterialTier = Types.MaterialTier.WOOD
@export var weapon: Types.WeaponType = Types.WeaponType.SLINGSHOT

var target: Enemy = null
var fire_cooldown: float = 0.0

# Derived stats
var damage: int = 10
var range_radius: float = 3.0
var fire_rate: float = 1.0
var aoe_radius: float = 0.0

var _enemies_container: Node = null
var _projectiles_container: Node = null

# Weapon stats: damage, range, fire_rate (shots/s), aoe_radius
const WEAPON_STATS := {
	# Tier 1 - Wood
	Types.WeaponType.SLINGSHOT: { "damage": 10, "range": 3.0, "fire_rate": 1.0, "aoe": 0.0 },
	Types.WeaponType.SPEAR: { "damage": 12, "range": 2.5, "fire_rate": 0.8, "aoe": 0.0 },
	# Tier 2 - Scrap Wood
	Types.WeaponType.BOW: { "damage": 15, "range": 4.0, "fire_rate": 1.5, "aoe": 0.0 },
	Types.WeaponType.CATAPULT: { "damage": 20, "range": 5.0, "fire_rate": 0.7, "aoe": 1.0 },
	# Tier 3 - Solid Metal
	Types.WeaponType.BALLISTA: { "damage": 40, "range": 5.0, "fire_rate": 0.5, "aoe": 0.0 },
	Types.WeaponType.TREBUCHET: { "damage": 25, "range": 6.0, "fire_rate": 0.3, "aoe": 2.0 },
	# Tier 4 - Copper
	Types.WeaponType.CANNON: { "damage": 50, "range": 6.0, "fire_rate": 0.6, "aoe": 1.5 },
	Types.WeaponType.EXPLODING_SHELLS: { "damage": 35, "range": 5.5, "fire_rate": 0.8, "aoe": 2.0 },
	# Tier 5 - Iron Plates
	Types.WeaponType.ARTILLERY: { "damage": 70, "range": 8.0, "fire_rate": 0.4, "aoe": 2.5 },
	Types.WeaponType.MACHINE_GUN: { "damage": 8, "range": 4.5, "fire_rate": 5.0, "aoe": 0.0 },
	# Tier 6 - Steel
	Types.WeaponType.GRENADE_LAUNCHER: { "damage": 55, "range": 6.5, "fire_rate": 1.0, "aoe": 2.0 },
	Types.WeaponType.BAZOOKA: { "damage": 90, "range": 7.0, "fire_rate": 0.4, "aoe": 1.5 },
	# Tier 7 - Diamond
	Types.WeaponType.MISSILE: { "damage": 80, "range": 9.0, "fire_rate": 0.7, "aoe": 1.8 },
	Types.WeaponType.RAILGUN: { "damage": 120, "range": 10.0, "fire_rate": 0.3, "aoe": 0.0 },
	# Tier 8 - Obsidian
	Types.WeaponType.LASER: { "damage": 100, "range": 8.0, "fire_rate": 2.0, "aoe": 0.0 },
	Types.WeaponType.NUCLEAR_BOMB: { "damage": 500, "range": 7.0, "fire_rate": 0.1, "aoe": 5.0 },
}

# Upgrade costs
const UPGRADE_COSTS := {
	Types.MaterialTier.WOOD: 75,  # Wood -> Scrap Wood
	Types.MaterialTier.SCRAP_WOOD: 150,  # Scrap Wood -> Solid Metal
	Types.MaterialTier.SOLID_METAL: 250,  # Solid Metal -> Copper
	Types.MaterialTier.COPPER: 400,  # Copper -> Iron Plates
	Types.MaterialTier.IRON_PLATES: 600,  # Iron Plates -> Steel
	Types.MaterialTier.STEEL: 900,  # Steel -> Diamond
	Types.MaterialTier.DIAMOND: 1500,  # Diamond -> Obsidian
}

const PLACEMENT_COST := 50
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const TOWER_SCENE := preload("res://scenes/tower.tscn")


func _ready() -> void:
	_apply_weapon_stats()
	GameState.register_tower(self)


func _exit_tree() -> void:
	GameState.unregister_tower(self)


func _apply_weapon_stats() -> void:
	var stats: Dictionary = WEAPON_STATS.get(weapon, WEAPON_STATS[Types.WeaponType.SLINGSHOT])
	damage = stats.damage
	range_radius = stats.range
	fire_rate = stats.fire_rate
	aoe_radius = stats.aoe


func _physics_process(delta: float) -> void:
	if GameState.phase != Types.GamePhase.COMBAT:
		return

	fire_cooldown = max(0.0, fire_cooldown - delta)

	if target == null or not is_instance_valid(target):
		_find_target()
	elif global_position.distance_to(target.global_position) > range_radius:
		target = null
		_find_target()

	if target != null and is_instance_valid(target):
		_rotate_toward_target()
		if fire_cooldown <= 0.0:
			_fire()


func _find_target() -> void:
	target = null
	if _enemies_container == null:
		return

	var nearest_dist := INF
	for child in _enemies_container.get_children():
		if not is_instance_valid(child):
			continue
		if child is Enemy:
			var dist := global_position.distance_to(child.global_position)
			if dist <= range_radius and dist < nearest_dist:
				nearest_dist = dist
				target = child


func _rotate_toward_target() -> void:
	if target == null:
		return
	var look_pos := target.global_position
	look_pos.y = global_position.y  # Only rotate on Y axis
	look_at(look_pos, Vector3.UP)


func _fire() -> void:
	if target == null or _projectiles_container == null:
		return

	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.target = target
	projectile.damage = damage
	projectile.aoe_radius = aoe_radius
	_projectiles_container.add_child(projectile)
	projectile.global_position = global_position

	fire_cooldown = 1.0 / fire_rate


## Upgrade tower to next tier
## Returns true if upgrade succeeded
func upgrade() -> bool:
	# Tier 1 (Wood) auto-upgrades to Tier 2 (Scrap Wood) with Bow
	if material_tier == Types.MaterialTier.WOOD:
		var cost: int = UPGRADE_COSTS.get(material_tier, -1)
		if cost < 0 or not GameState.spend_gold(cost):
			return false
		material_tier = Types.MaterialTier.SCRAP_WOOD
		weapon = Types.WeaponType.BOW
		_apply_weapon_stats()
		return true

	# All other tiers require weapon choice via upgrade_with_weapon
	return false


## Upgrade tower to next tier with weapon choice
## Returns true if upgrade succeeded
func upgrade_with_weapon(chosen_weapon: Types.WeaponType) -> bool:
	var cost: int = UPGRADE_COSTS.get(material_tier, -1)
	if cost < 0:
		return false

	if not GameState.spend_gold(cost):
		return false

	# Validate weapon choice for each tier
	var valid_weapons := get_weapon_choices(material_tier)
	if valid_weapons.is_empty() or chosen_weapon not in valid_weapons:
		return false

	# Upgrade to next tier
	var next_tier := material_tier + 1
	if next_tier > Types.MaterialTier.OBSIDIAN:
		return false

	material_tier = next_tier
	weapon = chosen_weapon
	_apply_weapon_stats()
	return true


func get_upgrade_cost() -> int:
	return UPGRADE_COSTS.get(material_tier, -1)


func can_upgrade() -> bool:
	var cost := get_upgrade_cost()
	return cost > 0 and GameState.gold >= cost


static func get_weapon_choices(tier: Types.MaterialTier) -> Array[Types.WeaponType]:
	match tier:
		Types.MaterialTier.WOOD:
			return [Types.WeaponType.SLINGSHOT, Types.WeaponType.SPEAR]
		Types.MaterialTier.SCRAP_WOOD:
			return [Types.WeaponType.BOW, Types.WeaponType.CATAPULT]
		Types.MaterialTier.SOLID_METAL:
			return [Types.WeaponType.BALLISTA, Types.WeaponType.TREBUCHET]
		Types.MaterialTier.COPPER:
			return [Types.WeaponType.CANNON, Types.WeaponType.EXPLODING_SHELLS]
		Types.MaterialTier.IRON_PLATES:
			return [Types.WeaponType.ARTILLERY, Types.WeaponType.MACHINE_GUN]
		Types.MaterialTier.STEEL:
			return [Types.WeaponType.GRENADE_LAUNCHER, Types.WeaponType.BAZOOKA]
		Types.MaterialTier.DIAMOND:
			return [Types.WeaponType.MISSILE, Types.WeaponType.RAILGUN]
		Types.MaterialTier.OBSIDIAN:
			return [Types.WeaponType.LASER, Types.WeaponType.NUCLEAR_BOMB]
	return []


## Spawn a tower at the given grid position
## Returns the tower instance, or null if placement invalid or cannot afford
static func spawn_tower(grid_pos: Vector2i, grid: Grid, towers_container: Node, enemies_container: Node, projectiles_container: Node) -> Tower:
	if not grid.can_place(grid_pos):
		return null

	if not GameState.spend_gold(PLACEMENT_COST):
		return null

	var tower: Tower = TOWER_SCENE.instantiate()
	tower.grid_pos = grid_pos
	tower.material_tier = Types.MaterialTier.WOOD
	tower.weapon = Types.WeaponType.SLINGSHOT
	tower._enemies_container = enemies_container
	tower._projectiles_container = projectiles_container

	tower.global_position = grid.grid_to_world(grid_pos)
	towers_container.add_child(tower)
	grid.mark_occupied(grid_pos)

	return tower
