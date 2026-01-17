## Main UI controller - manages HUD, popups, and game state display
class_name UIManager
extends CanvasLayer

var dragging_tier: Types.MaterialTier = Types.MaterialTier.WOOD
var is_dragging: bool = false
var selected_tower: Tower = null

@onready var gold_label: Label = $HUD/TopBar/GoldLabel
@onready var wave_label: Label = $HUD/TopBar/WaveLabel
@onready var castle_hp_label: Label = $HUD/TopBar/CastleHPLabel
@onready var start_button: Button = $HUD/BottomBar/StartButton
@onready var _wave_manager: WaveManager = $"../World/WaveManager"
@onready var _grid: Grid = $"../World/Grid"
@onready var _enemies_container: Node = $"../World/Enemies"
@onready var _tower_bar: TowerBar = $HUD/BottomBar/TowerBar
@onready var _towers_container: Node = $"../World/Towers"
@onready var _camera: Camera3D = $"../Camera3D"
@onready var _victory_screen: PanelContainer = $HUD/VictoryScreen
@onready var _victory_waves_label: Label = $HUD/VictoryScreen/VBox/WavesLabel
@onready var _victory_towers_label: Label = $HUD/VictoryScreen/VBox/TowersLabel
@onready var _victory_gold_label: Label = $HUD/VictoryScreen/VBox/GoldLabel
var _endless_button: Button

# Game over screen components
var _game_over_screen: PanelContainer
var _retry_button: Button

# Upgrade popup components
var _upgrade_popup: UpgradePopup
var _weapon_choice_popup: WeaponChoicePopup


func _ready() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.castle_damaged.connect(_on_castle_damaged)
	GameState.phase_changed.connect(_on_phase_changed)

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

	if _wave_manager:
		_wave_manager.setup(_grid, _enemies_container)
		_wave_manager.game_over.connect(show_game_over)
		_wave_manager.victory.connect(show_victory)
		_wave_manager.endless_started.connect(_on_endless_started)

	_create_game_over_screen()
	_create_endless_button()
	_create_upgrade_popups()
	_update_displays()


func _input(event: InputEvent) -> void:
	# Ignore input during tower placement
	if _tower_bar and _tower_bar._is_placement_mode:
		return

	# Ignore if popups are open
	if _upgrade_popup and _upgrade_popup.visible:
		return
	if _weapon_choice_popup and _weapon_choice_popup.visible:
		return

	# Handle tap/click release to select tower
	var screen_pos: Vector2 = Vector2.ZERO
	var is_release := false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			screen_pos = event.position
			is_release = true
	elif event is InputEventScreenTouch:
		if not event.pressed:
			screen_pos = event.position
			is_release = true

	if is_release:
		_try_select_tower(screen_pos)


func _try_select_tower(screen_pos: Vector2) -> void:
	if _camera == null or _towers_container == null:
		return

	var from := _camera.project_ray_origin(screen_pos)
	var to := from + _camera.project_ray_normal(screen_pos) * 1000.0

	var space_state := _camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return

	# Check if we hit a tower's ClickArea
	var collider: Variant = result.get("collider")
	if collider == null:
		return

	# ClickArea is child of Tower, so get parent
	var tower_node: Node = collider.get_parent()
	if is_instance_valid(tower_node) and tower_node is Tower:
		selected_tower = tower_node
		show_upgrade_popup(tower_node)


func _update_displays() -> void:
	update_gold(GameState.gold)
	update_wave(GameState.wave)
	update_castle_hp(GameState.castle_hp)


func update_gold(amount: int) -> void:
	if gold_label:
		gold_label.text = "🪙 " + str(amount)


func update_wave(wave: int) -> void:
	if wave_label:
		if _wave_manager and _wave_manager.is_endless_mode():
			wave_label.text = "WAVE %d (ENDLESS)" % wave
		else:
			wave_label.text = "WAVE %d/20" % wave


func update_castle_hp(hp: int) -> void:
	if castle_hp_label:
		castle_hp_label.text = "❤️ " + str(hp)


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
	get_tree().paused = true
	_game_over_screen.visible = true


func show_victory() -> void:
	get_tree().paused = true
	_victory_waves_label.text = "Waves: %d" % GameState.wave
	_victory_towers_label.text = "Towers Built: %d" % GameState.towers.size()
	_victory_gold_label.text = "Gold Earned: %d" % GameState.gold
	_victory_screen.visible = true


func _create_game_over_screen() -> void:
	_game_over_screen = PanelContainer.new()
	_game_over_screen.name = "GameOverScreen"
	_game_over_screen.visible = false
	_game_over_screen.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_screen.custom_minimum_size = Vector2(300, 200)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_game_over_screen.add_child(vbox)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	_retry_button = Button.new()
	_retry_button.text = "RETRY"
	_retry_button.custom_minimum_size = Vector2(100, 40)
	_retry_button.pressed.connect(_on_retry_pressed)
	vbox.add_child(_retry_button)

	add_child(_game_over_screen)


func _create_endless_button() -> void:
	if _victory_screen == null:
		return

	var vbox: VBoxContainer = _victory_screen.get_node_or_null("VBox")
	if vbox == null:
		return

	# Add spacer before button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Create endless mode button
	_endless_button = Button.new()
	_endless_button.name = "EndlessButton"
	_endless_button.text = "ENDLESS MODE"
	_endless_button.custom_minimum_size = Vector2(150, 40)
	_endless_button.pressed.connect(_on_endless_pressed)
	vbox.add_child(_endless_button)


func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()


func _on_endless_pressed() -> void:
	get_tree().paused = false
	_victory_screen.visible = false
	if _wave_manager:
		_wave_manager.start_endless_mode()


func _on_endless_started() -> void:
	# Wave label already updates via wave_changed signal
	pass


func _create_upgrade_popups() -> void:
	# Create upgrade popup
	_upgrade_popup = UpgradePopup.new()
	_upgrade_popup.visible = false
	_upgrade_popup.upgrade_requested.connect(_on_upgrade_requested)
	_upgrade_popup.weapon_choice_requested.connect(_on_weapon_choice_requested)
	add_child(_upgrade_popup)

	# Create weapon choice popup
	_weapon_choice_popup = WeaponChoicePopup.new()
	_weapon_choice_popup.visible = false
	_weapon_choice_popup.weapon_chosen.connect(_on_weapon_chosen)
	add_child(_weapon_choice_popup)


func show_upgrade_popup(tower: Tower) -> void:
	if _upgrade_popup:
		_upgrade_popup.show_for_tower(tower)


func _on_upgrade_requested(tower: Tower) -> void:
	tower.upgrade()


func _on_weapon_choice_requested(tower: Tower) -> void:
	if _weapon_choice_popup:
		_weapon_choice_popup.show_for_tower(tower)


func _on_weapon_chosen(tower: Tower, weapon: Types.WeaponType) -> void:
	tower.upgrade_with_weapon(weapon)
