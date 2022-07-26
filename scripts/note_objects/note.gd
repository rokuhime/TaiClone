class_name Note
extends HitObject

var is_kat := false

func _ready() -> void:
	var sprite := $"Sprite" as TextureRect

	# finisher scale
	if finisher:
		sprite.rect_scale = Vector2 (0.9, 0.9)

	# note colour
	($"Sprite" as TextureRect).self_modulate = _gameplay.skin.kat_colour if is_kat else _gameplay.skin.don_colour


func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	.ini(new_timing, new_speed, 0, new_finisher)
	if not _loaded:
		is_kat = new_is_kat
