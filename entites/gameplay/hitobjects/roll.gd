# roku note 2024-05-15
# was thinking about length/tick distance, if were adding piu sv that needs to be able to change dynamically
# look into a nice solution for this

class_name Roll
extends HitObject

@onready var middle_node := $Middle as Control
var length: float
var tick_duration: float

@onready var tick_container: Control = $Ticks
var tick_scene := load("res://entites/gameplay/hitobjects/roll_tick.tscn")

var colour := Color("FCB806")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_visual()

func update_visual() -> void:
	self_modulate = colour
	middle_node.modulate = colour # will make end node coloured too
	
	var body_length : float = length * speed * Global.resolution_multiplier
	
	if is_finisher:
		scale = Vector2.ONE * FINISHER_SCALE
		body_length /= FINISHER_SCALE
	
	middle_node.size.x = body_length

func apply_skin(skin: SkinManager) -> void:
	colour = skin.roll_colour
	# textures go here!
	update_visual()

func create_ticks() -> void:
	var tick_count = int(ceil(length / tick_duration)) + 1
	# tick distance = body length / tick count - 1 to ensure the first tick is on 0, and the last tick is on the body's end
	var tick_distance = length * speed * Global.resolution_multiplier / (tick_count - 1)
	
	await ready
	for tick_idx in tick_count:
		var new_tick: Control = tick_scene.instantiate()
		tick_container.add_child(new_tick)
		
		new_tick.position.x = tick_idx * tick_distance

func get_tick_idx(cur_time: float) -> int:
	return int(round( (cur_time - timing) / tick_duration ))

# roku note 2024-05-16
# feels weird as hell, it does take the closest timing but inputs can often get swallowed by nearby notes making it feel pretty blecky
# work on get_tick_idx to make it basically hone in on the closest NOT HIT tick maybe?
func hit_check(current_time: float, _input_side: Gameplay.SIDE, _is_input_kat: bool) -> HIT_RESULT:
	var tick_idx = clampi(get_tick_idx(current_time), 0, tick_container.get_child_count() - 1)
	var tick = tick_container.get_child(tick_idx)
	if tick.visible:
		tick.visible = false
		return HIT_RESULT.HIT
	return HIT_RESULT.INVALID

func miss_check(hit_time: float) -> bool:
	return false
