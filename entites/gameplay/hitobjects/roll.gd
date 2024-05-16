# roku note 2024-05-15
# was thinking about length/tick distance, if were adding piu sv that needs to be able to change dynamically
# look into a nice solution for this

class_name Roll
extends HitObject

@onready var middle_node := $Middle as Control
var length: float

@onready var tick_container: Control = $Ticks
var tick_scene := load("res://entites/gameplay/hitobjects/roll_tick.tscn")
var ticks := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self_modulate = Color("FCB806")
	middle_node.modulate = Color("FCB806") # will make end node coloured too
	
	var body_length : float = length * speed * Global.resolution_multiplier
	
	if is_finisher:
		scale = Vector2.ONE * FINISHER_SCALE
		body_length /= FINISHER_SCALE
	
	middle_node.size.x = body_length

func create_ticks(bpm: float) -> void:
	var beat_length = 60.0 / bpm
	var quarter_beat_length = beat_length / 4.0
	var tick_count = int(ceil(length / quarter_beat_length)) + 1
	# tick distance = body length / tick count - 1 to ensure the first tick is on 0, and the last tick is on the body's end
	var tick_distance = length * speed * Global.resolution_multiplier / (tick_count - 1)
	
	await ready
	for tick_idx in tick_count:
		var new_tick: Control = tick_scene.instantiate()
		tick_container.add_child(new_tick)
		
		new_tick.position.x = tick_idx * tick_distance
