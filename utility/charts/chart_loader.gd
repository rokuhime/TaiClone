class_name ChartLoader

# TODO: Audio_Path and Preview_Point include extra spaces at the start?
# TODO: dont include inherited points, unless kiai (inherit the last bpm)
# TODO: its not writing the velocity :((((((((((((((((((((((((((((((((((((((
# TODO: length is also grossly incorrect

# stupid notes to roku
# sv types could be named "default", "slide", "scale"
# respectively taiko, mania, piu

const TC_VERSION := "v0.0.1"
enum NOTETYPE {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

static var note_scene = preload("res://entites/gameplay/hitobjects/note.tscn")
static var roll_scene = preload("res://entites/gameplay/hitobjects/roll.tscn")
static var spinner_scene = preload("res://entites/gameplay/hitobjects/spinner.tscn")

## sees if chart needs to be converted, and then gives the .tc file path
static func get_chart_path(file_path: String, force_convert := false) -> String:
	if not file_path.ends_with(".tc"):
		if FileAccess.file_exists("user://ConvertedSongs/" + file_path.get_file() + ".tc") and not force_convert:
			
			# chart isnt .tc, and is converted
			print("ChartLoader: converted file found!")
			return "user://ConvertedSongs/" + file_path.get_file() + ".tc"
			
		# chart isnt .tc, and is NOT converted. attempt to convert
		print("ChartLoader: attempting to convert file...")
		file_path = convert_chart(file_path)
	
	# chart is .tc, nothing to do!
	print("ChartLoader: intended chart path grabbed!")
	return file_path

## converts charts from other games to .tc
static func convert_chart(file_path: String):
	# throw err if file doesnt exist
	if !FileAccess.file_exists(file_path):
		print("ChartLoader: invalid file path given!")
		return null
	
	#open and load
	var file := FileAccess.open(file_path, FileAccess.READ)
	var line := ""
	var origin
	
	var section := ""
	var chart_info := {}
	
	var current_timing := {}
	var timing_points := []
	var next_timing_time
	
	var hit_objects := []
	
	var slider_multiplier := 1.4
	
	match file_path.get_extension():
		"osu":
			print("ChartLoader: parsing file as osu...")
			origin = "osu"
			
			# variables that can be assigned while going through sections
			# avoids pointless vars that could break stuff
			var valid_variables := ["AudioFilename", "PreviewTime", "Title", "Artist", "Version", "Creator"]
			var translated_variables := ["Audio_Path", "Preview_Point", "Song_Title", "Song_Artist", "Chart_Title", "Chart_Artist"]
			
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
						
						if valid_variables.has(data_name):
							data_value = line.substr(line.find(':') + 1, line.length())
							chart_info[ translated_variables[valid_variables.find(data_name)] ] = data_value
						
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
								chart_info["Background"] = line_data[2].trim_prefix('"').trim_suffix('"')
								
						continue

					"TimingPoints":
						# ensure all required data is in line_data (compatibility)
						if line_data.size() < 3:
							line_data.append("4")

						if line_data.size() < 4:
							line_data.append("0")

						if line_data.size() < 5:
							line_data.append("0")

						if line_data.size() < 6:
							line_data.append("100")

						if line_data.size() < 7:
							line_data.append("1")

						# parse data
						var time := float(line_data[0]) / 1000 # time in seconds
						var uninherited = bool(int(line_data[6])) # silly, but lets it be treated as a bit to bool
						
						# parse bpm changes/sv, based on uninherited
						var beat_length := float(line_data[1])
						var timing_value := snappedf(((60000.0 if uninherited else -100.0) / beat_length if beat_length else INF), 0.001)
						var meter := int(line_data[2])
						
						# make timing point array
						var timing_point := [time, uninherited, timing_value, meter]
						
						# check for extra variables
						var ex := {}
						# im not going to lie to you, i dont know why its 0 here but it works
						if bool(1 << 0 & int(line_data[7])):
							ex["Kiai"] = true
						if bool(1 << 3 & int(line_data[7])):
							ex["Omit_Barline"] = true
						
