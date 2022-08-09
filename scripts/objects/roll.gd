class_name Roll
extends HitObject

var _current_tick := 0
var _tick_distance := 0.0
var _total_ticks := 0

onready var _tick_container := $"TickContainer"


func _ready() -> void:
	# note colour
	($"Scale/Head" as CanvasItem).self_modulate = _g.skin.roll_colour
	var body := $"Scale/Body" as Control
	body.modulate = _g.skin.roll_colour
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
	if _total_ticks <= _current_tick or not _active or not _loaded or not not (event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftKat") or event.is_action_pressed("RightDon") or event.is_action_pressed("RightKat")):
		return

	var cur_song_time := _g.music.get_playback_position()
	# if after slider is hittable
	if cur_song_time > timing + _length + _g.inacc_timing:
		deactivate()
		return
	# if before slider is hittable
	if cur_song_time < timing - _g.inacc_timing:
		return

	# get current tick target
	_current_tick = int(clamp((cur_song_time - timing) * _tick_distance * 4, 0, _total_ticks))

	_current_tick = int(min(_current_tick, _tick_container.get_child_count() - 1))
	var tick := _tick_container.get_child(_current_tick) as CanvasItem
	if tick.visible:
		print(_current_tick)
		tick.hide()
		_g.hit_manager.addScore("roll")


func change_properties(new_timing: float, new_speed: float, new_length: float, new_finisher: bool, beat_length: float) -> void:
	.ini(new_timing, new_speed, new_length, new_finisher)
	if _loaded:
		return

	_tick_distance = beat_length / 100

	# length of the roll divided by the distance between ticks
	# and multiplied by the frequency
	_total_ticks = int(_length / _tick_distance * 48)


func activate() -> void:
	for tick_idx in range(_tick_container.get_child_count()):
		(_tick_container.get_child(tick_idx) as CanvasItem).show()
	.activate()
