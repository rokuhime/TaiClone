class_name Placer
extends HitObject

var _is_kat := false

func change_display(new_kat: bool, new_finisher: bool) -> void:
	# finisher
	if new_finisher != finisher:
		if new_finisher:
			print("its a finisher")
			rect_position *= FINISHER_SCALE
			rect_size *= FINISHER_SCALE
		else:
			print("not a finisher")
			rect_position /= FINISHER_SCALE
			rect_size /= FINISHER_SCALE
	finisher = new_finisher

	# kat
	_is_kat = new_kat
	self_modulate = root_viewport.skin.kat_color - Color(0,0,0,0.5) if _is_kat else root_viewport.skin.don_color - Color(0,0,0,0.5)

## See [HitObject].
func apply_skin() -> void:
	self_modulate = root_viewport.skin.kat_color - Color(0,0,0,0.5) if _is_kat else root_viewport.skin.don_color - Color(0,0,0,0.5)
	texture = root_viewport.skin.big_circle if finisher else root_viewport.skin.hit_circle
		

