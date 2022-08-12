class_name BarLine
extends HitObject


func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0)


func skin(new_skin: SkinManager) -> void:
	# note colour
	($ColorRect as CanvasItem).self_modulate = new_skin.BARLINE_COLOUR
