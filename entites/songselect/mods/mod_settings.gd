class_name ModSettings
extends PanelContainer

@onready var title: Label = $VBoxContainer/TopInfo/Title

signal remove_button_pressed()

func _ready():
	title.text = name

func on_remove_button_pressed() -> void:
	remove_button_pressed.emit()
