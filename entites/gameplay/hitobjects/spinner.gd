class_name Spinner
extends HitObject

var rhythm_inputs := [ "LeftKat", "LeftDon", "RightDon", "RightKat" ]

@onready var spinner_warn := $SpinnerWarn
@onready var inside := $SpinnerGameplay/Inside
@onready var outside := $SpinnerGameplay/Outside
@onready var needed_hit_label := $SpinnerGameplay/NeededHits

var spinner_warn_tween: Tween  # for alpha fade
var outside_tween: Tween  # for outside scale

enum hit_type { FINISHED = -2, INACTIVE = -1, ANY, DON, KAT}
var hit_status := hit_type.INACTIVE
var length: float
var needed_hits := 50

@export var inside_rotation_speed := 0.0

func transition_to_playable() -> void:
	hit_status = hit_type.ANY
	
	spinner_warn_tween = create_tween()
	spinner_warn_tween.tween_property(spinner_warn, "self_modulate", Color(1,1,1,0), 0.5)
	
	outside_tween = create_tween()
	outside_tween.tween_property(outside, "size", Vector2.ONE * 0.1, length)

func _ready() -> void:
	needed_hit_label.text = str(needed_hits)

func _process(delta) -> void:
	if inside_rotation_speed > 0:
		inside_rotation_speed -= delta * 0.25
		inside.rotation += inside_rotation_speed

func finished() -> void:
	hit_status = hit_type.FINISHED
	await get_tree().create_timer(1).timeout
	# kill self

func hit_check(current_time: float, _input_side: Gameplay.SIDE, is_input_kat: bool) -> HIT_RESULT:
	if hit_status == int(is_input_kat) or hit_status == hit_type.ANY:
		needed_hits -= 1
		needed_hit_label.text = str(needed_hits)
		inside_rotation_speed = min(inside_rotation_speed + 0.05, 0.3)
		
		if needed_hits <= 0:
			finished()
			return HIT_RESULT.SPINNER_FINISH
		else:
			return HIT_RESULT.HIT
	return HIT_RESULT.INVALID
