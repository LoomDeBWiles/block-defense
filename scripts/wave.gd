## Manages wave spawning, progression, and win/lose conditions
class_name WaveManager
extends Node

signal wave_started(wave: int)
signal wave_complete(wave: int)
signal game_over
signal victory
signal spawn_activated(spawn_id: int)
signal endless_started

var _grid: Grid = null
var _enemies_container: Node = null
var _spawning: bool = false
var _enemies_remaining: int = 0
var _endless_mode: bool = false

# Spawn point progression by wave range
const SPAWN_PROGRESSION := {
	5: [0],           # Waves 1-5: West only
	12: [0, 1],       # Waves 6-12: West + East
	20: [0, 1, 2],    # Waves 13-20: West + East + North
}

# Spawn intervals by wave range
const SPAWN_INTERVALS := {
	5: 1.5,
	10: 1.2,
	15: 1.0,
	20: 0.8,
}

# Wave definitions: { spawn_id: [{ type: EnemyType, count: int }, ...] }
const WAVE_DATA := {
	1: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 5 }] },
	2: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 8 }] },
	3: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 6 }, { "type": Types.EnemyType.SKELETON, "count": 3 }] },
	4: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 8 }, { "type": Types.EnemyType.SKELETON, "count": 4 }] },
	5: { 0: [{ "type": Types.EnemyType.SLIME, "count": 4 }, { "type": Types.EnemyType.SKELETON, "count": 4 }] },
	6: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 6 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 1 }], 1: [{ "type": Types.EnemyType.ZOMBIE, "count": 4 }] },
	7: { 0: [{ "type": Types.EnemyType.SKELETON, "count": 5 }], 1: [{ "type": Types.EnemyType.ZOMBIE, "count": 5 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 1 }] },
	8: { 0: [{ "type": Types.EnemyType.SLIME, "count": 4 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 2 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 2 }, { "type": Types.EnemyType.SLIME, "count": 4 }] },
	9: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 6 }, { "type": Types.EnemyType.SKELETON, "count": 4 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 3 }, { "type": Types.EnemyType.ZOMBIE, "count": 6 }] },
	10: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 8 }, { "type": Types.EnemyType.TANK_BOSS, "count": 1 }], 1: [{ "type": Types.EnemyType.ZOMBIE, "count": 6 }, { "type": Types.EnemyType.SKELETON, "count": 4 }] },
	# Waves 11-20 follow similar patterns with increasing difficulty
	11: { 0: [{ "type": Types.EnemyType.SKELETON, "count": 8 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 2 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 2 }, { "type": Types.EnemyType.SLIME, "count": 5 }] },
	12: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 10 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 3 }, { "type": Types.EnemyType.SKELETON, "count": 8 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 2 }] },
	13: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 6 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 1 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 2 }, { "type": Types.EnemyType.ZOMBIE, "count": 6 }], 2: [{ "type": Types.EnemyType.ZOMBIE, "count": 4 }] },
	14: { 0: [{ "type": Types.EnemyType.SKELETON, "count": 6 }], 1: [{ "type": Types.EnemyType.SLIME, "count": 4 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 2 }], 2: [{ "type": Types.EnemyType.ENDERMAN, "count": 3 }, { "type": Types.EnemyType.ZOMBIE, "count": 6 }] },
	15: { 0: [{ "type": Types.EnemyType.SLIME, "count": 6 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 4 }, { "type": Types.EnemyType.SKELETON, "count": 6 }], 2: [{ "type": Types.EnemyType.SKELETON, "count": 4 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 2 }] },
	16: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 10 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 3 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 3 }, { "type": Types.EnemyType.ZOMBIE, "count": 10 }], 2: [{ "type": Types.EnemyType.SLIME, "count": 5 }] },
	17: { 0: [{ "type": Types.EnemyType.SKELETON, "count": 10 }], 1: [{ "type": Types.EnemyType.SLIME, "count": 6 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 3 }], 2: [{ "type": Types.EnemyType.ENDERMAN, "count": 4 }, { "type": Types.EnemyType.ZOMBIE, "count": 8 }] },
	18: { 0: [{ "type": Types.EnemyType.ENDERMAN, "count": 5 }, { "type": Types.EnemyType.SLIME, "count": 8 }], 1: [{ "type": Types.EnemyType.SKELETON, "count": 10 }], 2: [{ "type": Types.EnemyType.SKELETON, "count": 6 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 3 }] },
	19: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 12 }, { "type": Types.EnemyType.SLIME, "count": 4 }, { "type": Types.EnemyType.IRON_GOLEM, "count": 2 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 5 }, { "type": Types.EnemyType.SKELETON, "count": 10 }], 2: [{ "type": Types.EnemyType.SLIME, "count": 6 }] },
	20: { 0: [{ "type": Types.EnemyType.ZOMBIE, "count": 15 }, { "type": Types.EnemyType.SLIME, "count": 6 }], 1: [{ "type": Types.EnemyType.ENDERMAN, "count": 6 }, { "type": Types.EnemyType.SKELETON, "count": 12 }, { "type": Types.EnemyType.SLIME, "count": 4 }], 2: [{ "type": Types.EnemyType.ZOMBIE, "count": 10 }, { "type": Types.EnemyType.NETHER_DRAGON, "count": 1 }] },
}

