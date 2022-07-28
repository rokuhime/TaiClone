extends CanvasItem

signal hit_error_toggled(new_visible)
signal late_early_changed(new_value)


func _ready() -> void:
	var late_early_drop := $"ScrollContainer/VBoxContainer/ExtraDisplays/LateEarly/OptionButton" as OptionButton
	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")


func hit_error(new_visible: bool) -> void:
	emit_signal("hit_error_toggled", new_visible)


func late_early(new_value: int) -> void:
	emit_signal("late_early_changed", new_value)


func save_settings() -> void:
	settings.saveConfig()


func toggle_settings() -> void:
	visible = !visible
