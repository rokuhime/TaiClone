extends CanvasItem

signal hit_error_toggled(new_visible)
signal late_early_changed(new_value)
signal offset_changed

onready var _v := $"ScrollContainer/VBoxContainer"


func _ready() -> void:
	var late_early_drop := _v.get_node("ExtraDisplays/LateEarly/OptionButton") as OptionButton
	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")

	var offset_text := _v.get_node("Audio/Offset/LineEdit") as LineEdit
	if settings.globalOffset != 0:
		offset_text.text = str(settings.globalOffset)


# this script stinks. gonna become obsolete when i get actual good settings going w
func change_offset(new_value: String) -> void:
	settings.globalOffset = float(new_value) / 1000
	print_debug("Offset set to: %s" % settings.globalOffset)
	emit_signal("offset_changed")


func hit_error(new_visible: bool) -> void:
	emit_signal("hit_error_toggled", new_visible)


func late_early(new_value: int) -> void:
	emit_signal("late_early_changed", new_value)


func save_settings() -> void:
	settings.saveConfig()


func toggle_settings() -> void:
	visible = !visible
