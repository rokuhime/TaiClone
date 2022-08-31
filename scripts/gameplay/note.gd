class_name Note
extends HitObject

## Comment
signal new_marker_added(timing, add)

## Comment
var _first_hit := -1.0

## Whether or not this [Note] is a don or kat.
var _is_kat := true

## Comment
var _next_hit := ""

onready var head := $Head as CanvasItem


## See [HitObject].
func apply_skin(new_skin: SkinManager) -> void:
	head.self_modulate = new_skin.kat_color if _is_kat else new_skin.don_color


## Initialize [Note] variables.
func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	.ini(new_timing, new_speed, 0, new_finisher)
	_is_kat = new_is_kat


## See [HitObject].
func hit(inputs: Array, hit_time: float) -> bool:
	hit_time -= timing

	## Comment
	var early := hit_time < 0

	if state != int(State.ACTIVE) or early:
		return early

	## Comment
	var key := "Kat" if _is_kat else "Don"

	if _first_hit < 0:
		## Comment
		var this_hit := check_hit(key, inputs, not finisher)

		if not this_hit:
			finish(int(Score.MISS), true)
			return true

		_next_hit = "Right" if this_hit == "Left" else "Left" if this_hit == "Right" else ""
		if finisher:
			emit_signal("audio_played", "Finisher" + key)
			_first_hit = hit_time
			hide()

		else:
			finish()

		emit_signal("new_marker_added", hit_time, true)
		if Root.inputs_empty(inputs):
			return true

	if not finisher:
		return false

	if _next_hit:
		key = _next_hit + key
		if inputs.has(key):
			inputs.remove(inputs.find(key))
			emit_signal("new_marker_added", hit_time, false)

		else:
			finish()
			return false

	elif not check_hit(key, inputs, false):
		return true

	finish(int(Score.FINISHER))
	return false


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > timing:
		finish(int(Score.MISS) if _first_hit < 0 else -1)
		return false

	return true