						# add extra variables if provided
						if not ex.is_empty():
							timing_point.append(ex)
						
						# queue up first timing point, if not already done
						if current_timing.is_empty() and uninherited:
							current_timing["Time"] = time
							current_timing["BPM"] = timing_value
							current_timing["Velocity"] = 1.0
						
						elif next_timing_time == null:
							next_timing_time = time
						
						# already parsed it, may aswell use it
						timing_points.append(timing_point)
						
						continue

					"HitObjects":
						var time := float(line_data[2]) / 1000 # time in seconds
						
						# update current timing point if note object is past current timing
						var intended_timing_point = get_intended_timing(time, timing_points)
						current_timing["Velocity"] = intended_timing_point[2]
						current_timing["BPM"] = intended_timing_point[1]
						
						var velocity : float = current_timing["Velocity"] * slider_multiplier * current_timing["BPM"]
						
						var finisher := bool(1 << 2 & int(line_data[4]))
						# distinct between osu object types and taiclone types, as they are stored differently
						var tc_type
						
						# variable to hold any extra variables for objects
						var ex := {}
						
						# find note type, and add nessacary values
						
						if bool(1 << 3 & int(line_data[3])): # spinner
							ex["Length"] = float(line_data[5]) / 1000
							tc_type = NOTETYPE.SPINNER
						
						elif bool(1 << 1 & int(line_data[3])): # slider
							tc_type = NOTETYPE.ROLL
							
							# unnessacary variables, but breaking this down for readability
							# osu holds slider length extremely strangely, so this converts the slider's "length" into seconds
							var length = float(line_data[7])
							var repeats = int(line_data[6])
							ex["Length"] = length / (slider_multiplier * 100000.0 * current_timing["Velocity"]) * (60000.0 / current_timing["BPM"]) * repeats
						
						else:
							# everything else is parsed as a note, don/kat based on hitsounding as expected
							if bool(1 << 1 & int(line_data[4])):
								tc_type = NOTETYPE.KAT
							elif bool(1 << 3 & int(line_data[4])):
								tc_type = NOTETYPE.KAT
							else:
								tc_type = NOTETYPE.DON
						
						if bool(1 << 2 & int(line_data[3])): # new combo
							ex["New_Combo"] = true
						
						# make hit object array
						var hit_object := [time, velocity, tc_type, finisher, ex]
						
						hit_objects.append(hit_object)
						continue

					_:
						continue

		"tc":
			file.close()
			print("ChartLoader: tried to convert .tc!")
			return -2
		
		# throw err if file type isnt compatible
		_:
			file.close()
			print("ChartLoader: invalid file type!")
			return -3
	
	# save newly made taiclone file
	if not DirAccess.dir_exists_absolute("user://ConvertedSongs"):
		DirAccess.make_dir_absolute("user://ConvertedSongs")
	var new_file = FileAccess.open("user://ConvertedSongs/" + file_path.trim_prefix(file_path.get_base_dir()) + ".tc", FileAccess.WRITE)
	
	# top info
	new_file.store_line("TaiClone Chart " + TC_VERSION)
	if origin != null:
		new_file.store_line("Origin: " + file_path + "\n")
	
	# chart info section
	for ci in chart_info:
		new_file.store_line(str(ci) + ": " + chart_info[ci])
	
	# store timing points, then hit objects
	new_file.store_line(get_object_string(false, timing_points))
	new_file.store_line(get_object_string(true, hit_objects))
	
	# save path and close 
	var new_path = new_file.get_path()
	
	new_file.close()
	file.close()
	
	print("ChartLoader: done converting chart!")
	return new_path

## loads .tc files and spits out Chart variable
static func get_chart(file_path: String) -> Chart:
	var file := FileAccess.open(file_path, FileAccess.READ)
	var line := ""
	var section := ""
	
	var audio : AudioStream
	var background
	
	var chart_info := {}
	
	var timing_points := []
	var hit_objects := []
	
	while file.get_position() < file.get_length():
		line = file.get_line().strip_edges()
		
		if line.is_empty() or line.begins_with("TaiClone Chart"):
			continue
		
