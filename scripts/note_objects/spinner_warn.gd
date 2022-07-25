class_name SpinnerWarn
extends KinematicBody2D

var timing := 0.0

var _active := false
var _bpm := 1.0
var _length := 1.0
var _speed := 1.0

onready var _gameplay := $"../../../../.." as Gameplay
onready var _spinner_obj := preload("res://game/objects/spinner_object.tscn")


func _process(_delta: float) -> void:
	# move note if not hit yet
	if _active:
		var _vel := move_and_slide(Vector2(_speed * -1.9, 0))
		if _gameplay.music.get_playback_position() >= timing:
			deactivate()


func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	if _active:
		push_warning("Attempted to change spinner warning properties after active.")
		return
	timing = new_timing
	_bpm = new_bpm
	_length = new_length
	_speed = new_speed


func activate() -> void:
	if _active:
		push_warning("Attempted to activate spinner warning after active.")
		return
	modulate = Color.white
	position = Vector2(_speed * timing, 0)
	_active = true


func deactivate() -> void:
	if not _active:
		push_warning("Attempted to deactivate spinner warning before active.")
		return

	# make spinner obj first
	var spinner := _spinner_obj.instance() as Spinner
	spinner.change_properties(timing, _length, int(_length * 960 / _bpm))
	get_parent().add_child(spinner)
	get_parent().move_child(spinner, 0)

	# make self deactive (duh!)
	modulate = Color.transparent
	_active = false