# Unlock triggers: wave cleared -> tier unlocked
const UNLOCK_TRIGGERS := {
	2: Types.MaterialTier.SCRAP_WOOD,
	4: Types.MaterialTier.SOLID_METAL,
	7: Types.MaterialTier.COPPER,
	10: Types.MaterialTier.IRON_PLATES,
	13: Types.MaterialTier.STEEL,
	16: Types.MaterialTier.DIAMOND,
	19: Types.MaterialTier.OBSIDIAN,
}


class SpawnEntry:
	var enemy_type: Types.EnemyType
	var count: int

	func _init(type: Types.EnemyType, cnt: int) -> void:
		enemy_type = type
		count = cnt


class SpawnGroup:
	var spawn_point: int
	var enemies: Array[SpawnEntry]

	func _init(point: int) -> void:
		spawn_point = point
		enemies = []


class WaveData:
	var spawns: Array[SpawnGroup]
	var spawn_interval: float

	func _init() -> void:
		spawns = []
		spawn_interval = 0.0


func get_wave_data(wave: int) -> WaveData:
	var data := WaveData.new()
	if wave < 1:
		return data

	# For endless mode (wave > 20), generate scaled waves
	if wave > 20:
		return _generate_endless_wave_data(wave)

	data.spawn_interval = _get_spawn_interval_for_wave(wave)
	var wave_def: Dictionary = WAVE_DATA.get(wave, {})

	for spawn_id: int in wave_def.keys():
		var group := SpawnGroup.new(spawn_id)
		var entries: Array = wave_def[spawn_id]
		for entry: Dictionary in entries:
			var enemy_type: Types.EnemyType = entry.get("type", Types.EnemyType.ZOMBIE)
			var count: int = entry.get("count", 0)
			group.enemies.append(SpawnEntry.new(enemy_type, count))
		data.spawns.append(group)

	return data


func _generate_endless_wave_data(wave: int) -> WaveData:
	var data := WaveData.new()
	# Spawn interval continues to decrease slightly in endless mode
	data.spawn_interval = max(0.4, 0.8 - (wave - 20) * 0.02)

	# Scale based on waves past 20
	var waves_past_20 := wave - 20
	var scale_factor := 1.0 + waves_past_20 * 0.15  # 15% more enemies per wave

	# Base enemy counts that scale with waves
	var base_zombie := int(10 * scale_factor)
	var base_skeleton := int(8 * scale_factor)
	var base_slime := int(4 * scale_factor)
	var base_iron_golem := int(2 + waves_past_20 / 3)
	var base_enderman := int(3 + waves_past_20 / 2)

	# All 3 spawn points active in endless
	for spawn_id in [0, 1, 2]:
		var group := SpawnGroup.new(spawn_id)

		# Mix of enemy types per spawn
		match spawn_id:
			0:
				group.enemies.append(SpawnEntry.new(Types.EnemyType.ZOMBIE, base_zombie))
				group.enemies.append(SpawnEntry.new(Types.EnemyType.IRON_GOLEM, base_iron_golem))
			1:
				group.enemies.append(SpawnEntry.new(Types.EnemyType.SKELETON, base_skeleton))
				group.enemies.append(SpawnEntry.new(Types.EnemyType.ENDERMAN, base_enderman))
			2:
				group.enemies.append(SpawnEntry.new(Types.EnemyType.SLIME, base_slime))
				group.enemies.append(SpawnEntry.new(Types.EnemyType.ZOMBIE, base_zombie / 2))

		# Add bosses every 5 waves in endless
		if waves_past_20 > 0 and waves_past_20 % 5 == 0 and spawn_id == 2:
			if waves_past_20 % 10 == 0:
				group.enemies.append(SpawnEntry.new(Types.EnemyType.NETHER_DRAGON, 1))
			else:
				group.enemies.append(SpawnEntry.new(Types.EnemyType.TANK_BOSS, 1))

		data.spawns.append(group)

	return data


func _get_spawn_interval_for_wave(wave: int) -> float:
	for max_wave in SPAWN_INTERVALS.keys():
		if wave <= max_wave:
			return SPAWN_INTERVALS[max_wave]
	return 0.8


func setup(grid: Grid, enemies_container: Node) -> void:
	_grid = grid
	_enemies_container = enemies_container


func start_wave() -> void:
	if GameState.phase == Types.GamePhase.COMBAT:
		return

	GameState.set_phase(Types.GamePhase.COMBAT)
	wave_started.emit(GameState.wave)

	# Check if new spawn point activated
	var prev_spawns := get_active_spawns(GameState.wave - 1)
	var curr_spawns := get_active_spawns(GameState.wave)
	for spawn_id in curr_spawns:
		if spawn_id not in prev_spawns:
			spawn_activated.emit(spawn_id)

	_spawn_wave()


