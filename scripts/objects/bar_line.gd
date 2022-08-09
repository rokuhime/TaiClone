class_name Bar_Line
extends HitObject

func _ready() -> void:
	# note colour
	#($"Sprite" as TextureRect).self_modulate = _g.skin.barline_colour 
	pass


func change_properties(new_timing: float, new_speed: float) -> void:
	.ini(new_timing, new_speed, 0, false)
