class_name Spinner
extends HitObject

var rhythm_inputs := [ "LeftKat", "LeftDon", "RightDon", "RightKat" ]

@onready var spinner_warn := $SpinnerWarn

@onready var spinner_gameplay := $SpinnerGameplay
@onready var inside := $SpinnerGameplay/Inside
@onready var outside := $SpinnerGameplay/Outside
@onready var hit_count_label := $SpinnerGameplay/NeededHits

var spinner_warn_tween: Tween  # for alpha fade
var last_gameplay_position := Vector2.ZERO

enum hit_type { FINISHED = -3, INACTIVE = -2, ANY = -1, DON, KAT}
var hit_status := hit_type.INACTIVE
var length: float
var needed_hits := 50
var current_hits := 0

@export var inside_rotation_speed := 0.0

signal on_finished

func _ready() -> void:
	current_hits = needed_hits
	hit_count_label.text = str(current_hits)

func _process(delta) -> void:
	if hit_status > hit_type.INACTIVE:
		spinner_gameplay.set_global_position(last_gameplay_position)
	
	if inside_rotation_speed > 0:
		inside_rotation_speed -= delta * 0.25
		inside.rotation += inside_rotation_speed

func hit_check(current_time: float, _input_side: Gameplay.SIDE, is_input_kat: bool) -> HIT_RESULT:
	if hit_status == int(is_input_kat) or hit_status == hit_type.ANY:
		current_hits -= 1
		hit_count_label.text = str(current_hits)
		inside_rotation_speed = min(inside_rotation_speed + 0.05, 0.3)
		
		if current_hits <= 0:
			finished()
			return HIT_RESULT.SPINNER_FINISH
		else:
			# alternate requested hit type, and report back that it was hit
			hit_status = int(not is_input_kat)
			return HIT_RESULT.HIT
	return HIT_RESULT.INVALID

func miss_check(hit_time: float) -> bool:
	if timing <= hit_time and hit_status == hit_type.INACTIVE:
		last_gameplay_position = spinner_gameplay.global_position
		transition_to_playable()
	return false

func transition_to_playable() -> void:
	hit_status = hit_type.ANY
	
	# this is stupid, dont do it like this
	spinner_warn_tween = create_tween()
	spinner_warn_tween.tween_property(spinner_warn, "self_modulate", Color(1,1,1,0), 0.5)
	
	var tween = create_tween()
	tween.tween_property(get_node("SpinnerGameplay"), "modulate", Color(1,1,1,1), 0.2)
	
	var outside_pos_tween = create_tween()
	outside_pos_tween.tween_property(outside, "position", size / 2, length)
	var outside_size_tween = create_tween()
	outside_size_tween.tween_property(outside, "size", Vector2.ONE * 0.1, length)
	outside_size_tween.finished.connect(Callable(finished))

func finished() -> void:
	if hit_status == hit_type.FINISHED:
		return
	
	hit_status = hit_type.FINISHED
	print("spinner finished, ", needed_hits - current_hits, " / ", needed_hits, " = ", float(needed_hits - current_hits) / float(needed_hits))
	if current_hits:
		if float(needed_hits - current_hits) / float(needed_hits) >= 0.5: # half finished
			# roku note 2024-07-02
			# calling from tree here means multiplayer wouldnt work
			# TODO: change this into a signal to connect to ScoreManager via Gameplay
			on_finished.emit(1)
		else:# less than half finished (miss)
			on_finished.emit(0)
	else: # finished
		on_finished.emit(2)
	
	# kill self
	var alpha_tween = create_tween()
	alpha_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await get_tree().create_timer(1).timeout
	active = false
