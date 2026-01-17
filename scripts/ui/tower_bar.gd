## Tower selection bar - click to select, then click to place
class_name TowerBar
extends Control

signal tower_selected(tier: Types.MaterialTier)
signal tower_deselected
signal tower_placed(grid_pos: Vector2i)
signal placement_cancelled

const TIER_NAMES := {
	Types.MaterialTier.WOOD: "Wood",
	Types.MaterialTier.SCRAP_WOOD: "Scrap",
	Types.MaterialTier.SOLID_METAL: "Metal",
}

const TIER_WEAPONS := {
	Types.MaterialTier.WOOD: Types.WeaponType.SLINGSHOT,
	Types.MaterialTier.SCRAP_WOOD: Types.WeaponType.BOW,
	Types.MaterialTier.SOLID_METAL: Types.WeaponType.BALLISTA,
}

const WEAPON_NAMES := {
	Types.WeaponType.SLINGSHOT: "Slingshot",
	Types.WeaponType.BOW: "Bow",
	Types.WeaponType.BALLISTA: "Ballista",
	Types.WeaponType.TREBUCHET: "Trebuchet",
}

const SLOT_SIZE := Vector2(80, 60)
const SELECTED_COLOR := Color(0.3, 0.7, 0.3, 1.0)
const NORMAL_COLOR := Color(0.3, 0.3, 0.3, 1.0)
const GHOST_VALID_COLOR := Color(0.3, 0.5, 0.9, 0.5)  # Semi-transparent blue
const GHOST_INVALID_COLOR := Color(0.9, 0.3, 0.3, 0.5)  # Semi-transparent red

var _slots: Dictionary = {}  # MaterialTier -> Button
var _selected_tier: Types.MaterialTier = Types.MaterialTier.WOOD
var _is_placement_mode: bool = false
var _camera: Camera3D = null
var _grid: Grid = null
var _confirmation_popup: Control = null
var _pending_grid_pos: Vector2i = Vector2i.ZERO
var _ghost_tower: MeshInstance3D = null
var _ghost_material: StandardMaterial3D = null


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	if _camera == null:
		get_tree().process_frame.connect(_try_acquire_camera, CONNECT_ONE_SHOT)
	_create_slots()
	_create_confirmation_popup()
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
		slot.text = TIER_NAMES.get(tier, "?") + "\n%d🪙" % Tower.PLACEMENT_COST
		slot.set_meta("tier", tier)
		slot.pressed.connect(_on_slot_clicked.bind(tier))
		add_child(slot)
		_slots[tier] = slot


func _create_confirmation_popup() -> void:
	_confirmation_popup = PanelContainer.new()
	_confirmation_popup.visible = false
	_confirmation_popup.custom_minimum_size = Vector2(180, 100)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_confirmation_popup.add_child(vbox)

	var label := Label.new()
	label.text = "Place Tower?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 15)
	vbox.add_child(buttons)

	var confirm_btn := Button.new()
	confirm_btn.text = "Place"
	confirm_btn.custom_minimum_size = Vector2(70, 35)
	confirm_btn.pressed.connect(_on_confirm_placement)
	buttons.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(70, 35)
	cancel_btn.pressed.connect(_on_cancel_placement)
	buttons.add_child(cancel_btn)

	# Add to HUD (parent of BottomBar, which is parent of TowerBar)
	# TowerBar is at UI/HUD/BottomBar/TowerBar, so go up to HUD
	# Use call_deferred to avoid "parent node is busy" error
	var hud := get_parent().get_parent()  # BottomBar -> HUD
	if hud:
		hud.add_child.call_deferred(_confirmation_popup)
	else:
		# Fallback: add to self and position will be relative
		add_child.call_deferred(_confirmation_popup)


func _process(_delta: float) -> void:
	if not _is_placement_mode:
		return
	_update_ghost_position()


func _create_ghost_tower() -> void:
	if _ghost_tower != null:
		return

	_ghost_tower = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 1.0, 0.8)  # Same size as tower
	_ghost_tower.mesh = box

	_ghost_material = StandardMaterial3D.new()
	_ghost_material.albedo_color = GHOST_VALID_COLOR
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_tower.material_override = _ghost_material

	# Position at center of mesh (tower base is at y=0, mesh center at y=0.5)
	_ghost_tower.position.y = 0.5

	# Add to World node so it renders in 3D space
	var world := get_tree().root.get_node_or_null("Main/World")
	if world:
		world.add_child(_ghost_tower)


func _remove_ghost_tower() -> void:
	if _ghost_tower != null and is_instance_valid(_ghost_tower):
		_ghost_tower.queue_free()
	_ghost_tower = null
	_ghost_material = null


func _update_ghost_position() -> void:
	if _ghost_tower == null or _camera == null:
		return

	var screen_pos := get_viewport().get_mouse_position()

	# Don't show ghost when mouse is over UI
	if _is_click_on_ui(screen_pos):
		_ghost_tower.visible = false
		return

	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)

	# Find intersection with y=0 plane (grid level)
	if abs(dir.y) > 0.001:
		var t := -from.y / dir.y
		if t > 0:
			var world_pos := from + dir * t
			var grid_pos := Vector2i(int(floor(world_pos.x)), int(floor(world_pos.z)))

			# Snap to grid center
			_ghost_tower.position.x = grid_pos.x + 0.5
			_ghost_tower.position.z = grid_pos.y + 0.5
			_ghost_tower.visible = true

			# Update color based on validity
			var is_valid := _grid != null and _grid.can_place(grid_pos)
			_ghost_material.albedo_color = GHOST_VALID_COLOR if is_valid else GHOST_INVALID_COLOR
		else:
			_ghost_tower.visible = false
	else:
		_ghost_tower.visible = false


