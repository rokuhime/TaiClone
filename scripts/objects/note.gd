class_name Note
extends HitObject

var _is_kat := false


func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	.ini(new_timing, new_speed, 0, new_finisher)
	if not state:
		_is_kat = new_is_kat


func hit(inputs: Array, hit_time: float) -> Array:
	if state == int(State.FINISHED):
		inputs.append(Score.FINISHED)
	if state != int(State.ACTIVE):
		return inputs
	var hit_timing := hit_time - timing
	if hit_timing < 0:
		return inputs
	state = int(State.FINISHED)
	if _is_kat:
		if inputs.has("LeftKat"):
			inputs.remove(inputs.find("LeftKat"))
			inputs.append(hit_timing)
		elif inputs.has("RightKat"):
			inputs.remove(inputs.find("RightKat"))
			inputs.append(hit_timing)
		else:
			inputs.append("miss")
	else:
		if inputs.has("LeftDon"):
			inputs.remove(inputs.find("LeftDon"))
			inputs.append(hit_timing)
		elif inputs.has("RightDon"):
			inputs.remove(inputs.find("RightDon"))
			inputs.append(hit_timing)
		else:
			inputs.append("miss")
	queue_free()
	return inputs


func skin(new_skin: SkinManager) -> void:
	# note colour
	($Sprite as CanvasItem).self_modulate = new_skin.KAT_COLOUR if _is_kat else new_skin.DON_COLOUR
