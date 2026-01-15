## Enemy entity - follows waypoints, takes damage, reaches castle
class_name Enemy
extends Node3D

signal enemy_died(enemy: Enemy)
signal reached_castle(damage: int)
signal mini_slime_spawned(mini: Enemy)

@export var enemy_type: Types.EnemyType = Types.EnemyType.ZOMBIE

var is_mini: bool = false  # Mini-slimes don't split further
var hp: int = 30
var max_hp: int = 30
var speed: float = 1.0
var gold_value: int = 10
var damage_to_castle: int = 10

var waypoints: Array[Vector3] = []
var path_index: int = 0

# Stats by enemy type
const ENEMY_STATS := {
	Types.EnemyType.ZOMBIE: { "hp": 30, "speed": 1.0, "gold": 10, "castle_dmg": 10 },
	Types.EnemyType.SKELETON: { "hp": 20, "speed": 1.5, "gold": 8, "castle_dmg": 5 },
	Types.EnemyType.SLIME: { "hp": 50, "speed": 0.8, "gold": 15, "castle_dmg": 15 },
	Types.EnemyType.TANK_BOSS: { "hp": 500, "speed": 0.5, "gold": 200, "castle_dmg": 50 },
}


func _ready() -> void:
	_apply_stats()
	if waypoints.size() > 0:
		global_position = waypoints[0]


func _apply_stats() -> void:
	var stats: Dictionary = ENEMY_STATS.get(enemy_type, ENEMY_STATS[Types.EnemyType.ZOMBIE])
	hp = stats.hp
	max_hp = stats.hp
	speed = stats.speed
	gold_value = stats.gold
	damage_to_castle = stats.castle_dmg


func _physics_process(delta: float) -> void:
	if path_index >= waypoints.size():
		_reached_castle()
		return

	var target_pos := waypoints[path_index]
	global_position = global_position.move_toward(target_pos, speed * delta)

	if global_position.distance_to(target_pos) < 0.1:
		path_index += 1


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		die()


func die() -> void:
	GameState.add_gold(gold_value)

	# Slime split mechanic (mini-slimes don't split further)
	if enemy_type == Types.EnemyType.SLIME and not is_mini:
		_spawn_mini_slimes()

	enemy_died.emit(self)
	queue_free()


func _spawn_mini_slimes() -> void:
	# Spawn 2 mini-slimes at death position
	# Mini-slimes have reduced stats and inherit remaining waypoints
	var remaining_waypoints := waypoints.slice(path_index)
	for i in range(2):
		var mini := Enemy.new()
		mini.enemy_type = Types.EnemyType.SLIME
		mini.is_mini = true
		mini.hp = 15  # 30% of parent
		mini.max_hp = 15
		mini.speed = 1.2  # 150% of parent
		mini.gold_value = 5
		mini.damage_to_castle = 5
		mini.waypoints = remaining_waypoints.duplicate()
		mini.path_index = 0
		mini.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
		get_parent().add_child(mini)
		mini_slime_spawned.emit(mini)


func _reached_castle() -> void:
	GameState.damage_castle(damage_to_castle)
	reached_castle.emit(damage_to_castle)
	queue_free()


## Static helper to get enemies in radius (for AoE)
static func get_enemies_in_radius(enemies_container: Node, pos: Vector3, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child in enemies_container.get_children():
		if child is Enemy:
			if child.global_position.distance_to(pos) <= radius:
				result.append(child)
	return result
