class_name FloatSlider
extends ModValue

@onready var slider: HSlider = $HBoxContainer/HSlider
@onready var line_edit: LineEdit = $HBoxContainer/LineEdit

func on_text_changed(new_value: String) -> void:
	line_edit.release_focus()
	if not float(new_value):
		line_edit.text = str(slider.value)
	value_changed(float(new_value), false)

func value_changed(new_value: float, from_slider: bool) -> void:
	if from_slider:
		line_edit.text = str(new_value)
		return
	
	slider.value = new_value
