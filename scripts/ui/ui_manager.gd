## Main UI controller - manages HUD, popups, and game state display
class_name UIManager
extends CanvasLayer

var dragging_tier: Types.MaterialTier = Types.MaterialTier.WOOD
var is_dragging: bool = false
var selected_tower: Tower = null

@onready var gold_label: Label = $HUD/GoldLabel
@onready var wave_label: Label = $HUD/WaveLabel
@onready var castle_hp_label: Label = $HUD/CastleHPLabel
@onready var start_button: Button = $HUD/StartButton
@onready var _wave_manager: WaveManager = $"../World/WaveManager"


func _ready() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.castle_damaged.connect(_on_castle_damaged)
	GameState.phase_changed.connect(_on_phase_changed)

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

	_update_displays()


func _update_displays() -> void:
	update_gold(GameState.gold)
	update_wave(GameState.wave)
	update_castle_hp(GameState.castle_hp)


func update_gold(amount: int) -> void:
	if gold_label:
		gold_label.text = "🪙 " + str(amount)


func update_wave(wave: int) -> void:
	if wave_label:
		wave_label.text = "WAVE %d/20" % wave


func update_castle_hp(hp: int) -> void:
	if castle_hp_label:
		castle_hp_label.text = str(hp)


func _on_gold_changed(amount: int) -> void:
	update_gold(amount)


func _on_wave_changed(wave: int) -> void:
	update_wave(wave)


func _on_castle_damaged(hp: int) -> void:
	update_castle_hp(hp)


func _on_phase_changed(phase: Types.GamePhase) -> void:
	if start_button:
		if phase == Types.GamePhase.BUILD:
			start_button.visible = true
			start_button.text = "START WAVE"
		else:
			start_button.visible = false


func _on_start_button_pressed() -> void:
	if _wave_manager:
		_wave_manager.start_wave()


func show_game_over() -> void:
	# TODO: Show game over screen
	pass


func show_victory() -> void:
	# TODO: Show victory screen with stats
	pass
