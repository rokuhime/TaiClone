class_name HitErrorBar
extends Control

@onready var accurate_rect: ColorRect = $Accurate
@onready var point_container: Control = $PointContainer
@onready var average_marker: TextureRect = $AverageMarker
var average_marker_tween: Tween
const TIMING_MULTIPLIER := 10000

var point_width := 4
# allows point height to pass the height of the bar for viewing clarity
var point_height_boost := 20

var point_lifespan := 2
var max_points := 20
var current_point_index := 0
var point_tweens := []

# Called when the node enters the scene tree for the first time.
func _ready():
	point_tweens.resize(max_points)
	update_bar_size()

func update_bar_size():
	var inaccurate_size = Vector2(Global.INACC_TIMING * TIMING_MULTIPLIER, 25)
	var accurate_size = Vector2(Global.ACC_TIMING * TIMING_MULTIPLIER, 25)
	size = inaccurate_size
	accurate_rect.size = accurate_size
	
	# this will force it to be at the bottom unfortunately
	position.y = Global.get_root().size.y - size.y
	# center accurate_rect
	accurate_rect.set_position(Vector2((inaccurate_size.x - accurate_size.x) / 2.0, 0))

func add_point(hit_time: float):
	var new_point := ColorRect.new()
	point_container.add_child(new_point)
	new_point.size = Vector2(point_width, size.y + point_height_boost)
	
	# clamp hit time to ensure it stays within bounds
	var clamped_hittime = clampf(hit_time, -Global.INACC_TIMING, Global.INACC_TIMING)
	# remap the position to be the size of the hit error bar
	var point_posx = remap(clamped_hittime, -Global.INACC_TIMING, Global.INACC_TIMING, 
							0, point_container.size.x)
	new_point.position = Vector2(point_posx, -point_height_boost / 2)
	
	# delete previous point if we've looped back
	if point_container.get_child_count() >= max_points:
		point_container.get_child(current_point_index).queue_free()
	
	# kill existing tween if needed
	if point_tweens.size() - 1 >= current_point_index:
		if point_tweens[current_point_index]:
			point_tweens[current_point_index].kill()
	
	# modulate alpha of the point
	point_tweens[current_point_index] = create_tween()
	point_tweens[current_point_index].tween_property(new_point, "modulate:a", 0.0, point_lifespan)
	
	current_point_index = (current_point_index + 1) % max_points
	adjust_average_marker()

func adjust_average_marker() -> void:
	var point_posx_total := 0.0
	for point in point_container.get_children():
		point_posx_total += point.position.x
	
	if average_marker_tween:
		average_marker_tween.kill()
	average_marker_tween = Global.create_smooth_tween()
	average_marker_tween.tween_property(average_marker, "position:x", point_posx_total / point_container.get_child_count(), 0.5)
