class_name TimingPoint
extends HitObject

var bpm: float
var meter: int

func miss_check(hit_time: float) -> bool:
	if active:
		active = false
		return true
	return false
