class_name Spinner
extends HitObject

var _cur_hit_count := 0
var _current_speed := 0.0
var _first_hit_is_kat := false
var _needed_hits := 0

onready var _count_text := $"Label" as Label
onready var _spin_circ_rot := $"RotationObj" as Node2D
onready var _tween := $"Tween" as Tween


func _ready() -> void:
	# set counter text to say how many hits are needed
	_count_text.text = str(_needed_hits)

	# make approach circle shrink
	var approach := $"Approach" as Control
	if not _tween.remove(approach, "rect_scale"):
		push_warning("Attempted to remove spinner approach tween.")
	if not _tween.interpolate_property(approach, "rect_scale", Vector2(1, 1), Vector2(0.1, 0.1), _length, Tween.TRANS_LINEAR, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner approach.")

	# make spinner fade in
	if not _tween.remove(self, "modulate"):
		push_warning("Attempted to remove spinner fade in tween.")
	if not _tween.interpolate_property(self, "modulate", Color.transparent, Color.white, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner fade in.")

	if not _tween.start():
		push_warning("Attempted to start spinner tweens.")


func _process(_delta: float) -> void:
	if not _loaded:
		return
	_spin_circ_rot.rotation_degrees += _current_speed


func change_properties(new_timing: float, new_length: float, new_hits: int) -> void:
	.ini(new_timing, 0, new_length)
	if not _loaded:
		_needed_hits = new_hits


func deactivate(_object := null, _key := "") -> void:
	queue_free()


func hit(inputs: Array, hit_time: float) -> Array:
	if _finished:
		inputs.append("finished")
		return inputs
	if hit_time < _timing:
		return inputs

	if _cur_hit_count == 0:
		_first_hit_is_kat = inputs.has("LeftKat") or inputs.has("RightKat")
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

		# hit_success function
		_cur_hit_count += 1
		inputs.append("spinner")
		if _cur_hit_count == _needed_hits:
			spinner_finished()
			inputs.append("accurate")
			break
	if not inputs.has("spinner"):
		inputs.append("finished")
		return inputs

	_count_text.text = str(_needed_hits - _cur_hit_count)

	if not _tween.remove(self, "_current_speed"):
		push_warning("Attempted to remove spinner speed tween.")
	if not _tween.interpolate_property(self, "_current_speed", 3, 0, 1, Tween.TRANS_CIRC, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner speed.")
	if not _tween.start():
		push_warning("Attempted to start spinner speed tween.")
	return inputs


func miss_check(hit_time: float) -> String:
	if _finished:
		return "finished"
	if hit_time - _length > _timing:
		spinner_finished()
		return "inaccurate" if _needed_hits / 2.0 <= _cur_hit_count else "miss"
	return ""


func spinner_finished() -> void:
	if _finished:
		return
	_finished = true

	# make spinner fade out
	if not _tween.remove(self, "modulate"):
		push_warning("Attempted to remove spinner fade out tween.")
	if not _tween.interpolate_property(self, "modulate", Color.white, Color.transparent, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner fade out.")
	var _connect := _tween.connect("tween_completed", self, "deactivate")
	if not _tween.start():
		push_warning("Attempted to start spinner fade out tween.")
