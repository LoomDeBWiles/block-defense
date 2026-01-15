## Runtime game state singleton
## Autoload as "GameState"
extends Node

signal gold_changed(amount: int)
signal wave_changed(wave: int)
signal phase_changed(phase: Types.GamePhase)
signal castle_damaged(hp: int)

var gold: int = 500
var wave: int = 1
var phase: Types.GamePhase = Types.GamePhase.BUILD
var castle_hp: int = 100

var towers: Array[Node] = []
var enemies: Array[Enemy] = []


func register_enemy(enemy: Enemy) -> void:
	enemies.append(enemy)


func unregister_enemy(enemy: Enemy) -> void:
	enemies.erase(enemy)


func reset() -> void:
	gold = 500
	wave = 1
	phase = Types.GamePhase.BUILD
	castle_hp = 100
	towers.clear()
	enemies.clear()


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func damage_castle(amount: int) -> void:
	castle_hp = max(0, castle_hp - amount)
	castle_damaged.emit(castle_hp)


func set_phase(new_phase: Types.GamePhase) -> void:
	phase = new_phase
	phase_changed.emit(phase)


func advance_wave() -> void:
	wave += 1
	wave_changed.emit(wave)