func _refresh_slots() -> void:
	var can_afford := GameState.gold >= Tower.PLACEMENT_COST
	for tier: Types.MaterialTier in _slots:
		var slot: Button = _slots[tier]
		var unlocked := Save.is_tier_unlocked(tier)
		slot.visible = unlocked
		slot.disabled = not can_afford

		# Highlight selected slot
		if _is_placement_mode and tier == _selected_tier:
			slot.add_theme_color_override("font_color", SELECTED_COLOR)
			slot.add_theme_stylebox_override("normal", _create_selected_style())
		else:
			slot.remove_theme_color_override("font_color")
			slot.remove_theme_stylebox_override("normal")


func _create_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	style.border_color = Color(0.4, 0.9, 0.4, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	return style


func _on_tier_unlocked(_tier: Types.MaterialTier) -> void:
	_refresh_slots()


func _on_gold_changed(_amount: int) -> void:
	_refresh_slots()


func _on_slot_clicked(tier: Types.MaterialTier) -> void:
	if _is_placement_mode and tier == _selected_tier:
		# Clicking same button deselects
		exit_placement_mode()
	else:
		# Enter placement mode for this tier
		enter_placement_mode(tier)


func enter_placement_mode(tier: Types.MaterialTier) -> void:
	if not Save.is_tier_unlocked(tier):
		return
	if GameState.gold < Tower.PLACEMENT_COST:
		return

	_selected_tier = tier
	_is_placement_mode = true
	_refresh_slots()

	# Get grid reference and highlight valid tiles
	_grid = _get_grid()
	if _grid:
		_grid.highlight_placeable_tiles(true)

	_create_ghost_tower()
	tower_selected.emit(tier)


func exit_placement_mode() -> void:
	_is_placement_mode = false
	_hide_confirmation_popup()
	_refresh_slots()
	_remove_ghost_tower()

	if _grid:
		_grid.highlight_placeable_tiles(false)

	tower_deselected.emit()


func _get_grid() -> Grid:
	var world := get_tree().root.get_node_or_null("Main/World")
	if world:
		return world.get_node_or_null("Grid")
	return null


func _input(event: InputEvent) -> void:
	if not _is_placement_mode:
		return

	# Escape cancels placement mode
	if event.is_action_pressed("ui_cancel"):
		exit_placement_mode()
		get_viewport().set_input_as_handled()
		return

	# Handle clicks on the game world
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			var screen_pos: Vector2
			if event is InputEventMouseButton:
				if event.button_index != MOUSE_BUTTON_LEFT:
					return
				screen_pos = event.position
			else:
				screen_pos = event.position

			# Don't handle if clicking on UI
			if _is_click_on_ui(screen_pos):
				return

			_handle_placement_click(screen_pos)
			get_viewport().set_input_as_handled()


func _is_click_on_ui(screen_pos: Vector2) -> bool:
	# Check if click is on confirmation popup
	if _confirmation_popup and _confirmation_popup.visible:
		var popup_rect := Rect2(_confirmation_popup.position, _confirmation_popup.size)
		if popup_rect.has_point(screen_pos):
			return true
	# Check if click is on bottom bar area (where buttons are)
	var viewport_size := get_viewport().get_visible_rect().size
	return screen_pos.y > viewport_size.y - 100


func _handle_placement_click(screen_pos: Vector2) -> void:
	if _camera == null:
		return

	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)

	# Find intersection with y=0 plane (grid level)
	if abs(dir.y) > 0.001:
		var t := -from.y / dir.y
		if t > 0:
			var world_pos := from + dir * t
			var grid_pos := Vector2i(int(floor(world_pos.x)), int(floor(world_pos.z)))

			# Check if valid placement
			if _grid and _grid.can_place(grid_pos):
				_pending_grid_pos = grid_pos
				_show_confirmation_popup(screen_pos)
			else:
				# Invalid tile - show feedback or do nothing
				pass


func _show_confirmation_popup(screen_pos: Vector2) -> void:
	if _confirmation_popup == null:
		return

	# Position popup near click but clamped to viewport
	var viewport_size := get_viewport().get_visible_rect().size
	var popup_size := _confirmation_popup.custom_minimum_size
	var pos := screen_pos - popup_size / 2
	pos.x = clampf(pos.x, 10, viewport_size.x - popup_size.x - 10)
	pos.y = clampf(pos.y, 10, viewport_size.y - popup_size.y - 10)

	_confirmation_popup.position = pos
	_confirmation_popup.visible = true


func _hide_confirmation_popup() -> void:
	if _confirmation_popup:
		_confirmation_popup.visible = false


func _on_confirm_placement() -> void:
	_hide_confirmation_popup()

	var world := get_tree().root.get_node_or_null("Main/World")
	if world == null:
		return

	var grid: Grid = world.get_node_or_null("Grid")
	var towers := world.get_node_or_null("Towers")
	var enemies := world.get_node_or_null("Enemies")
	var projectiles := world.get_node_or_null("Projectiles")

	if grid == null or towers == null or enemies == null or projectiles == null:
		return

	var tower := Tower.spawn_tower(_pending_grid_pos, grid, towers, enemies, projectiles)
	if tower:
		tower_placed.emit(_pending_grid_pos)
		# Refresh highlights since tile is now occupied
		if _grid:
			_grid.highlight_placeable_tiles(true)
		# Refresh slot states (gold may have changed)
		_refresh_slots()
		# Check if we can still afford more towers
		if GameState.gold < Tower.PLACEMENT_COST:
			exit_placement_mode()


func _on_cancel_placement() -> void:
	_hide_confirmation_popup()
	# Stay in placement mode so user can try another tile
