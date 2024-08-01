extends VBoxContainer

@onready var spinbox: SpinBox = $SpinBox
@onready var slider: HSlider = $HSlider

func _ready():
	update_visual(false)
	update_visual(true)

func set_global_offset(new_offset: float, updated_from_spinbox := false):
	Global.change_global_offset(new_offset / 1000.0)
	update_visual(updated_from_spinbox)
	Global.change_focus_state(false)

func update_visual(updated_from_spinbox) -> void:
	if updated_from_spinbox:
		slider.set_value_no_signal(Global.global_offset * 1000)
	else:
		spinbox.set_value_no_signal(Global.global_offset * 1000)
