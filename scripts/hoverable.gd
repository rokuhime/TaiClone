class_name Hoverable
extends NinePatchRect

onready var background := $Background as NinePatchRect


func _ready() -> void:
	hover_end()


## Comment
func hover_end() -> void:
	background.modulate = Color.black


## Comment
func hover_start() -> void:
	background.modulate = Color("2d2d2d")
