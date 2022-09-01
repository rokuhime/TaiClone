class_name HitObject
extends KinematicBody2D

## Signals [Gameplay] when a hit sound should be played.
signal audio_played(key)

## Signals [Gameplay] when a score should be added.
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

## The time when this [HitObject] completes. It's used to sort [HitObject]s. Applies to all [HitObject]s.
var end_time := 0.0

## Whether or not this [HitObject] is a finisher. Only applies to [Note]s and [Roll]s.
var finisher := false

## The length of this [HitObject]. Only applies to [Roll]s, [Spinner]s, and [SpinnerWarn]s.
var length := 0.0

## The slider velocity of this [HitObject]. Applies to all [HitObject]s.
var speed := 0.0

## The [member State] of this [HitObject]. Applies to all [HitObject]s.
var state := 0

## The hit time of this [HitObject]. Applies to all [HitObject]s.
var timing := 0.0

onready var visibility_notifier := $VisibilityNotifier2D as VisibilityNotifier2D


func _ready() -> void:
	hide()
	Root.send_signal(self, "screen_entered", visibility_notifier, "show")
	Root.send_signal(self, "screen_exited", visibility_notifier, "hide")
	if finisher:
		(get_child(1) as Control).rect_scale *= 1.6
		visibility_notifier.scale *= 1.6

	add_to_group("HitObjects")
	state = int(State.READY)


## Enable motion and [method hit] and [method miss_check] calls on this [HitObject].
func activate() -> void:
	assert(state == int(State.READY), "Attempted to activate hitobject.")
	state = int(State.ACTIVE)


## Apply a skin to this [HitObject]. Intended to be implemented by child classes.
## new_skin (SkinManager): The skin to apply.
func apply_skin(_new_skin: SkinManager) -> void:
	pass


## Comment
func auto_hit(_hit_time: float, _hit_left: bool) -> int:
	return 0


## Perform a comprehensive check to see if this [HitObject] was correctly hit. Currently used by [Note]s and [Spinner]s.
## key ([String]): "Don" or "Kat"
## inputs ([Array]): The list of actions received.
## play_audio ([bool]): Whether or not to play the corresponding hit sound.
## return ([String]): The side hit. An empty string means this [HitObject] was not correctly hit.
func check_hit(key: String, inputs: Array, play_audio := true) -> String:
	## Whether or not this [HitObject] was hit on the left side.
	var left_hit := inputs.find("Left" + key)

	## Whether or not this [HitObject] was hit on the right side.
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


## Sets this [HitObject] to the FINISHED [member State].
## type ([int]): The optional type of [member Score] to score. If -1, no score will be added.
## marker ([bool]): Whether or not a marker on the hit error bar should be added.
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


## Comment
func move(cur_time: float) -> void:
	if state > int(State.READY):
		position.x = speed * (timing - cur_time)