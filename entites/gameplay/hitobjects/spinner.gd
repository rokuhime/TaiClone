# roku note 2024-08-19
# warn is not aligned
class_name Spinner
extends HitObject

# visual for the track
var warn_tween: Tween

# interactable element
@onready var spinner_gameplay := $SpinnerGameplay
var spinner_gameplay_tween: Tween
@onready var inside: TextureRect = $SpinnerGameplay/Inside # rotating middle
@onready var outside: TextureRect = $SpinnerGameplay/Outside # approach circle
@onready var hit_count_label := $SpinnerGameplay/NeededHits

enum hit_type { FINISHED = -3, INACTIVE = -2, ANY = -1, DON, KAT}
var hit_status := hit_type.INACTIVE

var length: float
var needed_hits := 50
var current_hits := 0
@onready var timer: Timer = $SpinnerGameplay/Timer

@export var inside_rotation_speed := 0.4
const ROTATE_SPEED_CAP := 0.4

signal on_finished

func _ready() -> void:
	reset()

func _process(delta) -> void:
	if hit_status < hit_type.ANY and active:
		return
	
	# scale timer outside if active
	var timer_percent := timer.time_left / timer.wait_time
	outside.scale = Vector2.ONE.lerp(Vector2(0.2,0.2), 1.0 - timer_percent)
	
	if inside_rotation_speed:
		# rotate gameplay visual
		inside.set_rotation_degrees(inside.rotation_degrees + inside_rotation_speed)
		# slow down rotation speed
		inside_rotation_speed = max(inside_rotation_speed - (delta * 0.3), 0.0)

func hit_check(_current_time: float, _input_side: Gameplay.SIDE, is_input_kat: bool) -> HIT_RESULT:
	if hit_status == int(is_input_kat) or hit_status == hit_type.ANY:
		current_hits -= 1
		hit_count_label.text = str(current_hits)
		inside_rotation_speed = min(inside_rotation_speed + 0.075, ROTATE_SPEED_CAP)
		
		if current_hits <= 0:
			finished()
			return HIT_RESULT.SPINNER_FINISH
		else:
			# alternate requested hit type, and report back that it was hit
			@warning_ignore("int_as_enum_without_cast")
			hit_status = int(not is_input_kat)
			return HIT_RESULT.TICK_HIT
	return HIT_RESULT.INVALID

func miss_check(_hit_time: float) -> bool:
	return false

func transition_to_playable() -> void:
	hit_status = hit_type.ANY

	# hide warn object
	warn_tween = create_tween()
	warn_tween.tween_property(self, "self_modulate:a", 0, 0.5)
	
	spinner_gameplay.visible = true
	spinner_gameplay_tween = create_tween()
	spinner_gameplay_tween.tween_property(spinner_gameplay, "modulate:a", 1, 0.2).from(0)
	
	timer.paused = false
	timer.start(length)

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

func reset() -> void:
	timer.stop()
	if spinner_gameplay.get_parent() != self:
		spinner_gameplay.get_parent().remove_child(spinner_gameplay)
		add_child(spinner_gameplay)
	spinner_gameplay.visible = false
	
	hit_status = hit_type.INACTIVE
	current_hits = needed_hits
	hit_count_label.text = str(current_hits)
	visible = true
	self_modulate.a = 1
	active = true

func apply_skin(skin: SkinManager) -> void:
	if skin.resource_exists("texture/spinner_warn"):
		texture = skin.resources["texture"]["spinner_warn"]
	if skin.resource_exists("texture/spinner_inside"):
		inside.texture = skin.resources["texture"]["spinner_inside"]
	if skin.resource_exists("texture/spinner_outside"):
		outside.texture = skin.resources["texture"]["spinner_outside"]
	
