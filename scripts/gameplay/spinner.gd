class_name Spinner
extends HitObject

# The number of hits received by this `Spinner`.
var _cur_hit_count := 0

# The current rotational speed of this `Spinner`.
var _current_speed := 0.0

# Whether or not this `Spinner`'s first hit is a don or kat.
var _first_hit_is_kat := false

# The `SceneTreeTween` used to fade this `Spinner` in and out.
var _modulate_tween := SceneTreeTween.new()

# The number of hits required for an ACCURATE `Score` for this `Spinner`.
var _needed_hits := 0

# The `SceneTreeTween` used to tween this `Spinner`'s `_current_speed`.
var _speed_tween := SceneTreeTween.new()


func _ready() -> void:
	_count_text()

	# The `PropertyTweener` that's used to tween the approach circle of this `Spinner`.
	var _approach_tween := Root.new_tween(SceneTreeTween.new(), self).tween_property($Approach as Control, "rect_scale", Vector2(0.1, 0.1), length).set_ease(Tween.EASE_OUT)

	# The `PropertyTweener` used to fade in this `Spinner`.
	var _tween := _tween_modulate(Color.white)

	.activate()


func _process(_delta: float) -> void:
	if state == int(State.ACTIVE):
		($RotationObj as Node2D).rotation_degrees += _current_speed


# Initialize `Spinner` variables.
func change_properties(new_timing: float, new_length: float, new_hits: int) -> void:
	.ini(new_timing, 0, new_length)
	_needed_hits = new_hits


# Tween this `Spinner`'s `_current_speed`.
func change_speed(new_speed: float) -> void:
	_current_speed = new_speed


# Dispose of this `Spinner` once tweens have finished.
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

	# The list of scores to add.
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
	_speed_tween = Root.new_tween(_speed_tween, self).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	# The `MethodTweener` that's used to tween this `Spinner`'s `_current_speed`.
	var _tween := _speed_tween.tween_method(self, "change_speed", 3, 0, 1)

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


# Set text to the remaining hits required for an ACCURATE `Score` for this `Spinner`.
func _count_text() -> void:
	($Label as Label).text = str(_needed_hits - _cur_hit_count)


# Set this `Spinner` to the FINISHED `State`.
func _spinner_finished() -> void:
	if state != int(State.FINISHED):
		state = int(State.FINISHED)

		# The `PropertyTweener` used to fade out this `Spinner`.
		if _tween_modulate(Color.transparent).connect("finished", self, "deactivate"):
			push_warning("Attempted to connect PropertyTweener finished.")


# Fade this `Spinner` in and out.
func _tween_modulate(final_val: Color) -> PropertyTweener:
	_modulate_tween = Root.new_tween(_modulate_tween, self).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	return _modulate_tween.tween_property(self, "modulate", final_val, 0.25)
