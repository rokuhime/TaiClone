# roku note 2024-08-19
# warn is not aligned
class_name Spinner
extends HitObject

# visual for the track
var warn_tween: Tween

# interactable element
@onready var spinner_gameplay := $SpinnerGameplay
var spinner_gameplay_tween: Tween

@onready var inside := $SpinnerGameplay/Inside # rotating middle
@onready var outside := $SpinnerGameplay/Outside # approach circle
@onready var hit_count_label := $SpinnerGameplay/NeededHits

enum hit_type { FINISHED = -3, INACTIVE = -2, ANY = -1, DON, KAT}
var hit_status := hit_type.INACTIVE

var length: float
var needed_hits := 50
var current_hits := 0

@export var inside_rotation_speed := 0.4
const ROTATE_SPEED_CAP := 0.4

signal on_finished

func _ready() -> void:
	current_hits = needed_hits
	hit_count_label.text = str(current_hits)
	spinner_gameplay.visible = false

func _process(delta) -> void:
	if inside_rotation_speed:
		# rotate gameplay visual
		inside.set_rotation_degrees(inside.rotation_degrees + inside_rotation_speed)
		# slow down rotation speed
		inside_rotation_speed = max(inside_rotation_speed - (delta * 0.3), 0.0)

func hit_check(current_time: float, _input_side: Gameplay.SIDE, is_input_kat: bool) -> HIT_RESULT:
	if hit_status == int(is_input_kat) or hit_status == hit_type.ANY:
		current_hits -= 1
		hit_count_label.text = str(current_hits)
		inside_rotation_speed = min(inside_rotation_speed + 0.075, ROTATE_SPEED_CAP)
		
		if current_hits <= 0:
			finished()
			return HIT_RESULT.SPINNER_FINISH
		else:
			# alternate requested hit type, and report back that it was hit
			hit_status = int(not is_input_kat)
			return HIT_RESULT.TICK_HIT
	return HIT_RESULT.INVALID

func miss_check(hit_time: float) -> bool:
	return false

func transition_to_playable() -> void:
	hit_status = hit_type.ANY

	# hide warn object
	warn_tween = create_tween()
	warn_tween.tween_property(self, "self_modulate:a", 0, 0.5)
	
	spinner_gameplay.visible = true
	spinner_gameplay_tween = create_tween()
	spinner_gameplay_tween.tween_property(spinner_gameplay, "modulate:a", 1, 0.2).from(0)
	
	var outside_pos_tween = create_tween()
	outside_pos_tween.tween_property(outside, "position", size / 2, length)
	var outside_size_tween = create_tween()
	outside_size_tween.tween_property(outside, "size", Vector2.ONE * 0.1, length)
	
	# connect the end of the spinner to the finished function
	outside_size_tween.finished.connect(finished)

func finished() -> void:
	if hit_status == hit_type.FINISHED:
		return
	
	hit_status = hit_type.FINISHED
	active = false
	print("spinner finished, ", needed_hits - current_hits, " / ", needed_hits, " = ", float(needed_hits - current_hits) / float(needed_hits))
	
	# emit on_finished with judgement
	if current_hits:
		if float(needed_hits - current_hits) / float(needed_hits) >= 0.5: # half finished
			on_finished.emit(self, HIT_RESULT.INACC)
		else:# less than half finished (miss)
			on_finished.emit(self, HIT_RESULT.MISS)
	else: # finished
		on_finished.emit(self, HIT_RESULT.ACC) # this is showing a miss but doing it correctly?
	
	# change visual for the spinner_gameplay
	if spinner_gameplay_tween:
		spinner_gameplay_tween.kill()
	spinner_gameplay_tween = Global.create_smooth_tween(spinner_gameplay, "modulate:a", 0.0, 0.2)
	
	await spinner_gameplay_tween.finished
	visible = false
	# reduce clutter in tree; reclaim the spinner gameplay visual
	spinner_gameplay.get_parent().remove_child(spinner_gameplay)
	add_child(spinner_gameplay)
