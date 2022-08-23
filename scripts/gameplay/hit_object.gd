class_name HitObject
extends KinematicBody2D

## The possible scores of a [HitObject]:
## 0: It is too early to hit this [HitObject]. Does not affect score or accuracy. Applies to all [HitObject]s.
## 1 (ACCURATE): 300 points and 100% accuracy. Applies to all [HitObject]s.
## 2 (INACCURATE): 150 points and 50% accuracy. Applies to all [HitObject]s.
## 3 (MISS): 0 points and 0% accuracy. Applies to all [HitObject]s.
## 4 (FINISHER): 300 additional points. Does not affect accuracy. Only applies to [Note]s.
## 5 (ROLL): 300 points. Does not affect accuracy. Only applies to [Roll]s.
## 6 (SPINNER): 600 points. Does not affect accuracy. Only applies to [Spinner]s.
## 7 (FINISHED): This [HitObject] is in the FINISHED [member State]. Does not affect score or accuracy. Applies to all [HitObject]s.
enum Score {ACCURATE = 1, INACCURATE, MISS, FINISHER, ROLL, SPINNER, FINISHED}

## The possible states of a [HitObject]:
## 0: This [HitObject]'s properties can be changed.
## 1 (READY): This [HitObject] has been loaded into the scene. Its properties can no longer be changed.
## 2 (ACTIVE): This [HitObject] has been activated and can receive [method hit] and [method miss_check] calls.
## 3 (FINISHED): This [HitObject] has been fully hit or missed. It will be disposed of once all animations finish.
enum State {READY = 1, ACTIVE, FINISHED}

## The length of this [HitObject]. This does not apply to [BarLine]s and [Note]s.
var length := 0.0

## The slider velocity of this [HitObject]. Applies to all [HitObject]s.
var speed := 0.0

## The [member State] of this [HitObject]. Applies to all [HitObject]s.
var state := 0

## The hit time of this [HitObject]. Applies to all [HitObject]s.
var timing := 0.0

## Whether or not this [HitObject] is a finisher. Only applies to [Note]s and [Roll]s.
var _finisher := false


func _ready() -> void:
	if _finisher:
		(get_child(0) as Control).rect_scale = Vector2(0.9, 0.9)

	state = int(State.READY)


func _process(_delta: float) -> void:
	if state == int(State.ACTIVE):
		## The distance the [HitObject] moved.
		var _vel := move_and_slide(Vector2(-speed, 0))


## Enable motion and [method hit] and [method miss_check] calls on this [HitObject].
func activate() -> void:
	assert(state == int(State.READY), "Attempted to activate hitobject.")
	# TODO: Remove 1.9 scaling
	position.x = speed * timing / 1.9
	state = int(State.ACTIVE)


## Check if this [HitObject] has been hit. Intended to be implemented by child classes.
## inputs (Array): The list of actions received.
## hit_time (float): The start of this [HitObject]'s hit window.
## return (Array): The list of actions remaining and [member Score]s to add.
func hit(inputs: Array, _hit_time: float) -> Array:
	return inputs


## Initialize base [HitObject] variables. Called and extended by child classes via [method change_properties].
func ini(new_timing: float, new_speed: float, new_length: float, new_finisher := false) -> void:
	assert(not state, "Attempted to change hitobject properties after loaded.")
	_finisher = new_finisher
	length = new_length
	# TODO: Remove 1.9 scaling
	speed = new_speed * 1.9
	timing = new_timing


## Check if this [HitObject] has been missed. It can be implemented by child classes to extend functionality.
## hit_time (float): The end of this [HitObject]'s hit window.
## return (String): The [member Score] to add.
func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED

	if hit_time > timing:
		queue_free()
		return Score.MISS

	return 0


## Apply a skin to this [HitObject]. Intended to be implemented by child classes.
## new_skin (SkinManager): The skin to apply.
func skin(_new_skin: SkinManager) -> void:
	pass
