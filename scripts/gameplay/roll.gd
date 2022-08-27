class_name Roll
extends HitObject

## The distance between ticks in this [Roll].
var _tick_distance := 0.0

## The number of ticks in this [Roll].
var _total_ticks := 0

onready var body := $Body as Control
onready var head := $Head as CanvasItem
onready var tick_container := $TickContainer


func _ready() -> void:
	body.rect_size.x = speed * length
	for tick_idx in range(_total_ticks):
		## The tick object to spawn.
		var new_tick := preload("res://scenes/gameplay/tick.tscn").instance() as Tick

		new_tick.change_properties(tick_idx * _tick_distance * speed)
		tick_container.add_child(new_tick)
		tick_container.move_child(new_tick, 0)


## Initialize [Roll] variables.
func change_properties(new_timing: float, new_speed: float, new_length: float, new_finisher: bool, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length, new_finisher)
	_tick_distance = 15 / new_bpm
	_total_ticks = int(round(length * 10 / _tick_distance) / 10) + 1


## See [HitObject].
func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED

	if hit_time - length > timing:
		state = int(State.FINISHED)
		queue_free()
		return Score.ACCURATE

	return 0


## See [HitObject].
func skin(new_skin: SkinManager) -> void:
	head.self_modulate = new_skin.roll_color
	body.modulate = new_skin.roll_color
