## Burning ground hazard - deals damage over time to enemies passing through
class_name BurningGround
extends Node3D

var damage_per_tick: int = 5
var tick_interval: float = 0.5
var duration: float = 3.0
var radius: float = 2.0

var _elapsed: float = 0.0
var _tick_timer: float = 0.0

const BURNING_GROUND_SCENE := preload("res://scenes/burning_ground.tscn")


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return

	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_deal_damage()


func _deal_damage() -> void:
	var targets := Enemy.get_enemies_in_radius(global_position, radius)
	for enemy in targets:
		enemy.take_damage(damage_per_tick, Types.DamageType.EXPLOSIVE)


## Spawn burning ground at position
static func spawn(pos: Vector3, container: Node, dmg: int = 5, tick: float = 0.5, dur: float = 3.0, rad: float = 2.0) -> BurningGround:
	var burning: BurningGround = BURNING_GROUND_SCENE.instantiate()
	burning.damage_per_tick = dmg
	burning.tick_interval = tick
	burning.duration = dur
	burning.radius = rad
	container.add_child(burning)
	burning.global_position = pos
	return burning
