## Upgrade popup - shown when tower is tapped
class_name UpgradePopup
extends Control

signal upgrade_requested(tower: Tower)
signal tier3_upgrade_requested(tower: Tower)
signal popup_closed

const TIER_NAMES := {
	Types.MaterialTier.WOOD: "Wood",
	Types.MaterialTier.SCRAP_WOOD: "Scrap Wood",
	Types.MaterialTier.SOLID_METAL: "Solid Metal",
}

const NEXT_TIER := {
	Types.MaterialTier.WOOD: Types.MaterialTier.SCRAP_WOOD,
	Types.MaterialTier.SCRAP_WOOD: Types.MaterialTier.SOLID_METAL,
}

var _current_tower: Tower = null
var _panel: PanelContainer
var _info_label: Label
var _upgrade_button: Button
var _close_button: Button
var _camera: Camera3D = null


func _ready() -> void:
	_create_ui()
	# Enable input processing for escape key
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Close on Escape key
	if event.is_action_pressed("ui_cancel"):
		hide_popup()
		get_viewport().set_input_as_handled()
		return

	# Close on click outside popup
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			var local_pos := get_local_mouse_position()
			var rect := Rect2(Vector2.ZERO, size)
			if not rect.has_point(local_pos):
				hide_popup()
				get_viewport().set_input_as_handled()


func _create_ui() -> void:
	custom_minimum_size = Vector2(200, 100)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_info_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons)

	_upgrade_button = Button.new()
	_upgrade_button.custom_minimum_size = Vector2(80, 35)
	_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	buttons.add_child(_upgrade_button)

	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(35, 35)
	_close_button.pressed.connect(_on_cancel_button_pressed)
	buttons.add_child(_close_button)


func show_for_tower(tower: Tower) -> void:
	_current_tower = tower
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
	_refresh_display()
	_position_above_tower()
	visible = true


func hide_popup() -> void:
	_current_tower = null
	visible = false
	popup_closed.emit()


func _refresh_display() -> void:
	if _current_tower == null:
		return

	var cost := _current_tower.get_upgrade_cost()
	var is_max_tier := cost < 0

	var next_tier = NEXT_TIER.get(_current_tower.material_tier)
	if is_max_tier or next_tier == null:
		_info_label.text = "MAX LEVEL"
		_upgrade_button.text = "---"
		_upgrade_button.disabled = true
	else:
		var next_name: String = TIER_NAMES.get(next_tier, "?")
		_info_label.text = "%s - %d🪙" % [next_name, cost]
		_upgrade_button.text = "Upgrade"
		_upgrade_button.disabled = not _current_tower.can_upgrade()


func _position_above_tower() -> void:
	if _current_tower == null or _camera == null:
		return

	var tower_pos := _current_tower.global_position + Vector3(0, 1.5, 0)
	var screen_pos := _camera.unproject_position(tower_pos)

	# Center on tower position
	var pos := screen_pos - custom_minimum_size / 2

	# Clamp to viewport bounds
	var viewport_size := get_viewport().get_visible_rect().size
	pos.x = clampf(pos.x, 0, viewport_size.x - custom_minimum_size.x)
	pos.y = clampf(pos.y, 0, viewport_size.y - custom_minimum_size.y)

	position = pos


func _on_upgrade_button_pressed() -> void:
	if _current_tower == null:
		return

	if _current_tower.material_tier == Types.MaterialTier.SCRAP_WOOD:
		tier3_upgrade_requested.emit(_current_tower)
		hide_popup()
	else:
		upgrade_requested.emit(_current_tower)
		hide_popup()


func _on_cancel_button_pressed() -> void:
	hide_popup()
