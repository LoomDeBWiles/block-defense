## Tower selection bar - drag to place towers
class_name TowerBar
extends Control

signal tower_drag_started(tier: Types.MaterialTier)
signal tower_drag_ended(grid_pos: Vector2i)
signal tower_drag_cancelled

const TIER_NAMES := {
	Types.MaterialTier.WOOD: "Wood",
	Types.MaterialTier.SCRAP_WOOD: "Scrap",
	Types.MaterialTier.SOLID_METAL: "Metal",
}

const TIER_WEAPONS := {
	Types.MaterialTier.WOOD: Types.WeaponType.SLINGSHOT,
	Types.MaterialTier.SCRAP_WOOD: Types.WeaponType.BOW,
	Types.MaterialTier.SOLID_METAL: Types.WeaponType.BALLISTA,  # Default for Metal slot
}

const WEAPON_NAMES := {
	Types.WeaponType.SLINGSHOT: "Slingshot",
	Types.WeaponType.BOW: "Bow",
	Types.WeaponType.BALLISTA: "Ballista",
	Types.WeaponType.TREBUCHET: "Trebuchet",
}

const SLOT_SIZE := Vector2(64, 64)
const LONG_PRESS_DURATION := 0.5

var _slots: Dictionary = {}  # MaterialTier -> Button
var _dragging_tier: Types.MaterialTier = Types.MaterialTier.WOOD
var _is_dragging: bool = false
var _ghost: Node3D = null
var _camera: Camera3D = null

# Long-press tooltip state
var _press_timer: Timer = null
var _pressed_tier: Types.MaterialTier = Types.MaterialTier.WOOD
var _is_long_pressing: bool = false
var _tooltip: Label = null


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	if _camera == null:
		# Camera may not exist yet during _ready - defer acquisition
		get_tree().process_frame.connect(_try_acquire_camera, CONNECT_ONE_SHOT)
	_create_slots()
	_create_tooltip()
	_create_press_timer()
	_refresh_slots()
	Save.tier_unlocked.connect(_on_tier_unlocked)
	GameState.gold_changed.connect(_on_gold_changed)


func _try_acquire_camera() -> void:
	if _camera == null:
		_camera = get_viewport().get_camera_3d()


func _create_slots() -> void:
	for tier_value in [1, 2, 3]:
		var tier: Types.MaterialTier = tier_value as Types.MaterialTier
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.text = TIER_NAMES.get(tier, "?")
		slot.set_meta("tier", tier)
		slot.button_down.connect(_on_slot_pressed.bind(tier))
		slot.button_up.connect(_on_slot_released.bind(tier))
		add_child(slot)
		_slots[tier] = slot


func _create_tooltip() -> void:
	_tooltip = Label.new()
	_tooltip.visible = false
	_tooltip.add_theme_color_override("font_color", Color.WHITE)
	_tooltip.add_theme_color_override("font_outline_color", Color.BLACK)
	_tooltip.add_theme_constant_override("outline_size", 2)
	add_child(_tooltip)


func _create_press_timer() -> void:
	_press_timer = Timer.new()
	_press_timer.one_shot = true
	_press_timer.wait_time = LONG_PRESS_DURATION
	_press_timer.timeout.connect(_on_long_press_triggered)
	add_child(_press_timer)


func _refresh_slots() -> void:
	var can_afford := GameState.gold >= Tower.PLACEMENT_COST
	for tier: Types.MaterialTier in _slots:
		var slot: Button = _slots[tier]
		var unlocked := Save.is_tier_unlocked(tier)
		slot.visible = unlocked
		slot.disabled = not can_afford


func _on_tier_unlocked(_tier: Types.MaterialTier) -> void:
	_refresh_slots()


func _on_gold_changed(_amount: int) -> void:
	_refresh_slots()


func _on_slot_pressed(tier: Types.MaterialTier) -> void:
	_pressed_tier = tier
	_press_timer.start()


