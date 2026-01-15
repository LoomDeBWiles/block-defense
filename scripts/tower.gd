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
	Types.WeaponType.SLINGSHOT: { "damage": 10, "range": 3.0, "fire_rate": 1.0, "aoe": 0.0 },
	Types.WeaponType.BOW: { "damage": 15, "range": 4.0, "fire_rate": 1.5, "aoe": 0.0 },
	Types.WeaponType.BALLISTA: { "damage": 40, "range": 5.0, "fire_rate": 0.5, "aoe": 0.0 },
	Types.WeaponType.TREBUCHET: { "damage": 25, "range": 6.0, "fire_rate": 0.3, "aoe": 2.0 },
}

# Upgrade costs
const UPGRADE_COSTS := {
	Types.MaterialTier.WOOD: 75,  # Wood -> Scrap Wood
	Types.MaterialTier.SCRAP_WOOD: 150,  # Scrap Wood -> Solid Metal
}

const PLACEMENT_COST := 50
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const TOWER_SCENE := preload("res://scenes/tower.tscn")


func _ready() -> void:
	_apply_weapon_stats()


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


## Upgrade tower from tier 1 to tier 2 (WOOD -> SCRAP_WOOD)
## Returns true if upgrade succeeded
func upgrade() -> bool:
	if material_tier != Types.MaterialTier.WOOD:
		return false  # Only works for tier 1

	var cost := UPGRADE_COSTS.get(material_tier, -1)
	if cost < 0:
		return false

	if not GameState.spend_gold(cost):
		return false

	material_tier = Types.MaterialTier.SCRAP_WOOD
	weapon = Types.WeaponType.BOW
	_apply_weapon_stats()
	return true


## Upgrade tower from tier 2 to tier 3 (SCRAP_WOOD -> SOLID_METAL) with weapon choice
## Returns true if upgrade succeeded
func upgrade_with_weapon(chosen_weapon: Types.WeaponType) -> bool:
	if material_tier != Types.MaterialTier.SCRAP_WOOD:
		return false  # Only works for tier 2

	if chosen_weapon not in [Types.WeaponType.BALLISTA, Types.WeaponType.TREBUCHET]:
		return false  # Invalid weapon for tier 3

	var cost := UPGRADE_COSTS.get(material_tier, -1)
	if cost < 0:
		return false

	if not GameState.spend_gold(cost):
		return false

	material_tier = Types.MaterialTier.SOLID_METAL
	weapon = chosen_weapon
	_apply_weapon_stats()
	return true


func get_upgrade_cost() -> int:
	return UPGRADE_COSTS.get(material_tier, -1)


func can_upgrade() -> bool:
	var cost := get_upgrade_cost()
	return cost > 0 and GameState.gold >= cost


static func get_weapon_choices(tier: Types.MaterialTier) -> Array[Types.WeaponType]:
	if tier == Types.MaterialTier.SOLID_METAL:
		return [Types.WeaponType.BALLISTA, Types.WeaponType.TREBUCHET]
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
