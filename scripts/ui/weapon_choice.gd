## Weapon choice popup - shown when upgrading to tier 3
class_name WeaponChoicePopup
extends Control

signal weapon_chosen(tower: Tower, weapon: Types.WeaponType)
signal popup_closed

const WEAPON_ICONS := {
	Types.WeaponType.BALLISTA: "🏹",
	Types.WeaponType.TREBUCHET: "💥",
}

const WEAPON_NAMES := {
	Types.WeaponType.BALLISTA: "Ballista",
	Types.WeaponType.TREBUCHET: "Trebuchet",
}

var _current_tower: Tower = null
var _buttons_container: HBoxContainer
var _weapon_buttons: Dictionary = {}


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(400, 180)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Choose Weapon"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	_buttons_container = HBoxContainer.new()
	_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons_container.add_theme_constant_override("separation", 20)
	vbox.add_child(_buttons_container)


func show_for_tower(tower: Tower) -> void:
	_current_tower = tower
	_populate_weapon_choices()
	visible = true


func _populate_weapon_choices() -> void:
	# Clear existing buttons
	for child in _buttons_container.get_children():
		child.queue_free()
	_weapon_buttons.clear()

	var choices := Tower.get_weapon_choices(Types.MaterialTier.SOLID_METAL)
	for weapon in choices:
		var button := _create_weapon_button(weapon)
		_buttons_container.add_child(button)
		_weapon_buttons[weapon] = button


func _create_weapon_button(weapon: Types.WeaponType) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 80)

	var icon := WEAPON_ICONS.get(weapon, "?")
	var name := WEAPON_NAMES.get(weapon, "Unknown")
	var stats: Dictionary = Tower.WEAPON_STATS.get(weapon, {})

	# Key stat: Ballista = damage, Trebuchet = AoE
	var key_stat: String
	if weapon == Types.WeaponType.BALLISTA:
		key_stat = "DMG: %d" % stats.get("damage", 0)
	else:
		key_stat = "AoE: %.1f" % stats.get("aoe", 0.0)

	button.text = "%s\n%s\n%s" % [icon, name, key_stat]
	button.pressed.connect(_on_weapon_button_pressed.bind(weapon))
	return button


func _on_weapon_button_pressed(weapon: Types.WeaponType) -> void:
	if _current_tower:
		weapon_chosen.emit(_current_tower, weapon)
	hide_popup()


func hide_popup() -> void:
	_current_tower = null
	visible = false
	popup_closed.emit()
