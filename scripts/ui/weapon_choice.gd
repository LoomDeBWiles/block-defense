## Weapon choice popup - shown when upgrading to tier 3
class_name WeaponChoicePopup
extends Control

signal weapon_chosen(tower: Tower, weapon: Types.WeaponType)
signal popup_closed

const WEAPON_ICONS := {
	# Tier 1 - Wood
	Types.WeaponType.SLINGSHOT: "🎯",
	Types.WeaponType.SPEAR: "🗡️",
	# Tier 2 - Scrap Wood
	Types.WeaponType.BOW: "🏹",
	Types.WeaponType.CATAPULT: "🪨",
	# Tier 3 - Solid Metal
	Types.WeaponType.BALLISTA: "⚔️",
	Types.WeaponType.TREBUCHET: "💥",
	# Tier 4 - Copper
	Types.WeaponType.CANNON: "💣",
	Types.WeaponType.EXPLODING_SHELLS: "🔥",
	# Tier 5 - Iron Plates
	Types.WeaponType.ARTILLERY: "🎆",
	Types.WeaponType.MACHINE_GUN: "🔫",
	# Tier 6 - Steel
	Types.WeaponType.GRENADE_LAUNCHER: "💣",
	Types.WeaponType.BAZOOKA: "🚀",
	# Tier 7 - Diamond
	Types.WeaponType.MISSILE: "🚀",
	Types.WeaponType.RAILGUN: "⚡",
	# Tier 8 - Obsidian
	Types.WeaponType.LASER: "✨",
	Types.WeaponType.NUCLEAR_BOMB: "☢️",
}

const WEAPON_NAMES := {
	# Tier 1 - Wood
	Types.WeaponType.SLINGSHOT: "Slingshot",
	Types.WeaponType.SPEAR: "Spear",
	# Tier 2 - Scrap Wood
	Types.WeaponType.BOW: "Bow",
	Types.WeaponType.CATAPULT: "Catapult",
	# Tier 3 - Solid Metal
	Types.WeaponType.BALLISTA: "Ballista",
	Types.WeaponType.TREBUCHET: "Trebuchet",
	# Tier 4 - Copper
	Types.WeaponType.CANNON: "Cannon",
	Types.WeaponType.EXPLODING_SHELLS: "Exploding Shells",
	# Tier 5 - Iron Plates
	Types.WeaponType.ARTILLERY: "Artillery",
	Types.WeaponType.MACHINE_GUN: "Machine Gun",
	# Tier 6 - Steel
	Types.WeaponType.GRENADE_LAUNCHER: "Grenade Launcher",
	Types.WeaponType.BAZOOKA: "Bazooka",
	# Tier 7 - Diamond
	Types.WeaponType.MISSILE: "Missile",
	Types.WeaponType.RAILGUN: "Railgun",
	# Tier 8 - Obsidian
	Types.WeaponType.LASER: "Laser",
	Types.WeaponType.NUCLEAR_BOMB: "Nuclear Bomb",
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

	if _current_tower == null:
		return

	# Get the NEXT tier's weapon choices (since we're upgrading)
	var next_tier := _current_tower.material_tier + 1
	if next_tier > Types.MaterialTier.OBSIDIAN:
		return

	var choices := Tower.get_weapon_choices(next_tier)
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

	# Show key stat: AoE weapons show AoE, others show damage
	var key_stat: String
	var aoe: float = stats.get("aoe", 0.0)
	if aoe > 0.0:
		key_stat = "AoE: %.1f" % aoe
	else:
		key_stat = "DMG: %d" % stats.get("damage", 0)

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
