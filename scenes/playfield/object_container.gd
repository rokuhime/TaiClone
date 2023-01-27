extends Node

enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

onready var hitObjectScenes := HitObjectScenes.new()
var spinner_warn_object := preload("res://scenes/playfield/hitobjects/spinner_warn.tscn") as PackedScene

const FUS_VERSION := "v0.0.10"
const FUS := "user://debug.fus"

var firstNoteTime := -1.0
var lastNoteTime := -1.0

func load_chart(_game_path: String, file_path: String) -> void:
	file_path = file_path.replace("\\", "/")
	var file := File.new()

	# fail safes

	if not file.file_exists(file_path):
		return

	if file.open(file_path, File.READ):
		file.close()
		return

	# actual loading 

	var hitObjects := []
	var songTitle := ""
	var audioPreviewTime := ""
	var bgFileName := ""
	var audioFileName := ""
	var songArtist := ""
	var chartAuthor := ""
	var chartTitle := ""
	var chartRating := ""
	var folderPath = file_path.get_base_dir()

	print_debug("Finding file path: ", file_path)

	if file_path.ends_with(".fus"):

		var bpmCurrent := -1.0
		var lineIndex := 0

		while file.get_position() < file.get_len():
			var line := file.get_line().strip_edges()

			# go through metadata
			lineIndex += 1
			match lineIndex:
				1:
					if line != FUS_VERSION:
						return
				2:
					songArtist = line
				3:
					songTitle = line
				4:
					chartAuthor = line
				5:
					chartTitle = line
				6:
					chartRating = line
				7:
					audioPreviewTime = line
				8:
					audioFileName = line
				9:
					bgFileName = line
				10:
					folderPath = line

			if line.empty() or lineIndex < 11:
				continue

			var line_data := line.split(",")
			if line_data.size() < 3:
				continue

			var objectTime := float(line_data[0])
			var svCurrent := float(line_data[1]) * bpmCurrent

			if int(line_data[2]) > NoteType.BARLINE:
				firstNoteTime = min(firstNoteTime if firstNoteTime + 1 else objectTime, objectTime)
				lastNoteTime = max(lastNoteTime if lastNoteTime + 1 else objectTime, objectTime)

			match int(line_data[2]):
				NoteType.BARLINE:
					var hit_object := hitObjectScenes.barline_object.instance() as BarLine
					hit_object.change_properties(objectTime, svCurrent)
					add_object(hit_object)

				NoteType.DON, NoteType.KAT:
					var hit_object := hitObjectScenes.note_object.instance() as Note
					hit_object.change_properties(objectTime, svCurrent, int(line_data[2]) == int(ChartLoader.NoteType.KAT), bool(int(line_data[3])))
					add_object(hit_object)

				NoteType.ROLL:
					var hit_object := hitObjectScenes.roll_object.instance() as Roll
					hit_object.change_properties(objectTime, svCurrent, float(line_data[3]), bool(int(line_data[4])), bpmCurrent)
					add_object(hit_object)

				NoteType.SPINNER:
					var hit_object := hitObjectScenes.spinner_warn_object.instance() as SpinnerWarn
					hit_object.change_properties(objectTime, svCurrent, float(line_data[3]), bpmCurrent)
					add_object(hit_object)

				NoteType.TIMING_POINT:
					bpmCurrent = float(line_data[1])

					#var hit_object := hitObjectScenes.timing_point_object as TimingPoint
					#hit_object.change_properties(objectTime, int(line_data[3]), bpmCurrent)
					#add_object(hit_object)
		print_debug("Done loading file!")
		return

	elif file_path.ends_with(".osu"):
		var section := ""
		var subsection := ""

		var svMap := ""
		var svCurrent := 0.0
		var bpmCurrent := -1.0
		var barlineNext := 0.0
		var beatLength := -1.0
		var timingPreviousTime := 0.0
		var kiaiCurrent := false
		var meterCurrent := 4

		var timingPoints := []

		while file.get_position() < file.get_len():
			var line := file.get_line().strip_edges()
			
			if line.empty():
				continue

			if line.begins_with("[") and line.ends_with("]"):
				section = line.substr(1, line.length() - 2)
				continue
			
			var line_data := line.split(",")

			match section:
				"Difficulty":
					chartRating = _find_value(line, "OverallDifficulty:", chartRating)
					svMap = _find_value(line, "SliderMultiplier:", svMap)
					svCurrent = float(svMap)
				"Events":
					if subsection == "Background and Video events":
						bgFileName = line_data[2].replace("\"", "")
						subsection = ""
					subsection = _find_value(line, "//")
				"General":
					audioFileName = _find_value(line, "AudioFilename:", audioFileName)
					audioPreviewTime = _find_value(line, "PreviewTime:", audioPreviewTime)
				
				#########################################
				"HitObjects":
					if line_data.size() < 5:
						continue
					var objectTimeInMilliseconds = float(line_data[2])
					while timingPoints.size() > 0:
						var timingPointCurrent := str(timingPoints[0]).split(",")

						var timingPointTime := float(timingPointCurrent[0])
						var timingPointInherited := timingPointCurrent[1] == "1"
						var timingPointMeter := int(timingPointCurrent[2])
						var timingPointValue := float(timingPointCurrent[3])
						var timingPointKiai := timingPointCurrent[4] != "0"
						var timingPointFirstBarLine := timingPointCurrent[5] == "1"

						if bpmCurrent < 0 and not timingPointInherited:
							while timingPointTime > objectTimeInMilliseconds:
								timingPointTime -= timingPointMeter * timingPointValue
								barlineNext += timingPointMeter
							meterCurrent = timingPointMeter
							timingPreviousTime = timingPointTime
						if timingPointTime > objectTimeInMilliseconds:
							break

						var barlines := (timingPointTime - timingPreviousTime) / beatLength if beatLength != 0 else float(2^1024 - 1)

						while barlineNext < barlines:
							if svCurrent > 0:
								hitObjects.append(PoolStringArray([barlineNext, svCurrent, NoteType.BARLINE]).join(","))
							barlineNext += meterCurrent

						if not timingPointInherited or timingPointKiai != kiaiCurrent:
							barlineNext -= barlines
							if not timingPointInherited:
								if bpmCurrent >= 0:
									barlineNext = 0

								beatLength = timingPointValue
								bpmCurrent = 60000 / beatLength if beatLength != 0 else float(2^1024 - 1)
								meterCurrent = timingPointMeter
								svCurrent = float(svMap)

								if timingPointFirstBarLine:
									barlineNext += meterCurrent

							hitObjects.append(PoolStringArray([timingPointTime, bpmCurrent, NoteType.TIMING_POINT, 1 if timingPointKiai else 0]).join(","))
							kiaiCurrent = timingPointKiai
							timingPreviousTime = timingPointTime

						if timingPointInherited:
							svCurrent = -100 * float(svMap) / timingPointValue if timingPointValue != 0 else float(2^1024 - 1)
						timingPoints.remove(0)
					#########################################

					var objectTimeInBeats = (objectTimeInMilliseconds - timingPreviousTime) / beatLength if beatLength != 0 else float(2^1024 - 1)
					while barlineNext <= objectTimeInBeats:
						if svCurrent > 0:
							hitObjects.append(PoolStringArray([barlineNext, svCurrent, NoteType.BARLINE]).join(","))
						barlineNext += meterCurrent
					var objectType = int(line_data[3])

					if 8 & objectType:
						if line_data.size() > 5:
							hitObjects.append(PoolStringArray([objectTimeInBeats, svCurrent, NoteType.SPINNER, (float(line_data[5]) - objectTimeInMilliseconds) / beatLength if beatLength != 0 else float(2^1024 - 1)]).join(","))
					else:
						var finisher := int(line_data[4])
						if 2 & objectType:
							hitObjects.append(PoolStringArray([objectTimeInBeats, svCurrent, NoteType.ROLL, float(line_data[7]) * int(line_data[6]) / svCurrent / 100 if bpmCurrent * svCurrent != 0 and line_data.size() > 7 else float(2^1024 - 1), 1 if 4 & finisher else 0]).join(","))
						else:
							hitObjects.append(PoolStringArray([objectTimeInBeats, svCurrent, NoteType.KAT if 10 & finisher else NoteType.DON, 1 if 4 & finisher else 0]).join(","))

				#########################################

				"Metadata":
					songArtist = _find_value(line, "Artist:", songArtist)
					songArtist = _find_value(line, "ArtistUnicode:", songArtist, true)
					songTitle = _find_value(line, "Title:", songTitle)
					songTitle = _find_value(line, "TitleUnicode:", songTitle, true)
					chartAuthor = _find_value(line, "Creator:", chartAuthor)
					chartTitle = _find_value(line, "Version:", chartTitle)
				"TimingPoints":
					if line_data.size() < 2:
						continue
					var effects := int(line_data[7]) if line_data.size() > 7 else 0
					var inherited := float(line_data[1]) < 0
					if line_data.size() > 6:
						inherited = line_data[6] == "0"
					
					timingPoints.append(PoolStringArray([line_data[0], 1 if inherited else 0, 0.0 if inherited else float(line_data[2]), line_data[1], 1 & effects, 8 & effects]).join(","))
		if svCurrent > 0:
			hitObjects.append(PoolStringArray([barlineNext, svCurrent, NoteType.BARLINE]).join(","))
	
	else:
		file.close()
		return
	file.close()

	if file.open(FUS, File.WRITE): 
		file.close()
		return

	var lines := [
		FUS_VERSION, 
		songArtist, 
		songTitle, 
		chartAuthor, 
		chartTitle, 
		chartRating,
		audioPreviewTime, 
		audioFileName, 
		bgFileName,
		folderPath
	]
	lines.append_array(hitObjects)
	file.store_string(PoolStringArray(lines).join("\n"))
	file.close()
	load_chart("", FUS)

func add_object(hit_object: HitObject, loaded := true) -> void:
	add_child(hit_object)
	for i in range(get_child_count()):
		if hit_object.end_time > (get_child(i) as HitObject).end_time:
			move_child(hit_object, i)
			break

	if loaded:
		return

static func _find_value(line: String, key: String, value := "", overwrite := false) -> String:
	return line.trim_prefix(key).strip_edges() if line.begins_with(key) and not (overwrite and value) else value
