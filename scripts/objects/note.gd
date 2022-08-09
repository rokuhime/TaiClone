class_name Note
extends HitObject

var is_kat := false


func _ready() -> void:
	# note colour
	($"Sprite" as CanvasItem).self_modulate = _g.skin.kat_colour if is_kat else _g.skin.don_colour


func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	.ini(new_timing, new_speed, 0, new_finisher)
	if not _loaded:
		is_kat = new_is_kat
