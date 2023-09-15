class_name ChartLoader

# stupid notes to roku
# sv types could be named "default", "slide", "scale"
# respectively taiko, mania, piu

enum NOTETYPE {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

const TC_VERSION := "v0.0.1"

static func load_chart(file_path: String = "/home/roku/Documents/Programming/TaiClone/Songs/osu/duskinovernight/N_dog - Dusk in overnight (6_6) [Eclipse].osu"):
	convert_chart(file_path)

static func convert_chart(file_path: String):
	# throw err if file doesnt exist
	if !FileAccess.file_exists(file_path):
		print("ChartLoader: invalid file path given!")
		return -1
	
	#open and load
	var file := FileAccess.open(file_path, FileAccess.READ)
	var line := ""
	
	var section := ""
	var chart_info := {}
	
	var current_timing := {}
	var timing_points := []
	var next_timing_time
	
	var hit_objects := []
	
	var slider_multiplier := 100
	
	
	if file_path.ends_with(".osu"):
		print("ChartLoader: parsing file as osu...")
		
		while file.get_position() < file.get_length():
			line = file.get_line().strip_edges()
			
			if line.is_empty():
				continue
			
			# change current section
			if line.begins_with("[") and line.ends_with("]"):
				section = line.substr(1, line.length() - 2)
				print("ChartLoader: changed section to ", section)
				continue
			
			# split line into array by commas
			var line_data := line.split(",")
			
			match section:
				"General":
					continue
				"Metadata":
					continue
				"Difficulty":
					continue
				"Events":
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
					var osu_type := int(line_data[3])
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
	
	# throw err if file type isnt compatible
	else:
		file.close()
		print("ChartLoader: invalid file type!")
		return -2
	
	file.close()
	
	# save newly made taiclone file
	var new_file = FileAccess.open("user://temp.tc", FileAccess.WRITE)
	new_file.store_line("TaiClone Chart " + TC_VERSION)

	new_file.store_line("\nTiming Points")
	for tp in timing_points:
		new_file.store_line(str(tp))

	new_file.store_line("\nHit Objects")
	for ho in hit_objects:
		new_file.store_line(str(ho))

	new_file.close()
	print("ChartLoader: done!")

static func _find_value(line: String, key: String, value := "", overwrite := false) -> String:
	return line.trim_prefix(key).strip_edges() if line.begins_with(key) and not (overwrite and value) else value

