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

func get_timing_points() -> Array:
	var found_timing_points := []
	for hobj in hit_objects:
		if hobj is TimingPoint:
			found_timing_points.append(hobj)
	return found_timing_points

# get first hit object thats hittable
func get_first_hitobject() -> HitObject:
	for i in range(hit_objects.size() - 1, -1, -1):
		var hit_object := hit_objects[i] as HitObject
		if hit_object.is_in_group("Hittable"):
			return hit_object
	return null

# get last hit object thats hittable, not passing end_time
func get_last_hitobject(end_time := 0.0) -> HitObject:
	for hit_object in hit_objects:
		if end_time > 0:
			if end_time < hit_object.timing:
				continue
		if hit_object.is_in_group("Hittable"):
			return hit_object
	return null
