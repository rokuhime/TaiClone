class_name Roll
extends HitObject

## The distance between [Tick]s in this [Roll].
var _tick_distance := 0.0

## The number of [Tick]s in this [Roll].
var _total_ticks := 0

onready var end := $Middle/End as TextureRect
onready var middle := $Middle as TextureRect
onready var overlay := $Overlay as TextureRect
#onready var tick_container := $TickContainer


func _ready() -> void:
	rect_size.x = speed * length

	if finisher:
		middle.rect_position.y *= FINISHER_SCALE
		middle.rect_size.y *= FINISHER_SCALE
		end.rect_size.x *= FINISHER_SCALE
		rect_position *= FINISHER_SCALE
		rect_size *= FINISHER_SCALE

	for tick_idx in range(_total_ticks):
		## The [Tick] object to spawn.
		pass
		# var new_tick := root_viewport.tick_object.instance() as Tick

		# new_tick.change_properties(tick_idx * _tick_distance * speed)
		# tick_container.add_child(new_tick)
		# tick_container.move_child(new_tick, 0)


## See [HitObject].
func apply_skin() -> void:
	middle.self_modulate = root_viewport.skin.roll_color
	#middle.texture = root_viewport.skin.roll_middle
	end.self_modulate = root_viewport.skin.roll_color
	#end.texture = root_viewport.skin.roll_end
	self_modulate = root_viewport.skin.roll_color
	#head.texture = root_viewport.skin.big_circle if finisher else root_viewport.skin.hit_circle
	#overlay.texture = root_viewport.skin.big_circle_overlay if finisher else root_viewport.skin.hit_circle_overlay


## See [HitObject].
func auto_hit(hit_time: float, hit_left: bool) -> int:
	#if tick_container.get_child_count():
	#	return (tick_container.get_child(tick_container.get_child_count() - 1) as Tick).auto_hit((hit_time - timing) * speed, hit_left)

	return 0


## Initialize [Roll] variables.
func change_properties(new_timing: float, new_speed: float, new_length: float, new_finisher: bool, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length, new_finisher)
	_tick_distance = 15 / new_bpm
	_total_ticks = int(round(length * 10 / _tick_distance) / 10) + 1


## See [HitObject].
func hit(inputs: Array, hit_time: float) -> bool:
	#for tick_idx in range(tick_container.get_child_count() - 1, -1, -1):
	#	if (tick_container.get_child(tick_idx) as Tick).hit(inputs, (hit_time - timing + _tick_distance / 2) * speed) or GlobalTools.inputs_empty(inputs):
	#		break

	return false


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time > end_time:
		state = int(State.FINISHED)
		if not visible:
			queue_free()

	#for tick_idx in range(tick_container.get_child_count() - 1, -1, -1):
	#	if (tick_container.get_child(tick_idx) as Tick).miss_check((hit_time - timing - _tick_distance / 2) * speed):
	#		return true

	return false
