class_name Note
extends KinematicBody2D

var finisher := true
var is_kat := false
var timing := 0.0

var _active := false
var _speed := 1.0

onready var _gameplay := $"../../../../.." as Gameplay


func _ready() -> void:
	var sprite := $"Sprite" as TextureRect

	# finisher scale
	if finisher:
		sprite.rect_scale = Vector2(0.9, 0.9)

	# note colour
	sprite.self_modulate = _gameplay.skin.kat_colour if is_kat else _gameplay.skin.don_colour


func _process(_delta: float) -> void:
	# move note if not hit yet
	if _active:
		var _vel := move_and_slide(Vector2(_speed * -1.9, 0))


func change_properties(new_timing: float, new_speed: float, new_is_kat: bool, new_finisher: bool) -> void:
	if _active:
		push_warning("Attempted to change note properties after active.")
		return
	finisher = new_finisher
	is_kat = new_is_kat
	timing = new_timing
	_speed = new_speed


func activate() -> void:
	if _active:
		push_warning("Attempted to activate note after active.")
		return
	modulate = Color.white
	position = Vector2(_speed * timing, 0)
	_active = true


func deactivate() -> void:
	if not _active:
		push_warning("Attempted to deactivate note before active.")
		return
	modulate = Color.transparent
	_active = false
