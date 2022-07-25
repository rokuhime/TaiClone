class_name Spinner
extends CanvasItem

var timing := 0.0

var _cur_hit_count := 0
var _current_speed := 0.0
var _finished := false
var _first_hit_is_kat := false
var _length := 1.0
var _loaded := false
var _needed_hits := 0

onready var _count_text := $"Label" as Label
onready var _gameplay := $"../../../../.." as Gameplay
onready var _spin_circ_rot := $"RotationObj" as Node2D
onready var _tween := $"Tween" as Tween


func _input(event: InputEvent) -> void:
	if _needed_hits <= _cur_hit_count or not _loaded:
		return
	var is_kat := event.is_action_pressed("LeftKat") or event.is_action_pressed("RightKat")
	if _cur_hit_count == 0:
		_first_hit_is_kat = is_kat
	else:
		var next_hit_is_kat := _cur_hit_count % 2 != int(_first_hit_is_kat)
		if (not next_hit_is_kat and not (event.is_action_pressed("LeftDon") or event.is_action_pressed("RightDon"))) or (next_hit_is_kat and not is_kat):
			return

	# hit_success function
	_cur_hit_count += 1
	_count_text.text = str(_needed_hits - _cur_hit_count)
	_gameplay.hit_manager.addScore("spinner")

	if not _tween.interpolate_property(self, "_current_speed", 3, 0, 1, Tween.TRANS_CIRC, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner speed.")
	if not _tween.start():
		push_warning("Attempted to start spinner speed tween.")


func _ready() -> void:
	# set counter text to say how many hits are needed
	_count_text.text = str(_needed_hits)

	# make approach circle shrink
	if not _tween.interpolate_property($"Approach" as Control, "rect_scale", Vector2(1, 1), Vector2(0.1, 0.1), _length, Tween.TRANS_LINEAR, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner approach.")

	# make spinner fade in
	if not _tween.interpolate_property(self, "modulate", Color.transparent, Color.white, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner fade in.")

	if not _tween.start():
		push_warning("Attempted to start spinner tweens.")
	_loaded = true


func _process(_delta: float) -> void:
	if not _loaded:
		return
	_spin_circ_rot.rotation_degrees += _current_speed
	if _finished or (_cur_hit_count < _needed_hits and _gameplay.music.get_playback_position() <= (timing + _length)):
		return
	_finished = true

	# spinner_finished function
	_gameplay.hit_manager.addScore("accurate" if _needed_hits <= _cur_hit_count else "inaccurate" if _needed_hits / 2.0 <= _cur_hit_count else "miss")

	# make spinner fade out
	if not _tween.interpolate_property(self, "modulate", Color.white, Color.transparent, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT):
		push_warning("Attempted to tween spinner fade out.")
	var _connect := _tween.connect("tween_completed", self, "delete_self")
	if not _tween.start():
		push_warning("Attempted to start spinner fade out tween.")


func change_properties(new_timing: float, new_length: float, new_hits: int) -> void:
	if _loaded:
		push_warning("Attempted to change spinner properties after loaded.")
		return
	timing = new_timing
	_length = new_length
	_needed_hits = new_hits


func activate() -> void:
	delete_self()


func deactivate() -> void:
	delete_self()


func delete_self() -> void:
	queue_free()
