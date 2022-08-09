class_name BarLine
extends HitObject


func _ready() -> void:
	# note colour
	($"ColorRect" as CanvasItem).self_modulate = skin.barline_colour


func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0)
