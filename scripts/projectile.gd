## Projectile fired by tower toward enemy
class_name Projectile
extends Node3D

var target: Enemy = null
var damage: int = 10
var speed: float = 10.0
var aoe_radius: float = 0.0  # 0 = single target

var _enemies_container: Node = null


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var target_pos := target.global_position
	global_position = global_position.move_toward(target_pos, speed * delta)

	if global_position.distance_to(target_pos) < 0.2:
		_hit()


func _hit() -> void:
	if aoe_radius > 0.0 and _enemies_container != null:
		# AoE damage
		var targets := Enemy.get_enemies_in_radius(_enemies_container, global_position, aoe_radius)
		for enemy in targets:
			enemy.take_damage(damage)
	elif is_instance_valid(target):
		# Single target damage
		target.take_damage(damage)

	queue_free()
