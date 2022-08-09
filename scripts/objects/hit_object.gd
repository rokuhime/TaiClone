class_name HitObject
extends KinematicBody2D

var finisher := false
var timing := 0.0

var _active := false
var _length := 1.0
var _loaded := false
var _speed := 1.0

onready var _g := $"/root/Gameplay" as Gameplay


func _ready() -> void:
	# finisher scale
	if finisher:
		(get_child(0) as Control).rect_scale = Vector2(0.9, 0.9)
	_loaded = true


func _process(_delta: float) -> void:
	# move note if not hit yet
	if _active:
		var _vel := move_and_slide(Vector2(_speed * -1.9, 0))


func activate() -> void:
	if _active or not _loaded:
		push_warning("Attempted to activate hitobject.")
		return
	modulate = Color.white
	position = Vector2(_speed * timing, 0)
	_active = true


func deactivate() -> void:
	if not _active or not _loaded:
		push_warning("Attempted to deactivate hitobject.")
	modulate = Color.transparent
	_active = false


func ini(new_timing: float, new_speed: float, new_length: float, new_finisher := false) -> void:
	if _loaded:
		push_warning("Attempted to change hitobject properties after loaded.")
		return
	finisher = new_finisher
	timing = new_timing
	_length = new_length
	_speed = new_speed
