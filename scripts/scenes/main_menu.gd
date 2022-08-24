extends Node

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	print(get_node("../../"))
	var _a = $Middle/Buttons/Play.connect("pressed", get_node("../../"), "changeUI", ["songselect"])
	_a = $Middle/Buttons/Play.connect("pressed", get_node("../../"), "playMenuSound", ["Select"])

func _exit_tree():
	print("AHHHHHHHHHHHHHHHHHH")
