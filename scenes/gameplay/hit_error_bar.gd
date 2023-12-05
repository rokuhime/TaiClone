class_name HitErrorBar
extends Control

@onready var accurate_rect: ColorRect = $Inaccurate/Accurate
@onready var point_container: Control = $PointContainer
const BASE_SIZE_MULTIPLIER := Vector2(10000, 50)
var point_lifespan := 1.0
var max_points := 20
var current_point_index := 0
var point_tweens := []

# Called when the node enters the scene tree for the first time.
func _ready():
	point_tweens.resize(max_points)
	update_size()

func update_size():
	var inaccurate_size = Vector2(Global.INACC_TIMING, 1) * BASE_SIZE_MULTIPLIER
	var accurate_size = Vector2(Global.ACC_TIMING, 1) * BASE_SIZE_MULTIPLIER
	size = inaccurate_size
	accurate_rect.size = accurate_size
	accurate_rect.set_position(Vector2((inaccurate_size.x - accurate_size.x) / 2, 0))

func add_point(hit_time: float):
	print("add_point #", current_point_index)
	var new_point := ColorRect.new()
	point_container.add_child(new_point)
	new_point.size = Vector2(2, size.y)
	new_point.position = Vector2(hit_time + point_container.size.x / 2, 0) * BASE_SIZE_MULTIPLIER
	
	# TODO: this is throwing a SHITTON of errors for some reason for oob
	if point_tweens[current_point_index] != null:
		point_tweens[current_point_index].kill()
		if point_container.get_child(current_point_index) != null:
			point_container.get_child(current_point_index).queue_free()
	
	point_tweens[current_point_index] = create_tween()
	point_tweens[current_point_index].tween_property(new_point, "modulate:a", 0.0, point_lifespan)
	point_tweens[current_point_index].finished.connect(new_point.queue_free)
	current_point_index = (current_point_index + 1) % max_points
	print("tweened and set current-point_index to ", current_point_index)
