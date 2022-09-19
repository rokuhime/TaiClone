class_name Clickable
extends Hoverable

## Comment
signal clicked


## Comment
func click_end() -> void:
	emit_signal("clicked")
	hover_start()


## Comment
func click_start() -> void:
	background.modulate = Color("737373")
