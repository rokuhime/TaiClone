class_name Checkbox
extends Clickable

signal toggled(tgl)

onready var root_viewport := $"/root" as Root
onready var titleObj := $H/Title as Label
onready var toggleObj := $H/Toggle as TextureRect

export var title := "Title"
export var toggled := false

func _ready():
	#set textures for clickable
	background.texture = root_viewport.box_flat
	
	#assign presets to the Checkbox
	titleObj.text = title

# change the texture of toggle
func change_toggle(val: bool):
	toggled = val
	
	if val:
		toggleObj.texture = root_viewport.box_flat
	else:
		toggleObj.texture = root_viewport.box_neutral

	emit_signal("toggled", toggled)

func hover_end() -> void:
		background.modulate = Color.transparent

# bounces signal
func click() -> void:
	change_toggle(not toggled)
