class_name SpinnerWarn
extends HitObject

var _bpm := 1.0

onready var _spinner_obj := preload("res://game/objects/spinner_object.tscn")


func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length)
	if not _loaded:
		_bpm = new_bpm


func miss_check(hit_time: float) -> String:
	if _finished:
		return "finished"
	if hit_time > timing:
		_finished = true

		# make spinner obj first
		var spinner := _spinner_obj.instance() as Spinner
		spinner.change_properties(timing, _length, int(_length * 960 / _bpm))
		get_parent().add_child(spinner)
		get_parent().move_child(spinner, 0)

		# make self deactive (duh!)
		queue_free()
	return ""
