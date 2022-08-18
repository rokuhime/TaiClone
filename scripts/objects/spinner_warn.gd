class_name SpinnerWarn
extends HitObject

# The BPM of the chart when the `Spinner` starts. Used to determine the number of hits required.
var _bpm := 1.0


# Initialize `SpinnerWarn` variables.
func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length)
	_bpm = new_bpm


# See `HitObject`.
func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED

	if hit_time > timing:
		state = int(State.FINISHED)

		# The `Spinner` object to spawn.
		var spinner := preload("res://game/objects/gameplay/spinner_object.tscn").instance() as Spinner

		spinner.change_properties(timing, length, int(length * 960 / _bpm))
		get_parent().add_child(spinner)
		# TODO Check end time for correct index.
		get_parent().move_child(spinner, 0)
		queue_free()

	return 0
