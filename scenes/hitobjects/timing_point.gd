class_name TimingPoint
extends HitObject

## Comment
var is_kiai := true

## Comment
var bpm := -1.0


## Initialize [TimingPoint] variables.
func change_properties(new_timing: float, new_kiai: bool, new_bpm: float) -> void:
	.ini(new_timing, new_bpm * 10, 0)
	bpm = new_bpm
	is_kiai = new_kiai


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > timing:
		finish()
		return false

	return true
