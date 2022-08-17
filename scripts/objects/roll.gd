class_name Roll
extends HitObject

# Comment
var _cur_sv := 0.0

# Comment
var _tick_distance := 0.0

# Comment
var _total_ticks := 0

# Comment
onready var body := $Scale/Body as Control

# Comment
onready var tick_container := $TickContainer


func _ready() -> void:
	body.rect_size.x = speed * length

	# Comment
	for tick_idx in range(_total_ticks):

		# Comment
		var new_tick := $Tick.duplicate() as TextureRect

		tick_container.add_child(new_tick)
		new_tick.rect_position.x = tick_idx * _cur_sv * _tick_distance
		new_tick.show()


# Initialize `Roll` variables.
func change_properties(new_timing: float, new_speed: float, new_length: float, new_finisher: bool, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length, new_finisher)
	_cur_sv = new_speed / new_bpm / 4.2
	_tick_distance = 15000 / new_bpm
	_total_ticks = int(round(length * 10000 / _tick_distance) / 10) + 1


# See `HitObject`.
func miss_check(hit_time: float) -> int:
	if state == int(State.FINISHED):
		return Score.FINISHED

	if hit_time - length > timing:
		state = int(State.FINISHED)
		queue_free()
		return Score.ACCURATE

	return 0


# See `HitObject`.
func skin(new_skin: SkinManager) -> void:
	($Scale/Head as CanvasItem).self_modulate = new_skin.ROLL_COLOUR
	body.modulate = new_skin.ROLL_COLOUR
