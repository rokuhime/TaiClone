class_name SpinnerWarn
extends HitObject

var _bpm := 1.0

onready var _spinner_obj := preload("res://game/objects/spinner_object.tscn")


func _process(_delta: float) -> void:
	if _active and _gameplay.music.get_playback_position() >= timing:
		deactivate()


func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length)
	if not _loaded:
		_bpm = new_bpm


func deactivate() -> void:
	# make spinner obj first
	var spinner := _spinner_obj.instance() as Spinner
	spinner.change_properties(timing, _length, int(_length * 960 / _bpm))
	get_parent().add_child(spinner)
	get_parent().move_child(spinner, 0)

	# make self deactive (duh!)
	.deactivate()
