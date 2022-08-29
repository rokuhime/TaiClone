class_name Spinner
extends HitObject

## The number of hits received by this [Spinner].
var _cur_hit_count := 0

## The current rotational speed of this [Spinner].
var _current_speed := 0.0

## Whether or not this [Spinner]'s first hit is a don or kat.
var _first_hit_is_kat := false

## The [SceneTreeTween] used to fade this [Spinner] in and out.
var _modulate_tween := SceneTreeTween.new()

## The number of hits required for an ACCURATE [member HitObject.Score] for this [Spinner].
var _needed_hits := 0

## The [SceneTreeTween] used to tween this [Spinner]'s [member _current_speed].
var _speed_tween := SceneTreeTween.new()

onready var approach := $Approach as Control
onready var label := $Label as Label
onready var rotation_obj := $RotationObj as Node2D
onready var taiclone := $"/root" as Root


func _ready() -> void:
	_count_text()

	## The [PropertyTweener] that's used to tween the approach circle of this [Spinner].
	var _approach_tween := taiclone.new_tween(SceneTreeTween.new()).tween_property(approach, "rect_scale", Vector2(0.1, 0.1), length).set_ease(Tween.EASE_OUT)

	## The [PropertyTweener] used to fade in this [Spinner].
	var _tween := _tween_modulate(1)

	.activate()


func _process(_delta: float) -> void:
	if state == int(State.ACTIVE):
		rotation_obj.rotation_degrees += _current_speed


## Initialize [Spinner] variables.
func change_properties(new_timing: float, new_length: float, new_hits: int) -> void:
	.ini(new_timing, 0, new_length)
	_needed_hits = int(max(1, new_hits))


## Change this [Spinner]'s [member _current_speed].
func change_speed(new_speed: float) -> void:
	_current_speed = new_speed


## See [HitObject].
func hit(inputs: Array, hit_time: float) -> bool:
	## Comment
	var early := hit_time < timing

	if state != int(State.ACTIVE) or early:
		return early

	if not _cur_hit_count:
		# TODO: Redo first hit logic to not bias kats
		_first_hit_is_kat = inputs.has("Kat") or inputs.has("LeftKat") or inputs.has("RightKat")

	## The list of [member HitObject.Score]s to add.
	var scores := []

	while not Root.inputs_empty(inputs):
		## Comment
		var key := "Don" if _cur_hit_count % 2 == int(_first_hit_is_kat) else "Kat"

		## Comment
		var this_hit := check_hit(key, inputs)

		if not this_hit:
			break

		_cur_hit_count += 1
		scores.append(int(Score.SPINNER))
		if _cur_hit_count == _needed_hits:
			_spinner_finished(int(Score.ACCURATE))
			break

	if scores.empty():
		return false

	for score in scores:
		emit_signal("score_added", score, false)

	_count_text()
	_speed_tween = taiclone.new_tween(_speed_tween).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	## The [MethodTweener] that's used to tween this [Spinner]'s [member _current_speed].
	var _tween := _speed_tween.tween_method(self, "change_speed", 3, 0, 1)

	return false


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > end_time:
		_spinner_finished(int(Score.MISS if _needed_hits / 2.0 > _cur_hit_count else Score.INACCURATE))
		return false

	return true


## Set text to the remaining hits required for an ACCURATE [member HitObject.Score] for this [Spinner].
func _count_text() -> void:
	label.text = str(_needed_hits - _cur_hit_count)


## Set this [Spinner] to the FINISHED [member HitObject.State].
func _spinner_finished(type: int) -> void:
	if state != int(State.FINISHED):
		state = int(State.FINISHED)
		emit_signal("score_added", type, false)
		Root.send_signal(self, "finished", _tween_modulate(0), "queue_free")


## Fade this [Spinner] in and out.
func _tween_modulate(final_val: float) -> PropertyTweener:
	_modulate_tween = taiclone.new_tween(_modulate_tween).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	return _modulate_tween.tween_property(self, "modulate:a", final_val, 0.25)
