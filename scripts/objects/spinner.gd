class_name Spinner
extends HitObject

# Comment
var _cur_hit_count := 0

# Comment
var _current_speed := 0.0

# Comment
var _first_hit_is_kat := false

# Comment
var _modulate_tween := SceneTreeTween.new()

# Comment
var _needed_hits := 0

# Comment
var _speed_tween := SceneTreeTween.new()


func _ready() -> void:
	_count_text()

	# Comment
	var _approach_tween := _new_tween(SceneTreeTween.new()).tween_property($Approach as Control, "rect_scale", Vector2(0.1, 0.1), length)

	# Comment
	var _tween := _tween_modulate(Color.white)

	.activate()


func _process(_delta: float) -> void:
	if state == int(State.ACTIVE):
		($RotationObj as Node2D).rotation_degrees += _current_speed


# Initialize `Spinner` variables.
func change_properties(new_timing: float, new_length: float, new_hits: int) -> void:
	.ini(new_timing, 0, new_length)
	_needed_hits = new_hits


# Comment
func change_speed(new_speed: float) -> void:
	_current_speed = new_speed


# Comment
func deactivate(_object := null, _key := "") -> void:
	queue_free()


# See `HitObject`.
func hit(inputs: Array, hit_time: float) -> Array:
	if state == int(State.FINISHED):
		inputs.append([int(Score.FINISHED)])

	if state != int(State.ACTIVE) or hit_time < timing:
		return inputs

	if not _cur_hit_count:
		_first_hit_is_kat = inputs.has("LeftKat") or inputs.has("RightKat")

	# Comment
	var scores := []

	while true:
		if _cur_hit_count % 2 != int(_first_hit_is_kat):
			if inputs.has("LeftKat"):
				inputs.remove(inputs.find("LeftKat"))

			elif inputs.has("RightKat"):
				inputs.remove(inputs.find("RightKat"))

			else:
				break

		else:
			if inputs.has("LeftDon"):
				inputs.remove(inputs.find("LeftDon"))

			elif inputs.has("RightDon"):
				inputs.remove(inputs.find("RightDon"))

			else:
				break

		_cur_hit_count += 1
		scores.append(int(Score.SPINNER))
		if _cur_hit_count == _needed_hits:
			_spinner_finished()
			scores.append(int(Score.ACCURATE))
			break

	if scores.empty():
		inputs.append([int(Score.FINISHED)])
		return inputs

	_count_text()
	_speed_tween = _new_tween(_speed_tween)

	var _tween := _speed_tween.tween_method(self, "change_speed", 3, 0, 1).set_trans(Tween.TRANS_CIRC)

	inputs.append(scores)
	return inputs


# See `HitObject`.
func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED

	if hit_time - length > timing:
		_spinner_finished()
		return Score.INACCURATE if _needed_hits / 2.0 <= _cur_hit_count else Score.MISS

	return 0


# Comment
func _count_text() -> void:
	($Label as Label).text = str(_needed_hits - _cur_hit_count)


# Comment
func _new_tween(old_tween: SceneTreeTween) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return create_tween().set_ease(Tween.EASE_OUT)


# Comment
func _spinner_finished() -> void:
	if state != int(State.FINISHED):
		state = int(State.FINISHED)
		if _tween_modulate(Color.transparent).connect("finished", self, "deactivate"):
			push_warning("Attempted to connect PropertyTweener finished.")


# Comment
func _tween_modulate(final_val: Color) -> PropertyTweener:
	_modulate_tween = _new_tween(_modulate_tween).set_trans(Tween.TRANS_EXPO)
	return _modulate_tween.tween_property(self, "modulate", final_val, 0.25)
