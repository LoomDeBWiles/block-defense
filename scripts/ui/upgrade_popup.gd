## Upgrade popup - shown when tower is tapped
class_name UpgradePopup
extends Control

signal upgrade_requested(tower: Tower)
signal popup_closed

var _current_tower: Tower = null


func show_for_tower(tower: Tower) -> void:
	_current_tower = tower
	_refresh_display()
	visible = true


func hide_popup() -> void:
	_current_tower = null
	visible = false
	popup_closed.emit()


func _refresh_display() -> void:
	if _current_tower == null:
		return

	var cost := _current_tower.get_upgrade_cost()
	# TODO: Update UI labels with tier name and cost


func _on_upgrade_button_pressed() -> void:
	if _current_tower == null:
		return

	# Check if tier 3 upgrade (needs weapon choice)
	if _current_tower.material_tier == Types.MaterialTier.SCRAP_WOOD:
		# Show weapon choice popup instead
		pass
	else:
		upgrade_requested.emit(_current_tower)

	hide_popup()


func _on_cancel_button_pressed() -> void:
	hide_popup()
