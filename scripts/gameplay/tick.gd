class_name Tick
extends HitObject


## See [HitObject].
func activate() -> void:
	.activate()
	position.x = timing


## Initialize [Tick] variables.
func change_properties(new_timing: float) -> void:
	.ini(new_timing, 0, 0)
