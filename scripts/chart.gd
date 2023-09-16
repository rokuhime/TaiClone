## dummy class to hold a chart's data
class_name Chart

var audio
var background

var chart_info := {}

var timing_points := []
var hit_objects := []

func _init(aud, bg, c_info, t_points, h_obj) -> void:
	audio = aud
	background = bg
	chart_info = c_info
	timing_points = t_points
	hit_objects = h_obj