func _spawn_wave() -> void:
	_spawning = true
	var current_wave := GameState.wave
	var interval: float

	_enemies_remaining = 0

	# Use generated wave data for endless mode
	if current_wave > 20:
		var endless_data := _generate_endless_wave_data(current_wave)
		interval = endless_data.spawn_interval

		# Count and spawn from generated data
		for spawn_group in endless_data.spawns:
			for entry in spawn_group.enemies:
				_enemies_remaining += entry.count

		for spawn_group in endless_data.spawns:
			var waypoints := _grid.get_path_waypoints(spawn_group.spawn_point)
			for entry in spawn_group.enemies:
				for i in range(entry.count):
					_spawn_enemy(entry.enemy_type, waypoints)
					await get_tree().create_timer(interval).timeout
	else:
		# Standard waves 1-20
		var wave_data: Dictionary = WAVE_DATA.get(current_wave, {})
		interval = _get_spawn_interval()
		var active_spawns := get_active_spawns(current_wave)

		# Count total enemies
		for spawn_id in active_spawns:
			var spawn_groups: Array = wave_data.get(spawn_id, [])
			for group in spawn_groups:
				_enemies_remaining += group.get("count", 0)

		# Spawn enemies with interval
		for spawn_id in active_spawns:
			var spawn_groups: Array = wave_data.get(spawn_id, [])
			var waypoints := _grid.get_path_waypoints(spawn_id)

			for group in spawn_groups:
				var enemy_type: Types.EnemyType = group.get("type", Types.EnemyType.ZOMBIE)
				var count: int = group.get("count", 1)

				for i in range(count):
					_spawn_enemy(enemy_type, waypoints)
					await get_tree().create_timer(interval).timeout

	_spawning = false


func _spawn_enemy(enemy_type: Types.EnemyType, waypoints: Array[Vector3]) -> void:
	if _enemies_container == null:
		return

	var enemy := Enemy.spawn_enemy(enemy_type, waypoints, _enemies_container)
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.reached_castle.connect(_on_enemy_reached_castle)
	enemy.mini_slime_spawned.connect(_on_mini_slime_spawned)
	enemy.minion_spawned.connect(_on_minion_spawned)


func _on_enemy_died(_enemy: Enemy) -> void:
	# Defer check since queue_free() is also deferred - enemy still in tree this frame
	call_deferred("_check_wave_complete")


func _on_mini_slime_spawned(mini: Enemy) -> void:
	mini.enemy_died.connect(_on_enemy_died)
	mini.reached_castle.connect(_on_enemy_reached_castle)
	mini.mini_slime_spawned.connect(_on_mini_slime_spawned)


func _on_minion_spawned(minion: Enemy) -> void:
	minion.enemy_died.connect(_on_enemy_died)
	minion.reached_castle.connect(_on_enemy_reached_castle)


func _on_enemy_reached_castle(damage: int) -> void:
	GameState.damage_castle(damage)
	if GameState.castle_hp <= 0:
		Save.record_game_end(false, GameState.wave, GameState.gold, GameState.towers.size())
		game_over.emit()
		return
	# Defer check since queue_free() is also deferred - enemy still in tree this frame
	call_deferred("_check_wave_complete")


func _check_wave_complete() -> void:
	if _spawning:
		return

	if is_instance_valid(_enemies_container) and _enemies_container.get_child_count() == 0:
		_complete_wave()


func _complete_wave() -> void:
	# Check for tier unlock
	var unlock_tier: Variant = UNLOCK_TRIGGERS.get(GameState.wave, null)
	if unlock_tier != null:
		Save.unlock_tier(unlock_tier)

	if GameState.wave >= 20 and not _endless_mode:
		Save.record_game_end(true, GameState.wave, GameState.gold, GameState.towers.size())
		victory.emit()
		return

	GameState.advance_wave()
	GameState.set_phase(Types.GamePhase.BUILD)
	wave_complete.emit(GameState.wave)


func start_endless_mode() -> void:
	_endless_mode = true
	endless_started.emit()
	GameState.advance_wave()
	GameState.set_phase(Types.GamePhase.BUILD)


func is_endless_mode() -> bool:
	return _endless_mode


func _get_spawn_interval() -> float:
	for max_wave in SPAWN_INTERVALS.keys():
		if GameState.wave <= max_wave:
			return SPAWN_INTERVALS[max_wave]
	return 0.8


func get_active_spawns(wave: int) -> Array[int]:
	var thresholds := SPAWN_PROGRESSION.keys()
	thresholds.sort()
	for max_wave: int in thresholds:
		if wave <= max_wave:
			var result: Array[int] = []
			result.assign(SPAWN_PROGRESSION[max_wave])
			return result
	return [0, 1, 2]


func is_wave_complete() -> bool:
	return not _spawning and _enemies_container and _enemies_container.get_child_count() == 0
