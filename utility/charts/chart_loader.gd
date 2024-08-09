class_name ChartLoader

# stupid notes to roku
# sv types could be named "default", "slide", "scale"
# respectively taiko, mania, piu

const TC_VERSION := "v0.0.3"
enum NOTETYPE {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}
const SUPPORTED_FILETYPES := ["tc", "osu"]

static var note_scene = preload("res://entites/gameplay/hitobjects/note.tscn")
static var roll_scene = preload("res://entites/gameplay/hitobjects/roll.tscn")
static var spinner_scene = preload("res://entites/gameplay/hitobjects/spinner.tscn")
static var timing_point_scene = preload("res://entites/gameplay/hitobjects/timing_point.tscn")

## sees if chart needs to be converted, and then gives the .tc file path
static func get_chart_path(file_path: String, force_convert := false) -> String:
	if not file_path.ends_with(".tc"):
		if FileAccess.file_exists("user://ConvertedCharts/" + file_path.get_file() + ".tc") and not force_convert:
			
			# chart isnt .tc, and is converted
			return "user://ConvertedCharts/" + file_path.get_file() + ".tc"
			
		# chart isnt .tc, and is NOT converted. attempt to convert\
		file_path = convert_chart(file_path)
	
	# chart is .tc, nothing to do!
	return file_path

