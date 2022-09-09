class_name TimingPoint
extends HitObject

## Comment
var _bpm := -1.0

## Comment
var _is_kiai := true


## Initialize [TimingPoint] variables.
func change_properties(new_timing: float, new_kiai: bool, new_bpm: float) -> void:
	.ini(new_timing, new_bpm * 10, 0)
	_bpm = new_bpm
	_is_kiai = new_kiai