func _on_slot_released(_tier: Types.MaterialTier) -> void:
	var was_long_press := _is_long_pressing
	_press_timer.stop()
	_hide_tooltip()

	if was_long_press:
		return  # Long-press = tooltip only, no drag

	start_drag(_pressed_tier)


func _on_long_press_triggered() -> void:
	_is_long_pressing = true
	_show_tooltip(_pressed_tier)


func _show_tooltip(tier: Types.MaterialTier) -> void:
	var weapon: Types.WeaponType = TIER_WEAPONS.get(tier, Types.WeaponType.SLINGSHOT)
	var stats: Dictionary = Tower.WEAPON_STATS.get(weapon, {})
	var weapon_name: String = WEAPON_NAMES.get(weapon, "?")
	var dmg: int = stats.get("damage", 0)
	var rng: float = stats.get("range", 0.0)

	_tooltip.text = "%s: %d dmg, %d range" % [weapon_name, dmg, int(rng)]
	_tooltip.visible = true

	# Position above the pressed slot
	var slot: Button = _slots.get(tier)
	if slot:
		_tooltip.position = slot.position + Vector2(0, -30)


func _hide_tooltip() -> void:
	_tooltip.visible = false
	_is_long_pressing = false


func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_update_ghost_position(event.position)
	elif event is InputEventMouseButton:
		if not event.pressed:
			_finish_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if not event.pressed:
			_finish_drag(event.position)
			get_viewport().set_input_as_handled()


func start_drag(tier: Types.MaterialTier) -> void:
	if not Save.is_tier_unlocked(tier):
		return
	if GameState.gold < Tower.PLACEMENT_COST:
		return

	_dragging_tier = tier
	_is_dragging = true
	_spawn_ghost()
	tower_drag_started.emit(tier)


func _spawn_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()

	var tower_scene: PackedScene = preload("res://scenes/tower.tscn")
	_ghost = tower_scene.instantiate()
	# Make semi-transparent
	_ghost.set_meta("is_ghost", true)
	# Add to world so it renders in 3D space
	var world := get_tree().root.get_node_or_null("Main/World")
	if world:
		world.add_child(_ghost)
	else:
		_ghost.queue_free()
		_ghost = null


func _update_ghost_position(screen_pos: Vector2) -> void:
	if _ghost == null or _camera == null:
		return

	# Project screen position to world at y=0.5 (tower height)
	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)

	# Find intersection with y=0.5 plane
	if abs(dir.y) > 0.001:
		var t := (0.5 - from.y) / dir.y
		if t > 0:
			var world_pos := from + dir * t
			_ghost.global_position = world_pos


func _finish_drag(screen_pos: Vector2) -> void:
	if not _is_dragging:
		return

	_is_dragging = false
	_remove_ghost()

	# Raycast to find grid position
	if _camera == null:
		cancel_drag()
		return

	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)

	# Find intersection with y=0 plane (grid level)
	if abs(dir.y) > 0.001:
		var t := -from.y / dir.y
		if t > 0:
			var world_pos := from + dir * t
			var grid_pos := Vector2i(roundi(world_pos.x), roundi(world_pos.z))
			end_drag(grid_pos)
			return

	cancel_drag()


func _remove_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null


func end_drag(grid_pos: Vector2i) -> void:
	var world := get_tree().root.get_node_or_null("Main/World")
	if world == null:
		tower_drag_cancelled.emit()
		return

	var grid: Grid = world.get_node_or_null("Grid")
	var towers := world.get_node_or_null("Towers")
	var enemies := world.get_node_or_null("Enemies")
	var projectiles := world.get_node_or_null("Projectiles")

	if grid == null or towers == null or enemies == null or projectiles == null:
		tower_drag_cancelled.emit()
		return

	var tower := Tower.spawn_tower(grid_pos, grid, towers, enemies, projectiles)
	if tower == null:
		tower_drag_cancelled.emit()
		return

	tower_drag_ended.emit(grid_pos)


func cancel_drag() -> void:
	_remove_ghost()
	_is_dragging = false
	tower_drag_cancelled.emit()
