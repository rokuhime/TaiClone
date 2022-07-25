class_name Roll
extends KinematicBody2D

var finisher := true
var timing := 0.0

var _active := false
var _length := 1.0
var _speed := 1.0

var _current_tick := 0
var _tick_distance := 0.0
var _total_ticks := 0

onready var _gameplay := $"../../../../.." as Gameplay
onready var _tick_container := $"TickContainer"


func _ready() -> void:
	var scale := $"Scale" as Control

	# finisher scale
	if finisher:
		scale.rect_scale = Vector2(0.9, 0.9)

	# note colour
	(scale.get_node("Head") as CanvasItem).self_modulate = _gameplay.skin.roll_colour

	var body := scale.get_node("Body") as Control
	body.modulate = _gameplay.skin.roll_colour
	body.rect_size = Vector2(_speed * _length, 129)

	# haha funny!!! idx like iidx as in funny beatmania silly game keys
	# but its a lot like INDEX!!!!!!!!!!!!!!!
	# GET IT
	for tick_idx in range(_total_ticks):
		# duplicate base tick and put it in the tick container
		var new_tick := $"Tick".duplicate() as TextureRect
		_tick_container.add_child(new_tick)
		_tick_container.move_child(new_tick, _tick_container.get_child_count())

		# the number of tick * tick distance * time signature * note speed / 1000 * time signature * 10
		#new_tick.rect_position = Vector2(tick_idx * _tick_distance * 4 * _speed / 1000 * 40, -64.5)
		new_tick.rect_position = Vector2(tick_idx * _tick_distance * _speed / 40, -64.5)


func _input(event: InputEvent) -> void:
	# lol
	if _total_ticks <= _current_tick or not _active or not not (event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftKat") or event.is_action_pressed("RightDon") or event.is_action_pressed("RightKat")):
		return

	var cur_song_time := _gameplay.music.get_playback_position()
	# if after slider is hittable
	if cur_song_time > timing + _length + _gameplay.hit_manager.inaccTiming:
		deactivate()
		return
	# if before slider is hittable
	if cur_song_time < timing - _gameplay.hit_manager.inaccTiming:
		return

	# get current tick target
	_current_tick = int(clamp((cur_song_time - timing) * _tick_distance * 4, 0, _total_ticks))

	_current_tick = int(min(_current_tick, _tick_container.get_child_count() - 1))
	var tick := _tick_container.get_child(_current_tick) as CanvasItem
	if tick.visible:
		print(_current_tick)
		tick.hide()
		_gameplay.hit_manager.addScore("roll")


func _process(_delta: float) -> void:
	if _active:
		var _vel := move_and_slide(Vector2(_speed * -1.9, 0))



func change_properties(new_timing: float, new_speed: float, new_length: float, new_finisher: bool, beat_length: float) -> void:
	if _active:
		push_warning("Attempted to change roll properties after active.")
		return
	finisher = new_finisher
	timing = new_timing
	_length = new_length
	_speed = new_speed

	_tick_distance = beat_length / 100

	# length of the roll divided by the distance between ticks
	# and multiplied by the frequency
	_total_ticks = int(_length / _tick_distance * 48)


func activate() -> void:
	if _active:
		push_warning("Attempted to activate roll after active.")
		return
	position = Vector2(_speed * timing, 0)
	for tick_idx in range(_tick_container.get_child_count()):
		var tick := _tick_container.get_child(tick_idx) as CanvasItem
		tick.show()
	_active = true


func deactivate() -> void:
	if not _active:
		push_warning("Attempted to deactivate roll before active.")
		return
	_active = false
