class_name Clickable
extends Hoverable

## Comment
signal clicked

## Comment
enum Style {BOX, BUTTON, EDGE, FLAT}

export(String) var label_text := ""
export(Style) var style
export var sound := false

onready var root_viewport := $"/root" as Root
onready var label_object := $Label as Label


func _ready() -> void:
	label_object.text = label_text
	match int(style):
		Style.BOX:
			texture = root_viewport.box_white
			background.texture = root_viewport.box_black

		Style.BUTTON:
			texture = root_viewport.button_white
			background.texture = root_viewport.button_black

		Style.EDGE:
			texture = root_viewport.edge_white
			background.texture = root_viewport.edge_black

		Style.FLAT:
			background.texture = root_viewport.box_flat


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
