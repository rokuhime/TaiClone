class_name HitObject
extends Control

const FINISHER_SCALE := 1.6
var is_finisher := false
@export var timing: float
@export var speed: float
var new_combo := false
enum HIT_RESULT {INVALID = -1, MISS, HIT, HIT_FINISHER, SPINNER_FINISH}
var active := true
var state: STATE

# TC3 CODE
## The possible states of a [HitObject]:
## 0: This [HitObject]'s properties can be changed.
## 1 (READY): This [HitObject] has been loaded into the scene. Its properties can no longer be changed.
## 2 (ACTIVE): This [HitObject] has been activated and can receive [method hit] and [method miss_check] calls.
## 3 (FINISHED): This [HitObject] has been fully hit or missed. It will be disposed of once all animations finish.
enum STATE {READY = 1, ACTIVE, FINISHED}

func hit_check(current_time: float, _input_side: Gameplay.SIDE, _is_input_kat: bool) -> HIT_RESULT:
	return HIT_RESULT.INVALID
func miss_check(hit_time: float) -> bool:
	return false

# TC3 CODE
## Sets this [HitObject] to the FINISHED [member State].
## type ([int]): The optional type of [member Score] to score. If -1, no score will be added.
## marker ([bool]): Whether or not a marker on the hit error bar should be added.
func finish(type := -1, marker := true) -> void:
	if state != int(STATE.FINISHED):
		state = int(STATE.FINISHED)
		queue_free()
		if type + 1:
			emit_signal("score_added", type, marker)

func apply_skin(skin_manager: SkinManager) -> void:
	pass
