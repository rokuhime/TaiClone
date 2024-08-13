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

# goes through the chart's timing points and adds all valid barlines
# TODO: move this inside of chart_loader
func populate_barlines():
	var timing_points := get_timing_points()
	var barlines := []
	
	# start at first timing point, back up a bar length until we cant back up anymore
	for i in range(timing_points.size() - 1, -1, -1):
		var target_timing_point: TimingPoint = timing_points[i]
		var barline_time := target_timing_point.timing
		var bar_length := 60 * target_timing_point.meter / target_timing_point.bpm
		
		# if its the first timing point, back up until we're about to go to negatives
		if i == timing_points.size() - 1:
			barline_time = target_timing_point.timing
			while barline_time - bar_length >= 0.0:
				barline_time -= bar_length
		
		var end_time := get_last_hitobject().timing # default to last hobj timing
		if i > 0: # if theres a later timing point that exists...
			end_time = timing_points[i - 1].timing
		
		# if the barline_time hasnt passed the end_time...
		while barline_time < end_time:
			var last_hobj_before_timing := get_last_hitobject(barline_time)
			if not last_hobj_before_timing:
				last_hobj_before_timing = get_first_hitobject()
			
			var velocity := last_hobj_before_timing.speed
			var new_barline := ChartLoader.generate_hit_object(ChartLoader.NOTETYPE.BARLINE, [barline_time, velocity], [])
			barlines.append(new_barline)
			barline_time += bar_length
	
	hit_objects.append_array(barlines)

func get_timing_points() -> Array:
	var timing_points := []
	for hobj in hit_objects:
		if hobj is TimingPoint:
			timing_points.append(hobj)
	return timing_points

# get first hit object thats hittable
func get_first_hitobject() -> HitObject:
	var first_hit_object: HitObject
	for i in range(hit_objects.size() - 1, -1, -1):
		var hit_object := hit_objects[i] as HitObject
		if hit_object.is_in_group("Hittable"):
			return hit_object
	return null

# get last hit object thats hittable, not passing end_time
func get_last_hitobject(end_time := 0.0) -> HitObject:
	var first_hit_object: HitObject
	for hit_object in hit_objects:
		if end_time > 0:
			if end_time < hit_object.timing:
				continue
		if hit_object.is_in_group("Hittable"):
			return hit_object
	return null
