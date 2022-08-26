class_name Tick
extends HitObject


## Initialize [Tick] variables.
func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0)
	print(speed * timing)
