class_name BarLine
extends HitObject

onready var color_rect := $ColorRect as CanvasItem


## Initialize [BarLine] variables.
func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0)
	end_time += 1


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > timing:
		state = int(State.FINISHED)
		if not visible:
			queue_free()

	return false


## See [HitObject].
func skin(new_skin: SkinManager) -> void:
	color_rect.self_modulate = new_skin.barline_color