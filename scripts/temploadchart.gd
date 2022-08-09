extends Node

signal load_chart(file_path)

onready var _debug_text := $"debugtext" as Label
onready var _file_input := $"temploadchart/LineEdit" as LineEdit
onready var _fps_text := $"fpstext" as Label


func _process(_delta: float) -> void:
	_fps_text.text = "FPS: %s" % Engine.get_frames_per_second()


func load_func() -> void:
	_debug_text.text = "Loading... [Checking File]"
	var file_path := _file_input.text.replace("\\", "/")
	if File.new().file_exists(file_path):
		_debug_text.text = "Loading... [Reading File]"
		emit_signal("load_chart", file_path)
		_debug_text.text = "Done!"
	else:
		_debug_text.text = "Invalid file!"
