class_name SpinnerWarn
extends HitObject

## Signals [Gameplay] to add the [Spinner] object.
signal object_added(hit_object, loaded)

## The BPM of the chart when the [Spinner] starts. Used to determine the number of hits required.
var _bpm := -1.0


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	texture = root_viewport.skin.spinner_warning


## Initialize [SpinnerWarn] variables.
func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length)
	_bpm = new_bpm
	end_time = timing


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time <= timing:
		return true

	if state != int(State.FINISHED):
		state = int(State.FINISHED)

		## The [Spinner] object to spawn.
		var spinner := root_viewport.spinner_object.instance() as Spinner

		spinner.change_properties(timing, length, int(length * 960 / _bpm))
		emit_signal("object_added", spinner, false)
		queue_free()

	return false
