class_name Tick
extends HitObject


## See [HitObject].
func activate() -> void:
	.activate()
	position.x = timing


## Initialize [Tick] variables.
func change_properties(new_timing: float) -> void:
	.ini(new_timing, 0, 0)


## See [HitObject].
func hit(inputs: Array, hit_time: float) -> bool:
	## Comment
	var early := hit_time < timing

	if state != int(State.ACTIVE) or early:
		return early

	inputs.insert(0, int(inputs.pop_front()) + 1)
	finish(int(Score.ROLL))
	return false


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > timing:
		finish()
		return false

	return true
