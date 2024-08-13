## dummy class to hold a chart's data
class_name Chart

var file_path: String # for .tc file
var hash: PackedByteArray

# roku note 2024-08-09
# its getting really annoying fetching for mandatory files like audio_path and background_path in here
# this method is better for easier databasing, but strongly consider making these normal variables
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

func _init(f_path: String, c_info: Dictionary, t_points: Array, h_obj: Array, new_hash: PackedByteArray) -> void:
	file_path = f_path
	chart_info = c_info
	timing_points = t_points
	hit_objects = h_obj
	hash = new_hash

func load_hit_objects() -> Chart:
	var hitobj_chart := ChartLoader.get_tc_gamedata(file_path) as Chart
	timing_points = hitobj_chart.timing_points
	hit_objects = hitobj_chart.hit_objects
	return self

# Malice.
func populate_barlines() -> Array:
	var timing_points := get_timing_points()
	var last_timing_point: TimingPoint
	var barlines := []
	
	for i in range(timing_points.size() - 1, -1, -1):
		var target_timing_point: TimingPoint = timing_points[i]
		if not last_timing_point:
			last_timing_point = target_timing_point
			continue
		
		barlines.append_array(get_barlines(last_timing_point, target_timing_point.timing))
		last_timing_point = target_timing_point
	barlines.append_array(get_barlines(last_timing_point, get_last_hitobject().timing))
	
	hit_objects.append_array(barlines)
	return barlines

func get_barlines(timing_point: TimingPoint, end_time: float) -> Array:
	var barlines := []
	var length_btwn_points: float = end_time - timing_point.timing
	var bps: float = 60.0 * timing_point.meter / timing_point.bpm
	var barline_count: int = ceil(length_btwn_points / bps)
	
	for barline_idx in barline_count:
		var barline_timing := timing_point.timing + (length_btwn_points / (barline_count + 1)) * barline_idx
		var new_barline := ChartLoader.generate_hit_object(ChartLoader.NOTETYPE.BARLINE, [barline_timing, 150], [])
		barlines.append(new_barline)
	return barlines

func get_timing_points() -> Array:
	var timing_points := []
	for hobj in hit_objects:
		if hobj is TimingPoint:
			timing_points.append(hobj)
	return timing_points

func get_first_hitobject() -> HitObject:
	# get first hit object thats hittable
	var first_hit_object: HitObject
	for i in range(hit_objects.size() - 1, -1, -1):
		var hit_object := hit_objects[i] as HitObject
		if hit_object.is_in_group("Hittable"):
			return hit_object
	return null
	
func get_last_hitobject() -> HitObject:
	# get last hit object thats hittable
	var first_hit_object: HitObject
	for hit_object in hit_objects:
		if hit_object.is_in_group("Hittable"):
			return hit_object
	return null
