class_name Note
extends HitObject

# Whether or not this `Note` is a kat or a don.
var _is_kat := false


# Initialize `Note` variables.
func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	.ini(new_timing, new_speed, 0, new_finisher)
	_is_kat = new_is_kat


# See `HitObject`.
func hit(inputs: Array, hit_time: float) -> Array:
	if state == int(State.FINISHED):
		inputs.append([int(Score.FINISHED)])

	# Time since the start of this `Note`'s hit window. A perfect hit has the value of `HitError.inacc_timing`.
	var hit_timing := hit_time - timing

	if state != int(State.ACTIVE) or hit_timing < 0:
		return inputs

	# TODO: Finishers
	state = int(State.FINISHED)
	if _is_kat:
		if inputs.has("LeftKat"):
			inputs.remove(inputs.find("LeftKat"))
			inputs.append([hit_timing])

		elif inputs.has("RightKat"):
			inputs.remove(inputs.find("RightKat"))
			inputs.append([hit_timing])

		else:
			inputs.append([int(Score.MISS)])

	else:
		if inputs.has("LeftDon"):
			inputs.remove(inputs.find("LeftDon"))
			inputs.append([hit_timing])

		elif inputs.has("RightDon"):
			inputs.remove(inputs.find("RightDon"))
			inputs.append([hit_timing])

		else:
			inputs.append([int(Score.MISS)])

	queue_free()
	return inputs


# See `HitObject`.
func skin(new_skin: SkinManager) -> void:
	($Sprite as CanvasItem).self_modulate = new_skin.KAT_COLOUR if _is_kat else new_skin.DON_COLOUR
