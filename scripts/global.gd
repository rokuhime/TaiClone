extends Node

const VERSION := "v0.0.1 - how many branches does it take to screw in a lightbulb?"

var expiring_audio = preload("res://scenes/global/expiring_audio.tscn")
const ACC_TIMING := 0.03
const INACC_TIMING := 0.07

func _init() -> void:
	DisplayServer.window_set_title("TaiClone " + VERSION, 0)

# made for timer class
func format_time(time) -> String:
	if time <= 0:
		return "00:00.00"
	var min : int = floor(time / 60)
	var sec : int = fmod(time, 60)
	var mil : int = fmod((time * 1000), 1000) / 10
	var str := "%02d:%02d.%02d" % [min, sec, mil]
	return str

# this should probably use an await??
func load_file(directory):
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	var content = file.get_as_text()
	file.close() # i aint makin any memory leaks you got me MESSED UP
	return content