## converts charts from other games to .tc
static func convert_chart(file_path: String):
	Global.push_console("ChartLoader", "Attempting to convert: %s" % file_path, -2)
	
	# throw err if file doesnt exist
	if !FileAccess.file_exists(file_path):
		Global.push_console("ChartLoader", "Tried to convert invalid file: %s" % file_path, 2)
		return null
	
	#open and load
	var file := FileAccess.open(file_path, FileAccess.READ)
	var line := ""
	var origin
	
	var section := ""
	var chart_info := {}
	var current_timing := {}
	var timing_points := []
	
	var hit_objects := []
	
	var slider_multiplier := 1.4
	
	match file_path.get_extension():
		"osu":
			Global.push_console("ChartLoader", "parsing file as .osu...", -2)
			origin = "osu"
			
			# translates variables from .osu's formatting to .tc's formatting
			var valid_variables := {
				"Title": "song_title", 
				"Artist": "song_artist", 
				"Creator": "chart_artist",
				"Version": "chart_title",
				"AudioFilename": "audio_path", 
				"PreviewTime": "preview_point", 
				}
			
			while file.get_position() < file.get_length():
				line = file.get_line().strip_edges()
				
				if line.is_empty():
					continue
				
				# change current section
				if line.begins_with("[") and line.ends_with("]"):
					section = line.substr(1, line.length() - 2)
					continue
				
				# split line into array by commas
				var line_data := line.split(",")
				var data_name := ""
				var data_value := ""
				
				match section:
					"General", "Metadata", "Difficulty":
						data_name = line.substr(0, line.find(':'))
						data_value = line.substr(line.find(':') + 1, line.length()).strip_edges()

						if valid_variables.has(data_name):
							chart_info[ valid_variables[data_name] ] = data_value
						
						elif data_name == "Mode":
							if data_value == "1": # taiko chart
								chart_info["origin"] = "Osu"
							else: # other gamemodes
								chart_info["origin"] = "Convert"
						
						elif data_name == "SliderMultiplier":
							data_value = line.substr(line.find(':') + 1, line.length())
							slider_multiplier = float(data_value)
						
						continue

					"Events":
						if line.begins_with("//"):
							continue
						if line_data[2].begins_with('"'):
							var bg_filepath = line_data[2].trim_prefix('"').trim_suffix('"')
							if bg_filepath.ends_with(".png") or bg_filepath.ends_with(".jpg"):
								chart_info["background_path"] = line_data[2].trim_prefix('"').trim_suffix('"')
								
						continue

					"TimingPoints":
						# ensure all required data is in line_data (compatibility)
						if line_data.size() < 2: # meter
							line_data.append("4")

						if line_data.size() < 3: # sample set
							line_data.append("0")

						if line_data.size() < 4: # sample index
							line_data.append("0")

						if line_data.size() < 5: # volume
							line_data.append("100")

						if line_data.size() < 6: # uninherited
							line_data.append("1")
						
						if line_data.size() < 6: # kiai
							line_data.append("0")

						# parse data
						var time := float(line_data[0]) / 1000 # time in seconds
						# silly thing here; if the timing point is inherited/sv change, meter will be 0
						# hence inherited == bool(meter)
						var meter := int(line_data[2]) if bool(int(line_data[6])) else 0
						
						# parse bpm changes/sv, based on uninherited
						var beat_length := float(line_data[1])
						var timing_value := snappedf(((60000.0 if meter else -100.0) / beat_length if beat_length else INF), 0.001)
						var is_kiai_enabled := bool(1 << 0 & int(line_data[7]))
						#if bool(1 << 3 & int(line_data[7])):
							#ex["Omit_Barline"] = true
						
						# make timing point array
						var timing_point := [time, timing_value, is_kiai_enabled, meter]
						
						# queue up first uninherited timing point, if not already done
						if current_timing.is_empty() and meter:
							current_timing["Time"] = time
							current_timing["Meter"] = meter
							current_timing["BPM"] = timing_value
							current_timing["Velocity"] = 1.0
							current_timing["Kiai"] = is_kiai_enabled
							current_timing["NextChangeTime"] = time
							
							# below doesnt find first timing point, so implement it here
							var timing_object := [time, current_timing["BPM"], NOTETYPE.TIMING_POINT, current_timing["Kiai"], current_timing["Meter"]]
							hit_objects.append(timing_object)
						
						# already parsed it, may aswell use it
						timing_points.append(timing_point)
						continue

					"HitObjects":
						var time := float(line_data[2]) / 1000 # time in seconds
						
						# update current timing point if note object is past current timing
						if not current_timing.is_empty():
							if current_timing["NextChangeTime"]:
								if time >= current_timing["NextChangeTime"]:
									# update timing values
									var old_kiai: bool = current_timing["Kiai"]
									current_timing = get_intended_timing(time, timing_points)
									
									if current_timing["LastChangeInherited"] or old_kiai != current_timing["Kiai"]:
										# make timing object array
										var timing_object := [time, current_timing["BPM"], NOTETYPE.TIMING_POINT, current_timing["Kiai"], current_timing["Meter"]]
										if not hit_objects.has(timing_object):
											hit_objects.append(timing_object)
						
						var velocity : float = current_timing["Velocity"] * slider_multiplier * current_timing["BPM"]
						
						var finisher := bool(1 << 2 & int(line_data[4]))
						# distinct between osu object types and taiclone types, as they are stored differently
						var tc_type
						
						# variable to hold any extra variables for objects
						var ex := []
						
						# find note type, and add nessacary values
						if bool(1 << 3 & int(line_data[3])): # spinner
							ex.append(float(line_data[5]) / 1000 - time)
							tc_type = NOTETYPE.SPINNER
						
						elif bool(1 << 1 & int(line_data[3])): # slider
							tc_type = NOTETYPE.ROLL
							
							# unnessacary variables, but breaking this down for readability
							# osu holds slider length extremely strangely, so this converts the slider's "length" into seconds
							var length = float(line_data[7])
							var repeats = int(line_data[6])
							ex.append(length / (slider_multiplier * 100000.0 * current_timing["Velocity"]) * (60000.0 / current_timing["BPM"]) * repeats)
						
						else:
							# everything else is parsed as a note, don/kat based on hitsounding as expected
							if bool(1 << 1 & int(line_data[4])):
								tc_type = NOTETYPE.KAT
							elif bool(1 << 3 & int(line_data[4])):
								tc_type = NOTETYPE.KAT
							else:
								tc_type = NOTETYPE.DON
						
						#if bool(1 << 2 & int(line_data[3])): # new combo
							#ex["New_Combo"] = true
						
						# make hit object array
						var hit_object := [time, velocity, tc_type, finisher]
						hit_object.append_array(ex)
						
						hit_objects.append(hit_object)
						continue

					_:
						continue

		"tc":
			# tried to convert tc, ignore and bail
			file.close()
			return -2
		
		# throw err if file type isnt compatible
		_:
			file.close()
			Global.push_console("ChartLoader", "Tried to convert invalid file type: %s" % file_path, 1)
			return -3
	
	# ensure file gets closed after use
	if file.is_open():
		file.close()
	
	# save newly made taiclone file
	if not DirAccess.dir_exists_absolute("user://ConvertedCharts"):
		DirAccess.make_dir_absolute("user://ConvertedCharts")
	var tc_path := "user://ConvertedCharts" + file_path.trim_prefix(file_path.get_base_dir()) + ".tc"
	var tc_file = FileAccess.open(tc_path, FileAccess.WRITE)
	
	# top info
	tc_file.store_line("TaiClone Chart " + TC_VERSION)
	if origin != null:
		tc_file.store_line("origin_path: " + file_path)
	
	# chart info section
	for ci in chart_info:
		tc_file.store_line(str(ci) + ": " + chart_info[ci])
	
	# store objects in .tc file and close
	tc_file.store_line(get_object_string(hit_objects))
	tc_file.close()
	
	Global.push_console("ChartLoader", "Chart successfully converted!", -1)
	return tc_path

