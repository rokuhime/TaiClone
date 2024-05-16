class_name HitObject
extends Control

const FINISHER_SCALE := 1.6
var is_finisher := false
@export var timing: float
@export var speed: float
var new_combo := false
enum HIT_RESULT {INVALID = -1, MISS, HIT, HIT_FINISHER}

# roku note 2024-05-16
# all hitobjects require a hit_check() and miss_check()
# not included here because of function signature dumbness
