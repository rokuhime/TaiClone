class_name Metadata
extends Node

onready var root_viewport := $"/root" as Root

onready var title_edit := $ScrollContainer/VBoxContainer/Title/LineEdit as LineEdit
onready var artist_edit := $ScrollContainer/VBoxContainer/Artist/LineEdit as LineEdit
onready var difficulty_edit := $ScrollContainer/VBoxContainer/Difficulty/LineEdit as LineEdit
onready var charter_edit := $ScrollContainer/VBoxContainer/Charter/LineEdit as LineEdit
onready var od_edit := $ScrollContainer/VBoxContainer/OD/SpinBox as SpinBox

func reload():
	title_edit.text = root_viewport.title
	artist_edit.text = root_viewport.artist
	difficulty_edit.text = root_viewport.difficulty_name
	charter_edit.text = root_viewport.charter
	od_edit.value = float(root_viewport.od)


func edit_metadata(input, type):
	match type:
		"title":
			root_viewport.title = input
		"artist":
			root_viewport.artist = input
		"difficulty":
			root_viewport.difficulty_name = input
		"charter":
			root_viewport.charter = input
		"od":
			root_viewport.od = String(input)
	reload()
