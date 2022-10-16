class_name ChartLoader

## Comment
enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

## Comment
const FUS := "debug.fus"

## Comment
const FUS_VERSION := "v0.0.6"


## Comment
static func load_chart(game_path: String, file_path: String) -> void:
	## Comment
	var f := File.new()

	if not f.file_exists(file_path):
		return

	if f.open(file_path, File.READ):
		f.close()
		return

	## Comment
	var artist := ""

	## Comment
	var audio_filename := ""

	## Comment
	var bg_file_name := ""

	## Comment
	var charter := ""

	## Comment
	var cur_bpm := -1.0

	## Comment
	var current_kiai := false

	## Comment
	var current_meter := 4.0

	## Comment
	var difficulty_name := ""

	## Comment
	var map_sv_multiplier := "1"

	## Comment
	var notes := []

	## Comment
	var title := ""

	## Comment
	var total_cur_sv := 1.0

	if file_path.ends_with(".osu"):
		## Comment
		var current_timing_data := []

		## Comment
		var next_barline := 0.0

		## Comment
		var next_timing := []

		## Comment
		var section := ""

		## Comment
		var subsection := ""

		while f.get_position() < f.get_len():
			## Comment
			var line := f.get_line().strip_edges()

			if line.empty():
				continue

			if line.begins_with("[") and line.ends_with("]"):
				section = line.substr(1, line.length() - 2)
				continue

			## Comment
			var line_data := line.split(",")

			match section:
				"Difficulty":
					map_sv_multiplier = _find_value(line, "SliderMultiplier:", map_sv_multiplier)
					total_cur_sv = float(map_sv_multiplier)

				"Events":
					if subsection == "Background and Video events":
						bg_file_name = line.get_slice(",", 2).replace("\"", "")
						subsection = ""

					subsection = _find_value(line, "//", subsection)

				"General":
					audio_filename = _find_value(line, "AudioFilename:", audio_filename)

				"HitObjects":
					## Comment
					var time := float(line_data[2]) / 1000

					while not next_timing.empty():
						## Comment
						var kiai := int(next_timing[3])

						## Comment
						var meter := int(next_timing[1])

						## Comment
						var next_time := float(next_timing[0])

						## Comment
						var timing := float(next_timing[2])

						if cur_bpm == -1 and meter:
							next_barline = next_time
							while next_time > time:
								next_time -= 60 * meter / timing

						if next_time > time:
							break

						if meter:
							while next_barline < next_time:
								next_barline = _barline(total_cur_sv, notes, next_barline, current_meter, cur_bpm)

							cur_bpm = timing
							current_meter = meter
							next_barline = next_time
							total_cur_sv = float(map_sv_multiplier)

						else:
							total_cur_sv = timing * float(map_sv_multiplier)

						if meter or bool(kiai) != current_kiai:
							_append_note(notes, [next_barline, cur_bpm, NoteType.TIMING_POINT, kiai])
							current_kiai = bool(kiai)

						if int(next_timing[4]):
							next_barline = _barline(0, notes, next_barline, current_meter, cur_bpm)

						if current_timing_data.empty():
							next_timing.clear()

						else:
							next_timing = str(current_timing_data.pop_front()).split(",")

					while next_barline <= time:
						next_barline = _barline(total_cur_sv, notes, next_barline, current_meter, cur_bpm)

					if 1 << 3 & int(line_data[3]):
						_append_note(notes, [time, total_cur_sv, NoteType.SPINNER, float(line_data[5]) / 1000 - time, -1])
						continue

					## Comment
					var finisher_int := 1 << 2 & int(line_data[4])

					if 1 << 1 & int(line_data[3]):
						_append_note(notes, [time, total_cur_sv, NoteType.ROLL, float(line_data[7]) * int(line_data[6]) * 0.6 / cur_bpm / total_cur_sv, finisher_int])

					else:
						_append_note(notes, [time, total_cur_sv, NoteType.KAT if bool(((1 << 1) + (1 << 3)) & int(line_data[4])) else NoteType.DON, finisher_int])

				"Metadata":
					artist = _find_value(line, "Artist:", artist)
					charter = _find_value(line, "Creator:", charter)
					difficulty_name = _find_value(line, "Version:", difficulty_name)
					title = _find_value(line, "Title:", title)

				"TimingPoints":
					## Comment
					var uninherited := bool(int(line_data[6]))

					line_data = _csv_line([float(line_data[0]) / 1000, int(line_data[2]) if uninherited else 0, (60000 if uninherited else -100) / float(line_data[1]), 1 << 0 & int(line_data[7]), 1 << 3 & int(line_data[7])])
					if next_timing.empty():
						next_timing = line_data

					else:
						current_timing_data.append(line_data.join(","))

	elif file_path.ends_with(".tja"):
		## Comment
		var balloons_string := ""

		## Comment
		var barlines := true

		## Comment
		var current_note := []

		## Comment
		var measure := []

		## Comment
		var metadata := true

		## Comment
		var notes_in_measure := 0

		## Comment
		var offset_string := "0"

		## Comment
		var starting_bpm := "120"

		## Comment
		var time := 0.0

		while f.get_position() < f.get_len():
			## Comment
			var line := f.get_line().strip_edges()

			if line.empty() or line.begins_with("//"):
				continue

			if metadata:
				if line == "#START":
					cur_bpm = float(starting_bpm)
					time = -float(offset_string)
					total_cur_sv = float(map_sv_multiplier)
					_append_note(notes, [time, cur_bpm, NoteType.TIMING_POINT, 0])
					metadata = false
					match difficulty_name:
						"0":
							difficulty_name = "Easy"

						"1":
							difficulty_name = "Normal"

						"2":
							difficulty_name = "Hard"

						"3":
							difficulty_name = "Oni"

						"4", "Edit":
							difficulty_name = "Ura"

						"5":
							difficulty_name = "Tower"

						"6":
							difficulty_name = "Dan"

				else:
					artist = _find_value(line, "SUBTITLE:", artist).trim_prefix("++").trim_prefix("--")
					artist = _find_value(line, "SUBTITLEEN:", artist, true)
					audio_filename = _find_value(line, "WAVE:", audio_filename)
					balloons_string = _find_value(line, "BALLOON:", balloons_string)
					bg_file_name = _find_value(line, "BGIMAGE:", bg_file_name)
					charter = _find_value(line, "MAKER:", charter)
					difficulty_name = _find_value(line, "COURSE:", difficulty_name)
					map_sv_multiplier = _find_value(line, "HEADSCROLL:", map_sv_multiplier)
					offset_string = _find_value(line, "OFFSET:", offset_string)
					starting_bpm = _find_value(line, "BPM:", starting_bpm)
					title = _find_value(line, "TITLE:", title)
					title = _find_value(line, "TITLEEN:", title, true)

				continue

			if line == "#END":
				metadata = true
				# TODO: Handle multiple charts in one file (once song select is implemented)
				break

			measure.append(line)
			if line.begins_with("#"):
				continue

			notes_in_measure += line.trim_suffix(",").length()
			if not line.ends_with(","):
				continue

			for i in measure.size():
				line = str(measure[i])
				match line:
					"#BARLINEOFF":
						barlines = false

					"#BARLINEON":
						barlines = true

					"#GOGOEND":
						_append_note(notes, [time, cur_bpm, NoteType.TIMING_POINT, 0])

					"#GOGOSTART":
						_append_note(notes, [time, cur_bpm, NoteType.TIMING_POINT, 1])

					_:
						if line.begins_with("#"):
							## Comment
							var command_value := _find_value(line, "#BPMCHANGE")

							if command_value:
								cur_bpm = float(command_value)

							command_value = _find_value(line, "#DELAY")
							if command_value:
								time += float(command_value)

							command_value = _find_value(line, "#MEASURE")
							if command_value:
								## Comment
								var line_data := command_value.split("/")

								current_meter = float(line_data[0]) * 4 / float(line_data[1])

							command_value = _find_value(line, "#SCROLL")
							if command_value:
								total_cur_sv = float(map_sv_multiplier) * float(command_value)

							continue

						for idx in line.trim_suffix(","):
							match int(idx):
								1:
									_append_note(notes, [time, total_cur_sv, NoteType.DON, 0])

								2:
									_append_note(notes, [time, total_cur_sv, NoteType.KAT, 0])

								3:
									_append_note(notes, [time, total_cur_sv, NoteType.DON, 1])

								4:
									_append_note(notes, [time, total_cur_sv, NoteType.KAT, 1])

								5:
									current_note = [time, total_cur_sv, NoteType.ROLL, 0]

								6:
									current_note = [time, total_cur_sv, NoteType.ROLL, 0]

								7:
									current_note = [time, total_cur_sv, NoteType.SPINNER, -1]

								8:
									if not current_note.empty():
										current_note.insert(3, time - float(current_note[0]))
										_append_note(notes, current_note)
										current_note.clear()

							time += 60 * current_meter / cur_bpm / notes_in_measure

			if notes_in_measure == 0:
				time += 60 * current_meter / cur_bpm

			if barlines:
				_append_note(notes, [time, total_cur_sv, NoteType.BARLINE])

			measure.clear()
			notes_in_measure = 0

	else:
		f.close()
		return

	f.close()
	if f.open(game_path.plus_file(FUS), File.WRITE):
		f.close()
		return

	## Comment
	var folder_path := file_path.get_base_dir()

	f.store_string(_csv_line([FUS_VERSION, folder_path.plus_file(bg_file_name), folder_path.plus_file(audio_filename), artist, charter, difficulty_name, title] + notes).join("\n"))
	f.close()

	return


## Comment
static func _append_note(notes: Array, line_data: Array) -> void:
	notes.append(_csv_line(line_data).join(","))


## Comment
static func _barline(total_cur_sv: float, notes: Array, next_barline: float, current_meter: float, cur_bpm: float) -> float:
	if total_cur_sv > 0:
		_append_note(notes, [next_barline, total_cur_sv, NoteType.BARLINE])

	return next_barline + 60 * current_meter / cur_bpm


## Comment
static func _csv_line(line_data: Array) -> PoolStringArray:
	## Comment
	var csv_line := []

	for key in line_data:
		csv_line.append(str(key))

	return PoolStringArray(csv_line)


## Comment
static func _find_value(line: String, key: String, value := "", overwrite := false) -> String:
	return line.trim_prefix(key).strip_edges() if line.begins_with(key) and not (overwrite and value) else value
