class_name HitObject
extends KinematicBody2D

## Comment
signal audio_played(key)

## Comment
signal score_added(type, marker)

## The possible scores of a [HitObject]:
## 0 (ACCURATE): 300 points and 100% accuracy. Applies to all [HitObject]s.
## 1 (INACCURATE): 150 points and 50% accuracy. Applies to all [HitObject]s.
## 2 (MISS): 0 points and 0% accuracy. Applies to all [HitObject]s.
## 3 (FINISHER): 300 additional points. Does not affect accuracy. Only applies to [Note]s.
## 4 (ROLL): 300 points. Does not affect accuracy. Only applies to [Roll]s.
## 5 (SPINNER): 600 points. Does not affect accuracy. Only applies to [Spinner]s.
enum Score {ACCURATE, INACCURATE, MISS, FINISHER, ROLL, SPINNER}

## The possible states of a [HitObject]:
## 0: This [HitObject]'s properties can be changed.
## 1 (READY): This [HitObject] has been loaded into the scene. Its properties can no longer be changed.
## 2 (ACTIVE): This [HitObject] has been activated and can receive [method hit] and [method miss_check] calls.
## 3 (FINISHED): This [HitObject] has been fully hit or missed. It will be disposed of once all animations finish.
enum State {READY = 1, ACTIVE, FINISHED}

## Comment
var end_time := 0.0

## Whether or not this [HitObject] is a finisher. Only applies to [Note]s and [Roll]s.
var finisher := false

## The length of this [HitObject]. This does not apply to [BarLine]s and [Note]s.
var length := 0.0

## The slider velocity of this [HitObject]. Applies to all [HitObject]s.
var speed := 0.0

## The [member State] of this [HitObject]. Applies to all [HitObject]s.
var state := 0

## The hit time of this [HitObject]. Applies to all [HitObject]s.
var timing := 0.0


func _ready() -> void:
	if finisher:
		(get_child(0) as Control).rect_scale *= 1.6

	add_to_group("HitObjects")
	state = int(State.READY)


func _process(_delta: float) -> void:
	if state == int(State.ACTIVE):
		## The distance the [HitObject] moved.
		var _vel := move_and_slide(Vector2(-speed, 0))


## Enable motion and [method hit] and [method miss_check] calls on this [HitObject].
func activate() -> void:
	assert(state == int(State.READY), "Attempted to activate hitobject.")
	position.x = speed * timing
	state = int(State.ACTIVE)


## Comment
func check_hit(key: String, inputs: Array, play_audio := true) -> String:
	## Comment
	var left_hit := inputs.find("Left" + key)

	## Comment
	var right_hit := inputs.find("Right" + key)

	if left_hit + 1 and right_hit + 1:
		inputs.remove(left_hit)
		inputs.remove(right_hit)
		inputs.append(key)
		if play_audio:
			emit_signal("audio_played", "Left" + key)
		return key

	elif left_hit + 1:
		inputs.remove(left_hit)
		if play_audio:
			emit_signal("audio_played", "Left" + key)
		return "Left"

	elif right_hit + 1:
		inputs.remove(right_hit)
		if play_audio:
			emit_signal("audio_played", "Right" + key)
		return "Right"

	elif inputs.has(key):
		inputs.remove(inputs.find(key))
		if play_audio:
			emit_signal("audio_played", "Right" + key)
		return key

	else:
		return ""


## Comment
func finish(type := -1, marker := false) -> void:
	if state != int(State.FINISHED):
		state = int(State.FINISHED)
		queue_free()
		if type + 1:
			emit_signal("score_added", type, marker)


## Check if this [HitObject] has been hit. Intended to be implemented by child classes.
## inputs (Array): The list of actions received.
## hit_time (float): The start of this [HitObject]'s hit window.
## return (bool): Whether or not to continue checking for hits.
func hit(_inputs: Array, _hit_time: float) -> bool:
	return false


## Initialize base [HitObject] variables. Called and extended by child classes via [method change_properties].
func ini(new_timing: float, new_speed: float, new_length: float, new_finisher := false) -> void:
	assert(not state, "Attempted to change hitobject properties after loaded.")
	finisher = new_finisher
	length = new_length
	speed = new_speed
	timing = new_timing
	end_time = timing + length


## Check if this [HitObject] has been missed. Intended to be implemented by child classes.
## hit_time (float): The end of this [HitObject]'s hit window.
## return (bool): Whether or not to continue checking for misses.
func miss_check(_hit_time: float) -> bool:
	return false


## Apply a skin to this [HitObject]. Intended to be implemented by child classes.
## new_skin (SkinManager): The skin to apply.
func skin(_new_skin: SkinManager) -> void:
	pass
