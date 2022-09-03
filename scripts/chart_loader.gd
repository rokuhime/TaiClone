class_name ChartLoader

## Comment
enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

## Comment
const FUS := "user://debug.fus"

## Comment
const FUS_VERSION := "v0.0.3"


## Comment
static func load_audio_file(file_path: String) -> AudioStream:
	var f := File.new()
	if f.open(file_path, File.READ):
		f.close()
		return load(file_path) as AudioStream

	## Comment
	var bytes := f.get_buffer(f.get_len())

	f.close()
	if file_path.ends_with(".mp3"):
		## Comment
		var new_stream := AudioStreamMP3.new()

		new_stream.data = bytes
		return new_stream

	if file_path.ends_with(".ogg"):
		## Comment
		var new_stream := AudioStreamOGGVorbis.new()

		new_stream.data = bytes
		return new_stream

	return load(file_path) as AudioStream


## Comment
static func load_chart(file_path: String) -> bool:
	## Comment
	var f := File.new()

	if f.open(file_path, File.READ):
		f.close()
		return true

	if file_path.ends_with(".osu"):
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
		var current_meter := 0

		## Comment
		var current_timing_data := []

		## Comment
		var difficulty_name := ""

		## Comment
		var map_sv_multiplier := ""

		## Comment
		var next_barline := 0.0

		## Comment
		var next_timing := []

		## Comment
		var notes := []

		## Comment
		var section := ""

		## Comment
		var subsection := ""

		## Comment
		var title := ""

		## Comment
		var total_cur_sv := 0.0

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
					map_sv_multiplier = _find_value(map_sv_multiplier, line, "SliderMultiplier:")
					total_cur_sv = float(map_sv_multiplier)

				"Events":
					if subsection == "Background and Video events":
						bg_file_name = line.get_slice(",", 2).replace("\"", "")
						subsection = ""

					subsection = _find_value(subsection, line, "//")

				"General":
					audio_filename = _find_value(audio_filename, line, "AudioFilename:")

				"HitObjects":
					## Comment
					var time := float(line_data[2]) / 1000

					while not next_timing.empty():
						## Comment
						var meter := int(next_timing[1])

						## Comment
						var next_time := float(next_timing[0])

						## Comment
						var timing := float(next_timing[2])

						if cur_bpm == -1 and meter:
							while next_time > min(-1, time - 1):
								next_time -= 60 * meter / timing

							next_barline = next_time

						if next_time > time:
							break

						if meter:
							while next_barline < next_time:
								next_barline = _barline(total_cur_sv, notes, next_barline, current_meter, cur_bpm)

							cur_bpm = timing
							current_meter = meter
							next_barline = next_time
							_append_note(notes, [next_barline, cur_bpm, NoteType.TIMING_POINT])

						else:
							total_cur_sv = timing * float(map_sv_multiplier)

						if current_timing_data.empty():
							next_timing = []

						else:
							next_timing = str(current_timing_data.pop_front()).split(",")

					while next_barline <= time:
						next_barline = _barline(total_cur_sv, notes, next_barline, current_meter, cur_bpm)

					if 1 << 3 & int(line_data[3]):
						_append_note(notes, [time, total_cur_sv, NoteType.SPINNER, float(line_data[5]) / 1000 - time])
						continue

					## Comment
					var finisher_int := 1 << 2 & int(line_data[4])

					if 1 << 1 & int(line_data[3]):
						_append_note(notes, [time, total_cur_sv, NoteType.ROLL, float(line_data[7]) * int(line_data[6]) * 0.6 / cur_bpm / total_cur_sv, finisher_int])

					else:
						_append_note(notes, [time, total_cur_sv, NoteType.KAT if bool(((1 << 1) + (1 << 3)) & int(line_data[4])) else NoteType.DON, finisher_int])

				"Metadata":
					artist = _find_value(artist, line, "Artist:")
					charter = _find_value(charter, line, "Creator:")
					difficulty_name = _find_value(difficulty_name, line, "Version:")
					title = _find_value(title, line, "Title:")

				"TimingPoints":
					## Comment
					var uninherited := bool(int(line_data[6]))

					line_data = _csv_line([float(line_data[0]) / 1000, int(line_data[2]) if uninherited else 0, (60000 if uninherited else -100) / float(line_data[1])])
					if next_timing.empty():
						next_timing = line_data

					else:
						current_timing_data.append(line_data.join(","))

		f.close()

		## Comment
		var folder_path := file_path.get_base_dir()

		file_path = FUS
		if f.open(file_path, File.WRITE):
			f.close()
			return true

		f.store_string(_csv_line([FUS_VERSION, folder_path.plus_file(bg_file_name), folder_path.plus_file(audio_filename), artist, charter, difficulty_name, title] + notes).join("\n"))
		f.close()

	elif not file_path.ends_with(".fus"):
		return true

	return false


## Comment
static func texture_from_image(file_path: String) -> Texture:
	if file_path.begins_with("res://"):
		return load(file_path) as Texture

	## Comment
	var image := Image.new()

	## Comment
	var new_texture := ImageTexture.new()

	if not image.load(file_path):
		new_texture.create_from_image(image)

	return new_texture


## Comment
static func _append_note(notes: Array, line_data: Array) -> void:
	notes.append(_csv_line(line_data).join(","))


## Comment
static func _barline(total_cur_sv: float, notes: Array, next_barline: float, current_meter: int, cur_bpm: float) -> float:
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
static func _find_value(value: String, line: String, key: String) -> String:
	return line.trim_prefix(key).strip_edges() if line.begins_with(key) else value
