class_name ChartLoader

# TODO: Audio_Path and Preview_Point include extra spaces at the start?
# TODO: dont include inherited points, unless kiai (inherit the last bpm)
# TODO: its not writing the velocity :((((((((((((((((((((((((((((((((((((((
# TODO: length is also grossly incorrect

# stupid notes to roku
# sv types could be named "default", "slide", "scale"
# respectively taiko, mania, piu

enum NOTETYPE {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

const TC_VERSION := "v0.0.1"

## sees if chart needs to be converted, and then gives the .tc file path
static func get_chart_path(file_path: String, force_convert := false):
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
		return -1
	
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
	
	var slider_multiplier := 100
	
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
							slider_multiplier = float(data_value) * 100
						
						continue

					"Events":
						if line.begins_with("//"):
							continue
						if line_data[2].begins_with('"'):
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
						var timing_value := snappedf(((60000 if uninherited else slider_multiplier * -1) / beat_length if beat_length else INF), 0.001)
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
							current_timing["Velocity"] = slider_multiplier * timing_value
						
						elif next_timing_time == null:
							next_timing_time = time
						
						# already parsed it, may aswell use it
						timing_points.append(timing_point)
						
						continue

					"HitObjects":
						var time := float(line_data[2]) / 1000 # time in seconds
						
						# update current timing point if note object is past current timing
						if next_timing_time != null:
							if next_timing_time <= time:
								# cycle through timing points til its past intended time
								for timing in timing_points:
									if timing[0] > time:
										break
									
									current_timing["Time"] = timing[0]
									if timing[1]: # if bpm change...
										current_timing["BPM"] = timing[2]
										current_timing["Velocity"] = timing[2] * slider_multiplier
									
									else: # if sv change...
										current_timing["Velocity"] = timing[2]
							
							else:
								next_timing_time = null
						
						var velocity : float = current_timing["Velocity"] * slider_multiplier
						
						var finisher := bool(2 & int(line_data[4]) >= 2)
						
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
							var beat_length = current_timing["BPM"] / 60000
							ex["Length"] = (length * repeats / (slider_multiplier * 100 * current_timing["Velocity"]) * beat_length) / 1000
						
						else:
							# everything else is parsed as a note, don/kat based on hitsounding as expected
							tc_type = NOTETYPE.KAT if bool(1 << 1 & int(line_data[4])) else NOTETYPE.DON
						
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
	
	# timing section
	new_file.store_line("\n[Timing Points]")
	for tp in timing_points:
		var intended_line := ""
		
		for tim_var in tp:
			if typeof(tim_var) == TYPE_DICTIONARY:
				for ex_var in tim_var:
					intended_line += str(ex_var, ": ", tim_var[ex_var], ", ")
				continue
			
			intended_line += str(tim_var, ", ")
		
		intended_line = intended_line.substr(0, intended_line.length() - 2)
		new_file.store_line(intended_line)

	# hit object section
	new_file.store_line("\n[Hit Objects]")
	for ho in hit_objects:
		var intended_line := ""
		
		for hobj_var in ho:
			if typeof(hobj_var) == TYPE_DICTIONARY:
				for ex_var in hobj_var:
					intended_line += str(ex_var, ": ", hobj_var[ex_var], ", ")
				continue
			
			intended_line += str(hobj_var, ", ")
		
		intended_line = intended_line.substr(0, intended_line.length() - 2)
		new_file.store_line(intended_line)
	
	# save path and close 
	var new_path = new_file.get_path()
	
	new_file.close()
	file.close()
	
	print("ChartLoader: done converting chart!")
	return new_path

## loads .tc files and spits out Chart variable
static func load_chart(file_path: String):	
	var file := FileAccess.open(file_path, FileAccess.READ)
	var line := ""
	var section := ""
	
	var audio
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
		var data_name := ""
		var data_value := ""
		
		match section:
			"Timing Points":
				continue

			"Hit Objects":
				
				continue

			_: # chart info
				data_name = line.substr(0, line.find(':'))
				data_value = line.substr(line.find(':') + 1, line.length()).strip_edges()
				
				match data_name:
					"Origin":
						file_path = data_value

					"Audio_Path":
						# FIX ME HOOK HAT
						# i really dont like the fact were instancing it here, ugly and wastes memory. cant be outside of this because static
						# find a way to make AudioLoader static, convert_to_16bit was getting in the way
						var audio_loader = AudioLoader.new()
						audio = audio_loader.load_file(file_path.get_base_dir() + "/" + data_value)

					"Background":
						background = Global.load_image(file_path.get_base_dir() + "/" + data_value)
					
					_:
						chart_info[data_name] = data_value
				continue
	
	print("ChartLoader: chart loaded successfully!")
	return Chart.new(audio, background, chart_info, timing_points, hit_objects)
