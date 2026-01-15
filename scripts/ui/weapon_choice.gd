## Weapon choice popup - shown when upgrading to tier 3
class_name WeaponChoicePopup
extends Control

signal weapon_chosen(tower: Tower, weapon: Types.WeaponType)
signal popup_closed

var _current_tower: Tower = null


func show_for_tower(tower: Tower) -> void:
	_current_tower = tower
	visible = true


func hide_popup() -> void:
	_current_tower = null
	visible = false
	popup_closed.emit()


func _on_ballista_button_pressed() -> void:
	if _current_tower:
		weapon_chosen.emit(_current_tower, Types.WeaponType.BALLISTA)
	hide_popup()


func _on_trebuchet_button_pressed() -> void:
	if _current_tower:
		weapon_chosen.emit(_current_tower, Types.WeaponType.TREBUCHET)
	hide_popup()
