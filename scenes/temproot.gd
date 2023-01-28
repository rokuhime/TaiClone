extends Node

var skin := self

var barline_color : Color
var don_color : Color
var kat_color : Color
var roll_color : Color

func _init(skin_path: String) -> void:
	barline_color = Color.white
	don_color = Color("eb452c")
	kat_color = Color("448dab")
	roll_color = Color("fc5306")
