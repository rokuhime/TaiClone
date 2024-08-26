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
var tick_texture: ImageTexture

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
	colour = skin.resources["colour"]["roll"]
	# textures go here!
	
	if skin.resources["texture"].keys().has("note"):
		texture = skin.resources["texture"]["note"]
	if skin.resources["texture"].keys().has("note_overlay"):
		$Overlay.texture = skin.resources["texture"]["note_overlay"]
	
	if skin.resources["texture"].keys().has("roll_tick"):
		tick_texture = skin.resources["texture"]["roll_tick"]
	if skin.resources["texture"].keys().has("roll_middle"):
		middle_node.texture = skin.resources["texture"]["roll_middle"]
	if skin.resources["texture"].keys().has("roll_end"):
		middle_node.get_node("End").texture = skin.resources["texture"]["roll_end"]
		
	update_visual()

func create_ticks() -> void:
	var tick_velocity = length * speed * Global.resolution_multiplier
	var tick_timing := 0.0
	
	await ready
	while tick_timing <= length:
		var new_tick: Control = tick_scene.instantiate()
		tick_container.add_child(new_tick)
		if tick_texture:
			new_tick.texture = tick_texture
		
		new_tick.position.x = (tick_timing / length) * middle_node.size.x
		tick_timing += tick_duration

func get_tick_idx(cur_time: float) -> int:
	return int(round( (cur_time - timing) / tick_duration ))

# roku note 2024-05-16
# feels weird as hell, it does take the closest timing but inputs can often get swallowed by nearby notes making it feel pretty blecky
# work on get_tick_idx to make it basically hone in on the closest NOT HIT tick maybe?
func hit_check(current_time: float, _input_side: Gameplay.SIDE, _is_input_kat: bool) -> HIT_RESULT:
	var tick_idx = clampi(get_tick_idx(current_time), 0, tick_container.get_child_count() - 1)
	
	# if were on the first tick and not within inacc timing, ignore
	if tick_idx == 0 and abs(timing - current_time) > Global.INACC_TIMING:
		return HIT_RESULT.INVALID
	# if were on the last tick and not within inacc timing, ignore
	elif tick_idx == tick_container.get_child_count() - 1 and abs((timing + length) - current_time) > Global.INACC_TIMING:
		return HIT_RESULT.INVALID
	
	# within bounds
	var tick = tick_container.get_child(tick_idx)
	if tick.visible:
		tick.visible = false
		return HIT_RESULT.TICK_HIT
	return HIT_RESULT.INVALID

func miss_check(hit_time: float) -> bool:
	return false
