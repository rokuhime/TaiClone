class_name SpinnerWarn
extends HitObject

var _bpm := 1.0


func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length)
	if not state:
		_bpm = new_bpm


func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED
	if hit_time > timing:
		state = int(State.FINISHED)

		# make spinner obj first
		var spinner := preload("res://game/objects/spinner_object.tscn").instance() as Spinner
		spinner.change_properties(timing, length, int(length * 960 / _bpm))
		get_parent().add_child(spinner)
		get_parent().move_child(spinner, 0)

		# make self deactive (duh!)
		queue_free()
	return 0