## gets metadata from a .tc file
static func get_tc_metadata(file_path: String) -> Chart:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if !file:
		Global.push_console("ChartLoader", "Bad file provided for get_chart: " % file_path, 2)
		return
	
	var origin_file_path := file_path
	var hash := Global.get_hash(file_path)
	
	var line := ""
	# 0 = metadata, 1 = hit objects
	var section := 0
	
	var audio : AudioStream
	var background
	var chart_info := {}
	
	var timing_points := []
	var hit_objects := []
	
	while file.get_position() < file.get_length():
		line = file.get_line().strip_edges()
		
		if line.begins_with("TaiClone Chart"):
			continue
		
		# change current section
		# roku note 2024-07-16
		# if this stays like this, itll be really easy to corrupt .tc files by adding extra linebreaks. be careful
		if line.is_empty():
			break
		
		# split line into array by commas
		var line_data := line.split(",")
		
		# this is stupid, but the alternative is line_data[line_data.find(line_data_segment)]
		# strip edges of each value in line_data
		var i := 0
		for line_data_segment in line_data:
			line_data[i] = line_data[i].strip_edges()
			i += 1
		
		var data_name := line.substr(0, line.find(':'))
		var data_value := line.substr(line.find(':') + 1, line.length()).strip_edges()
		
		match data_name:
			"origin_path":
				origin_file_path = data_value
				chart_info["origin_path"] = data_value

			"origin":
				chart_info["origin"] = data_value

			"audio_path":
				chart_info["audio_path"] = origin_file_path.get_base_dir().path_join(data_value)

			"background_path":
				chart_info["background_path"] = origin_file_path.get_base_dir().path_join(data_value)

			"preview_point":
				chart_info["preview_point"] = int(data_value) / 1000.0

			_:
				chart_info[data_name] = data_value
		continue
	
	file.close()
	
	return Chart.new(file_path, chart_info, [], [], hash)

## gets hit objects from a .tc file
static func get_tc_gamedata(file_path: String) -> Chart:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if !file:
		Global.push_console("ChartLoader", "Bad file provided for get_chart: " % file_path, 2)
		return
	
	var hash := Global.get_hash(file_path)
	
	var line := ""
	# 0 = metadata, 1 = hit objects
	var section := 0
	
	var timing_points := []
	var hit_objects := []
	
	while file.get_position() < file.get_length():
		line = file.get_line().strip_edges()
		
		if line.begins_with("TaiClone Chart"):
			continue
		
		# change current section
		# roku note 2024-07-16
		# if this stays like this, itll be really easy to corrupt .tc files by adding extra linebreaks. be careful
		if line.is_empty():
			section += 1
			continue
		
		# if were only grabbing metadata, ignore everything else
		if section != 1:
			continue
		
		# split line into array by commas
		var line_data := line.split(",")
		
		# this is stupid, but the alternative is line_data[line_data.find(line_data_segment)]
		# strip edges of each value in line_data
		var i := 0
		for line_data_segment in line_data:
			line_data[i] = line_data[i].strip_edges()
			i += 1
		
		var data_name := ""
		var data_value := ""
		
		if section: 
			if int(line_data[2]) == NOTETYPE.TIMING_POINT:
				var obj_arr := []

				# set basic variables 
				obj_arr.push_back(float(line_data[0])) # timing
				obj_arr.push_back(float(line_data[1])) # bpm value
				obj_arr.push_back(line_data[3] == "true") # kiai
				obj_arr.push_back(int(line_data[4])) # time signature (assumes 4/x)

				timing_points.push_back(obj_arr)
			
			hit_objects.push_back( generate_hit_object( (int(line_data[2]) as NOTETYPE), line_data, timing_points) )
			continue
	file.close()

	hit_objects.sort_custom(
		func(a: HitObject, b: HitObject): return a.timing > b.timing
	)
	
	return Chart.new(file_path, {}, timing_points, hit_objects, hash)

