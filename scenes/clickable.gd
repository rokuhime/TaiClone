class_name Clickable
extends Hoverable

## Comment
signal clicked
export var sound := false

## Comment
func click_end() -> void:
	emit_signal("clicked")
	hover_start()
	if sound:
		(get_node("TextureRect") as TextureRect).texture = GlobalTools.get_image_texture("res://temporary/squisheh1.png")
		($AudioStreamPlayer as AudioStreamPlayer).stream = AudioLoader.load_file("res://temporary/squeaky2.wav")
		($AudioStreamPlayer as AudioStreamPlayer).play()
		
func click_start() -> void:
	background.modulate = Color("737373")
	if sound:
		(get_node("TextureRect") as TextureRect).texture = GlobalTools.get_image_texture("res://temporary/squisheh2.png")
		($AudioStreamPlayer as AudioStreamPlayer).stream = AudioLoader.load_file("res://temporary/squeaky1.wav")
		($AudioStreamPlayer as AudioStreamPlayer).play()
