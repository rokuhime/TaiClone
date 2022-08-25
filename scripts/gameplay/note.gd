class_name Note
extends HitObject

## Whether or not this [Note] is a don or kat.
var _is_kat := false

# if the last hit was on the right side; only applies to finishers
# saved as int because this cant be null :(
var _previous_side_was_right := 0

onready var sprite := $Sprite as CanvasItem


## Initialize [Note] variables.
func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	.ini(new_timing, new_speed, 0, new_finisher)
	_is_kat = new_is_kat


## See [HitObject].
func hit(inputs: Array, hit_time: float) -> Array:
	if state == int(State.FINISHED):
		inputs.append([int(Score.FINISHED)])

	## The time since the start of this [Note]'s hit window. A perfect hit has the value of [member Root.inacc_timing].
	var hit_timing := hit_time - timing

	if state != int(State.ACTIVE) or hit_timing < 0:
		return inputs
		
	
	# The list of scores to add.
	var scores := []
	
	var current_side_is_right : int
	
	if _is_kat:
		if inputs.has("LeftKat"):
			inputs.remove(inputs.find("LeftKat"))
			scores.append(hit_timing)
			current_side_is_right = 1

		elif inputs.has("RightKat"):
			inputs.remove(inputs.find("RightKat"))
			scores.append(hit_timing)
			current_side_is_right = 2

		else:
			scores.append(int(Score.MISS))

	else:
		if inputs.has("LeftDon"):
			inputs.remove(inputs.find("LeftDon"))
			scores.append(hit_timing)
			current_side_is_right = 1

		elif inputs.has("RightDon"):
			inputs.remove(inputs.find("RightDon"))
			scores.append(hit_timing)
			current_side_is_right = 2

		else:
			scores.append(int(Score.MISS))

	# finisher check
	
	# if it isnt a finisher...
	if not finisher:
		state = int(State.FINISHED)
		queue_free()
	
	# if finisher, check the last side used
	elif _previous_side_was_right != 0:
		if bool(_previous_side_was_right - 1) != bool(current_side_is_right - 1):
			#finisher hit
			scores.remove(0)
			scores.append(int(Score.FINISHER))
			
			state = int(State.FINISHED)
			queue_free()
	else:
		hide()
		_previous_side_was_right = current_side_is_right
	
	
	inputs.append(scores)
	return inputs

func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED

	if hit_time > timing:
		if _previous_side_was_right != 0:
			state = Score.FINISHED
			queue_free()
			return Score.FINISHED
		else:
			queue_free()
			return Score.MISS

	return 0

## See [HitObject].
func skin(new_skin: SkinManager) -> void:
	sprite.self_modulate = new_skin.kat_color if _is_kat else new_skin.don_color
