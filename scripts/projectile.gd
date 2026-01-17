## Projectile fired by tower toward enemy
class_name Projectile
extends Node3D

var target: Enemy = null
var damage: int = 10
var speed: float = 10.0
var aoe_radius: float = 0.0  # 0 = single target
var weapon_type: Types.WeaponType = Types.WeaponType.SLINGSHOT
var damage_type: Types.DamageType = Types.DamageType.PIERCING
var hazards_container: Node = null

# Explosive weapons bypass armor
const EXPLOSIVE_WEAPONS := [
	Types.WeaponType.CATAPULT,
	Types.WeaponType.TREBUCHET,
	Types.WeaponType.CANNON,
	Types.WeaponType.EXPLODING_SHELLS,
	Types.WeaponType.ARTILLERY,
	Types.WeaponType.GRENADE_LAUNCHER,
	Types.WeaponType.BAZOOKA,
	Types.WeaponType.MISSILE,
	Types.WeaponType.NUCLEAR_BOMB,
]


static func get_damage_type(weapon: Types.WeaponType) -> Types.DamageType:
	if weapon in EXPLOSIVE_WEAPONS:
		return Types.DamageType.EXPLOSIVE
	return Types.DamageType.PIERCING


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var target_pos := target.global_position
	global_position = global_position.move_toward(target_pos, speed * delta)

	if global_position.distance_to(target_pos) < 0.2:
		_hit()


func _spawn_nuke_visual() -> void:
	if hazards_container == null:
		return

	# Screen-wide flash effect using a large sphere
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 50.0  # Large enough to cover visible area
	sphere.height = 100.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5, 0.8)  # Bright yellow-white
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.3)
	mat.emission_energy_multiplier = 5.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	flash.mesh = sphere
	flash.material_override = mat

	flash.global_position = global_position
	hazards_container.add_child(flash)

	# Fade out the flash
	var tween := flash.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)


func _hit() -> void:
	if weapon_type == Types.WeaponType.NUCLEAR_BOMB:
		# Screen-clearing ultimate - damage ALL enemies
		_spawn_nuke_visual()
		for enemy in GameState.enemies:
			if is_instance_valid(enemy):
				enemy.take_damage(damage, damage_type)
	elif aoe_radius > 0.0:
		# AoE damage
		var targets := Enemy.get_enemies_in_radius(global_position, aoe_radius)
		for enemy in targets:
			enemy.take_damage(damage, damage_type)
	elif is_instance_valid(target):
		# Single target damage
		target.take_damage(damage, damage_type)

	# Exploding Shells leaves burning ground
	if weapon_type == Types.WeaponType.EXPLODING_SHELLS and hazards_container != null:
		BurningGround.spawn(global_position, hazards_container, 5, 0.5, 3.0, aoe_radius)

	queue_free()
