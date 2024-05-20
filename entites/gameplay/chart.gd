## dummy class to hold a chart's data
class_name Chart

var file_path: String
var audio
var background

var chart_info := {}

var timing_points := []
var hit_objects := []

func _init(f_path, aud, bg, c_info, t_points, h_obj) -> void:
	file_path = f_path
	audio = aud
	background = bg
	chart_info = c_info
	timing_points = t_points
	hit_objects = h_obj
