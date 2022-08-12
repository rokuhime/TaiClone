class_name HitObject
extends KinematicBody2D

var _active := false
var _finished := false
var _finisher := false
var _length := 1.0
var _loaded := false
var _speed := 1.0
var _timing := 0.0


func _ready() -> void:
	# finisher scale
	if _finisher:
		(get_child(0) as Control).rect_scale = Vector2(0.9, 0.9)
	_loaded = true


func _process(_delta: float) -> void:
	# move note if not hit yet
	if _active:
		var _vel := move_and_slide(Vector2(_speed * -1.9, 0))


func activate() -> void:
	if _active or _finished or not _loaded:
		push_warning("Attempted to activate hitobject.")
		return
	modulate = Color.white
	position = Vector2(_speed * _timing, 0)
	_active = true


func hit(inputs: Array, _hit_time: float) -> Array:
	return inputs


func ini(new_timing: float, new_speed: float, new_length: float, new_finisher := false) -> void:
	if _loaded:
		push_warning("Attempted to change hitobject properties after loaded.")
		return
	_finisher = new_finisher
	_length = new_length
	_speed = new_speed
	_timing = new_timing


func miss_check(hit_time: float) -> String:
	if _finished:
		return "finished"
	if hit_time > _timing:
		queue_free()
		return "miss"
	return ""


func skin(_new_skin: SkinManager) -> void:
	pass
