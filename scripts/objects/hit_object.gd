class_name HitObject
extends KinematicBody2D

enum State {READY = 1, ACTIVE, FINISHED}

var length := 1.0
var speed := 1.0
var state := 0
var timing := 0.0

var _finisher := false


func _ready() -> void:
	# finisher scale
	if _finisher:
		(get_child(0) as Control).rect_scale = Vector2(0.9, 0.9)
	state = int(State.READY)


func _process(_delta: float) -> void:
	# move note if not hit yet
	if state == int(State.ACTIVE):
		var _vel := move_and_slide(Vector2(speed * -1.9, 0))


func activate() -> void:
	if state != int(State.READY):
		push_warning("Attempted to activate hitobject.")
		return
	modulate = Color.white
	position = Vector2(speed * timing, 0)
	state = int(State.ACTIVE)


func hit(inputs: Array, _hit_time: float) -> Array:
	return inputs


func ini(new_timing: float, new_speed: float, new_length: float, new_finisher := false) -> void:
	if state:
		push_warning("Attempted to change hitobject properties after loaded.")
		return
	length = new_length
	speed = new_speed
	timing = new_timing
	_finisher = new_finisher


func miss_check(hit_time: float) -> String:
	if state == int(State.FINISHED):
		return "finished"
	if hit_time > timing:
		queue_free()
		return "miss"
	return ""


func skin(_new_skin: SkinManager) -> void:
	pass
