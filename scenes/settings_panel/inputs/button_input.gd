class_name ButtonInput
extends HBoxContainer

onready var root_viewport := $"/root" as Root
onready var clickable := $Clickable as Clickable
onready var titleObj := $Title as Label
onready var inputObj := $Clickable/Label as Label

export var title := "Title"

signal clicked

func _ready():
	#set textures for clickable
	clickable.texture = root_viewport.box_white
	clickable.background.texture = root_viewport.box_black
	
	#assign presets to the ButtonInput
	titleObj.text = title
	inputObj.theme_type_variation = "FontRegular026"

# change the text inside Clickable
func change_input(val: String):
	inputObj.text = val

# bounces signal from Clickable to the ButtonInput
func click() -> void:
	emit_signal("clicked")
