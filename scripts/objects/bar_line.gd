class_name BarLine
extends HitObject


# Initialize `BarLine` variables.
func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0)


# See `HitObject`.
func skin(new_skin: SkinManager) -> void:
	($ColorRect as CanvasItem).self_modulate = new_skin.BARLINE_COLOUR