		# change current section
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2)
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
		
		match section:
			"Timing Points":
				var obj_arr := []
				
				# set basic variables 
				obj_arr.push_back(float(line_data[0])) # timing
				obj_arr.push_back(line_data[1] == "true") # bpm change (this is silly and will be fixed!)
				obj_arr.push_back(float(line_data[2])) # bpm value
				obj_arr.push_back(int(line_data[3])) # time signature (assumes 4/x)
				
				timing_points.push_back(obj_arr)
				continue

			"Hit Objects":
				hit_objects.push_back( generate_hit_object( (int(line_data[2]) as NOTETYPE), line_data, timing_points) )
				continue

			_: # chart info
				data_name = line.substr(0, line.find(':'))
				data_value = line.substr(line.find(':') + 1, line.length()).strip_edges()
				
				match data_name:
					"Origin":
						file_path = data_value

					"Audio_Path":
						audio = AudioLoader.load_file(file_path.get_base_dir() + "/" + data_value)

					"Background":
						background = ImageLoader.load_image(file_path.get_base_dir() + "/" + data_value)

					_:
						chart_info[data_name] = data_value
				continue

	hit_objects.sort_custom(
		func(a: HitObject, b: HitObject): return a.timing > b.timing
	)

	print("ChartLoader: chart loaded successfully!")
	return Chart.new(audio, background, chart_info, timing_points, hit_objects)

## formats objects into a string
static func get_object_string(is_hobj: bool, data: Array) -> String:
	var intended_str := ""
	
	if is_hobj:
		intended_str += "\n[Hit Objects]\n"
	else:
		intended_str += "\n[Timing Points]\n"
	
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
	var ex_vars := {}
	var intended_timing_point = get_intended_timing(float(line_data[0]), timing_data)
	
	if line_data.size() > 4: # if ex vars exist...
		for ex in line_data.slice(4, line_data.size()):
			var data_name = ex.substr(0, ex.find(':')).strip_edges()
			var data_value = ex.substr(ex.find(':') + 1, ex.length()).strip_edges()
			ex_vars[data_name] = data_value
	
	match type:
		NOTETYPE.ROLL:
			var new_hit_object = roll_scene.instantiate() as Roll
			
			new_hit_object.timing = float(line_data[0])
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			if ex_vars.keys().has("New_Combo"):
				new_hit_object.new_combo = ex_vars["New_Combo"] == "true"
			
			(new_hit_object as Roll).length = ex_vars["Length"]
			
			return new_hit_object 
		
		NOTETYPE.SPINNER:
			var new_hit_object = spinner_scene.instantiate() as Spinner
			
			new_hit_object.timing = float(line_data[0])
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			if ex_vars.keys().has("New_Combo"):
				new_hit_object.new_combo = ex_vars["New_Combo"] == "true"
			
			(new_hit_object as Spinner).length = ex_vars["Length"]
			
			var beat_measure : int = intended_timing_point[3]
			var beat_divisor := 4
			var beat_in_seconds : float = (60.0 * beat_measure) / intended_timing_point[1]
			(new_hit_object as Spinner).needed_hits = floor(float(ex_vars["Length"]) / (beat_in_seconds / beat_divisor) )
			return new_hit_object 
		
		_:  # note
			var new_hit_object := note_scene.instantiate() as Note
			
			new_hit_object.timing = float(line_data[0])
			new_hit_object.speed = float(line_data[1]) # velocity
			new_hit_object.is_finisher = line_data[3] == "true"
			
			if ex_vars.keys().has("New_Combo"):
				new_hit_object.new_combo = ex_vars["New_Combo"] == "true"
			
			(new_hit_object as Note).is_kat = type == NOTETYPE.KAT
			
			return new_hit_object 

static func get_intended_timing(current_time: float, timing_points):
	var timing := 0.0
	var bpm := 0.0
	var velocity := 1.0
	var meter := 4
	
	for tp in timing_points:
		if tp[0] > current_time:
			break
		
		if tp[1]:  # if inherited (bpm)
			bpm = tp[2]
			meter = tp[3]
			continue
		velocity = tp[2]
	
	return [timing, bpm, velocity, meter]
