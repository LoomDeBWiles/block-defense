## Tower entity - targets enemies, fires projectiles, upgradeable
class_name Tower
extends Node3D

@export var grid_pos: Vector2i = Vector2i.ZERO
@export var material_tier: Types.MaterialTier = Types.MaterialTier.WOOD
@export var weapon: Types.WeaponType = Types.WeaponType.SLINGSHOT

var target: Enemy = null
var fire_cooldown: float = 0.0

# Laser beam state
var _laser_beam_visual: MeshInstance3D = null
var _laser_beam_material: StandardMaterial3D = null

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
		_cleanup_laser_beam()
		return

	fire_cooldown = max(0.0, fire_cooldown - delta)

	if target == null or not is_instance_valid(target):
		_find_target()
	elif global_position.distance_to(target.global_position) > range_radius:
		target = null
		_find_target()

	# Handle laser beam cleanup when target lost
	if weapon == Types.WeaponType.LASER and (target == null or not is_instance_valid(target)):
		_cleanup_laser_beam()

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

	# Railgun: instant-hit beam that damages all enemies in a line
	if weapon == Types.WeaponType.RAILGUN:
		_fire_railgun()
		fire_cooldown = 1.0 / fire_rate
		return

	# Laser: continuous melting beam that damages per tick
	if weapon == Types.WeaponType.LASER:
		_fire_laser()
		fire_cooldown = 1.0 / fire_rate
		return

	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.target = target
	projectile.damage = damage
	projectile.aoe_radius = aoe_radius
	projectile.weapon_type = weapon
	projectile.damage_type = Projectile.get_damage_type(weapon)
	projectile.hazards_container = _projectiles_container
	# Grenade Launcher fires bouncing explosives (1-2 bounces)
	if weapon == Types.WeaponType.GRENADE_LAUNCHER:
		projectile.bounces_remaining = randi_range(1, 2)
	# Missiles are homing - they retarget if target dies
	if weapon == Types.WeaponType.MISSILE:
		projectile.homing = true
	_projectiles_container.add_child(projectile)
	projectile.global_position = global_position

	fire_cooldown = 1.0 / fire_rate


func _fire_railgun() -> void:
	var start := global_position
	var direction := (target.global_position - start).normalized()
	direction.y = 0  # Keep beam horizontal
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	var end := start + direction * range_radius

	# Damage all enemies along the beam line
	var hit_enemies := _get_enemies_in_line(start, end, 0.3)  # 0.3 unit radius for line
	for enemy in hit_enemies:
		enemy.take_damage(damage, Types.DamageType.PIERCING)

	# Visual beam effect
	_spawn_beam_visual(start, end)


func _get_enemies_in_line(start: Vector3, end: Vector3, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	if _enemies_container == null:
		return result

	var line_dir := (end - start).normalized()
	var line_length := start.distance_to(end)

	for child in _enemies_container.get_children():
		if not is_instance_valid(child) or not child is Enemy:
			continue
		var enemy: Enemy = child
		# Project enemy position onto the line
		var to_enemy := enemy.global_position - start
		var proj_length := to_enemy.dot(line_dir)
		# Check if projection is within line segment
		if proj_length < 0 or proj_length > line_length:
			continue
		# Get perpendicular distance from line
		var proj_point := start + line_dir * proj_length
		var dist := enemy.global_position.distance_to(proj_point)
		if dist <= radius:
			result.append(enemy)

	return result


func _spawn_beam_visual(start: Vector3, end: Vector3) -> void:
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	var length := start.distance_to(end)
	box.size = Vector3(0.1, 0.1, length)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0)  # Cyan beam
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	beam.mesh = box
	beam.material_override = mat

	# Position at midpoint, looking toward end
	var midpoint := (start + end) / 2.0
	beam.global_position = midpoint
	beam.look_at(end, Vector3.UP)

	_projectiles_container.add_child(beam)

	# Fade out and remove beam
	var tween := beam.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(beam.queue_free)


func _fire_laser() -> void:
	if target == null or not is_instance_valid(target):
		_cleanup_laser_beam()
		return

	# Deal damage tick to target
	target.take_damage(damage, Types.DamageType.EXPLOSIVE)

	# Update or create visual beam
	_update_laser_beam_visual()


func _update_laser_beam_visual() -> void:
	if target == null or not is_instance_valid(target):
		_cleanup_laser_beam()
		return

	var start := global_position
	var end := target.global_position
	var length := start.distance_to(end)

	if _laser_beam_visual == null or not is_instance_valid(_laser_beam_visual):
		# Create persistent beam visual
		_laser_beam_visual = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.15, 0.15, 1.0)  # Z will be scaled
		_laser_beam_visual.mesh = box

		_laser_beam_material = StandardMaterial3D.new()
		_laser_beam_material.albedo_color = Color(1.0, 0.3, 0.1)  # Orange-red melting beam
		_laser_beam_material.emission_enabled = true
		_laser_beam_material.emission = Color(1.0, 0.4, 0.1)
		_laser_beam_material.emission_energy_multiplier = 4.0
		_laser_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		_laser_beam_visual.material_override = _laser_beam_material
		_projectiles_container.add_child(_laser_beam_visual)

	# Update beam position and scale
	_laser_beam_visual.scale.z = length
	var midpoint := (start + end) / 2.0
	_laser_beam_visual.global_position = midpoint
	_laser_beam_visual.look_at(end, Vector3.UP)


func _cleanup_laser_beam() -> void:
	if _laser_beam_visual != null and is_instance_valid(_laser_beam_visual):
		_laser_beam_visual.queue_free()
	_laser_beam_visual = null
	_laser_beam_material = null


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

	# Validate weapon choice for the NEXT tier (we're upgrading into it)
	var next_tier := material_tier + 1
	if next_tier > Types.MaterialTier.OBSIDIAN:
		return false

	var valid_weapons := get_weapon_choices(next_tier)
	if chosen_weapon not in valid_weapons:
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

	# Bouncy placement animation: scale from 0 to 1 with elastic bounce
	tower.scale = Vector3.ZERO
	var tween := tower.create_tween()
	tween.tween_property(tower, "scale", Vector3.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	return tower
