class_name BarLine
extends HitObject


## Initialize [BarLine] variables.
func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0)
	end_time += 10

## used to hide object, not for actual misses
## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > timing:
		state = int(State.FINISHED)
		if not visible:
			queue_free()

	return false
