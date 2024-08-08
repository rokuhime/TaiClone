## dummy class to hold a chart's data
class_name Chart

var file_path: String # for .tc file
var audio
var background
var hash: PackedByteArray

var chart_info := {
	"song_title": "",
	"song_artist": "",
	"chart_title": "",
	"chart_artist": "",
	
	"origin": "",
	# "origin_path": "", (optional, for origins outside of taiclone)
	"audio_path": "",
	"background_path": "",
	"preview_point": 0.0,
}

var timing_points := []
var hit_objects := []

func _init(f_path, aud, bg, c_info, t_points, h_obj, new_hash) -> void:
	file_path = f_path
	audio = aud
	background = bg
	chart_info = c_info
	timing_points = t_points
	hit_objects = h_obj
	hash = new_hash

func load_hit_objects() -> Chart:
	var hitobj_chart := ChartLoader.get_tc_gamedata(file_path) as Chart
	timing_points = hitobj_chart.timing_points
	hit_objects = hitobj_chart.hit_objects
	return self
