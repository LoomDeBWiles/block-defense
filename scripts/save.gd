## Persistent save data manager
## Autoload as "Save"
extends Node

signal tier_unlocked(tier: Types.MaterialTier)
signal progress_saved

const SAVE_KEY := "block_defense_save"
const CURRENT_VERSION := 1

var unlocked_tiers: Array[int] = [1]  # Tier 1 always unlocked
var highest_wave: int = 0
var total_gold_earned: int = 0
var games_played: int = 0
var games_won: int = 0
var towers_built: int = 0


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not OS.has_feature("web"):
		return

	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return

	var storage := window.localStorage
	if storage == null:
		return

	var json_str: String = storage.getItem(SAVE_KEY)
	if json_str.is_empty():
		return

	var data: Variant = JSON.parse_string(json_str)
	if data == null or not data is Dictionary:
		push_warning("Corrupted save data, using defaults")
		return

	_apply_save_data(data)


func _apply_save_data(data: Dictionary) -> void:
	data = _migrate_save_data(data)

	unlocked_tiers = Array(data.get("unlocked_tiers", [1]), TYPE_INT, "", null)
	highest_wave = data.get("highest_wave", 0)
	total_gold_earned = data.get("total_gold_earned", 0)
	games_played = data.get("games_played", 0)
	games_won = data.get("games_won", 0)
	towers_built = data.get("towers_built", 0)


func _migrate_save_data(data: Dictionary) -> Dictionary:
	var version: int = data.get("version", 0)

	# Apply migrations sequentially
	if version < 1:
		data = _migrate_v0_to_v1(data)

	return data


func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	# Version 0: Pre-versioned saves, add defaults for any missing fields
	data["version"] = 1
	if not data.has("unlocked_tiers"):
		data["unlocked_tiers"] = [1]
	if not data.has("highest_wave"):
		data["highest_wave"] = 0
	if not data.has("total_gold_earned"):
		data["total_gold_earned"] = 0
	if not data.has("games_played"):
		data["games_played"] = 0
	if not data.has("games_won"):
		data["games_won"] = 0
	if not data.has("towers_built"):
		data["towers_built"] = 0
	return data


func save_progress() -> void:
	if not OS.has_feature("web"):
		return

	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return

	var storage := window.localStorage
	if storage == null:
		return

	var data := {
		"version": CURRENT_VERSION,
		"unlocked_tiers": unlocked_tiers,
		"highest_wave": highest_wave,
		"total_gold_earned": total_gold_earned,
		"games_played": games_played,
		"games_won": games_won,
		"towers_built": towers_built,
	}

	storage.setItem(SAVE_KEY, JSON.stringify(data))
	progress_saved.emit()


func is_tier_unlocked(tier: Types.MaterialTier) -> bool:
	return tier in unlocked_tiers


func unlock_tier(tier: Types.MaterialTier) -> void:
	if tier not in unlocked_tiers:
		unlocked_tiers.append(tier)
		save_progress()
		tier_unlocked.emit(tier)


func record_game_end(won: bool, wave: int, gold: int, towers: int) -> void:
	games_played += 1
	if won:
		games_won += 1
	highest_wave = max(highest_wave, wave)
	total_gold_earned += gold
	towers_built += towers
	save_progress()


func reset_save() -> void:
	unlocked_tiers = [1]
	highest_wave = 0
	total_gold_earned = 0
	games_played = 0
	games_won = 0
	towers_built = 0

	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		if window != null:
			var storage := window.localStorage
			if storage != null:
				storage.removeItem(SAVE_KEY)
