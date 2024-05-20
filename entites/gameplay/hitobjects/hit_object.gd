class_name HitObject
extends Control

const FINISHER_SCALE := 1.6
var is_finisher := false
@export var timing: float
@export var speed: float
var new_combo := false
enum HIT_RESULT {INVALID = -1, MISS, HIT, HIT_FINISHER, SPINNER_FINISH}

func hit_check(current_time: float, _input_side: Gameplay.SIDE, _is_input_kat: bool) -> HIT_RESULT:
	return HIT_RESULT.INVALID
func miss_check():
	return
