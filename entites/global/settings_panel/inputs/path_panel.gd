class_name PathPanel
extends PanelContainer

var chart_path: String
@onready var path_label: Label = $Label

func _ready() -> void:
	path_label.text = chart_path

func set_path(target_chart_path: String) -> void:
	chart_path = target_chart_path

func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or !event.is_pressed():
			return
		get_tree().get_first_node_in_group("ChartPathChanger").select_path(self)