## formats objects into a string
static func get_object_string(data: Array) -> String:
	var intended_str := "\n" # start with a linebreak to separate metadata and hit objects
	
	for obj in data:
		var line := ""
		
		for value in obj:
			if typeof(value) == TYPE_DICTIONARY:
				for ex_value in value:
					line += str(ex_value, ": ", value[ex_value], ", ")
				continue
			
			line += str(value, ", ")
		
		# trim off ending comma, and add line
		intended_str += line.substr(0, line.length() - 2) + "\n"
	
	return intended_str

static func generate_hit_object(type: NOTETYPE, line_data, timing_data) -> HitObject:
	var ex_vars := []
	var intended_timing_point = get_intended_timing(float(line_data[0]), timing_data)
	
	if line_data.size() > 4: # if ex vars exist...
		for ex in line_data.slice(4, line_data.size()):
			ex_vars.append(ex)
	
	match type:
		NOTETYPE.TIMING_POINT:
			var new_hit_object = timing_point_scene.instantiate() as TimingPoint
			
			new_hit_object.timing = line_data[0]
			new_hit_object.bpm = line_data[1]
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			return new_hit_object
		
		NOTETYPE.ROLL:
			var new_hit_object = roll_scene.instantiate() as Roll
			
			new_hit_object.timing = float(line_data[0])
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			#if ex_vars.keys().has("New_Combo"):
				#new_hit_object.new_combo = ex_vars["New_Combo"] == "true"
			
			(new_hit_object as Roll).length = ex_vars[0]
			(new_hit_object as Roll).tick_duration = (60.0 / intended_timing_point["BPM"]) / 4.0
			(new_hit_object as Roll).create_ticks()
			
			return new_hit_object
		
		NOTETYPE.SPINNER:
			var new_hit_object = spinner_scene.instantiate() as Spinner
			
			new_hit_object.timing = float(line_data[0])
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			#if ex_vars.keys().has("New_Combo"):
				#new_hit_object.new_combo = ex_vars["New_Combo"] == "true"
			
			(new_hit_object as Spinner).length = ex_vars[0]
			
			var beat_measure : int = intended_timing_point["Meter"]
			var beat_divisor := 4
			var beat_in_seconds : float = (60.0 * beat_measure) / intended_timing_point["BPM"]
			(new_hit_object as Spinner).needed_hits = ceil(float(ex_vars[0]) / (beat_in_seconds / beat_divisor) )
			return new_hit_object 
		
		_:  # note
			var new_hit_object := note_scene.instantiate() as Note
			
			new_hit_object.timing = float(line_data[0])
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			#if ex_vars.keys().has("New_Combo"):
				#new_hit_object.new_combo = ex_vars["New_Combo"] == "true"
			
			(new_hit_object as Note).is_kat = type == NOTETYPE.KAT
			
			return new_hit_object 

# return all relevant timing related info from a timestamp
static func get_intended_timing(current_time: float, timing_points) -> Dictionary:
	var intended_timing := { "BPM": 0.0, "Velocity": 1, "Meter": 4, "Kiai": false, "LastChangeInherited": false, "NextChangeTime": null}
	
	for tp in timing_points:
		# if timing point takes place after current_time, return results
		if tp[0] > current_time:
			intended_timing["NextChangeTime"] = tp[0]
			break 
		intended_timing["Kiai"] = tp[2]
		
		# if its uninherited (has meter)...
		if tp[3]:
			intended_timing["BPM"] = tp[1]
			intended_timing["Meter"] = tp[3]
			continue
		
		# inherited, only change velocity
		intended_timing["Velocity"] = tp[1]
	
	return intended_timing
