class_name Note
extends KinematicBody2D

var finisher := true
var is_kat := false
var timing := 0.0

var _active := false
var _skin := SkinManager.new()
var _speed := 1.0


func _ready() -> void:
	var sprite := $"Sprite" as TextureRect

	# finisher scale
	if finisher:
		sprite.rect_scale = Vector2(0.9, 0.9)

	# note colour
	sprite.self_modulate = _skin.kat_colour if is_kat else _skin.don_colour


func _process(_delta: float) -> void:
	# move note if not hit yet
	if _active:
		var _vel := move_and_slide(Vector2(_speed * -1.9, 0))


func change_properties(new_timing: float, new_speed: float, new_skin: SkinManager, new_is_kat: bool, new_finisher: bool) -> void:
	if _active:
		push_warning("Attempted to change note properties after active.")
		return
	finisher = new_finisher
	is_kat = new_is_kat
	timing = new_timing
	_skin = new_skin
	_speed = new_speed


func activate() -> void:
	if _active:
		push_warning("Attempted to activate after active.")
		return
	modulate = Color.white
	position = Vector2(_speed * timing, 0)
	_active = true


func deactivate() -> void:
	if not _active:
		push_warning("Attempted to deactivate before active.")
		return
	modulate = Color.transparent
	_active = false
