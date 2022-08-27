class_name BarLeft
extends Node

## Comment
signal debug_text(text)

## Comment
signal marker_added(type, timing, skin)

## Comment
signal score_added(score, accuracy)

## Comment
enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

## Comment
var _accurate_count := 0

## Comment
var _combo := 0

## Comment
var _cur_time := 0.0

## Comment
var _f := File.new()

## Comment
var _fus := "user://debug.fus"

## Comment
var _inaccurate_count := 0

## Comment
var _judgement_tween := SceneTreeTween.new()

## Comment
var _miss_count := 0

## Comment
var _score := 0

onready var combo := $DrumVisual/Combo as Label
onready var judgement := $Judgement as TextureRect
onready var music := $Music as AudioStreamPlayer
onready var obj_container := $ObjectContainer as Control
onready var taiclone := $"/root" as Root


## Comment
func _process(delta: float) -> void:
	if not music.playing:
		return

	_cur_time += delta
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var note := obj_container.get_child(i) as HitObject

		if note.miss_check(_cur_time - (taiclone.inacc_timing if note is BarLine or note is Note else 0.0)):
			break


## Comment
func add_object(obj: HitObject) -> void:
	obj_container.add_child(obj)
	for i in range(obj_container.get_child_count()):
		if obj.end_time > (obj_container.get_child(i) as HitObject).end_time:
			obj_container.move_child(obj, i)
			break

	obj.add_to_group("HitObjects")
	if obj.connect("score_added", self, "add_score"):
		push_warning("Attempted to connect HitObject score_added.")

	obj.skin(taiclone.skin)


## Comment
func add_score(type: int, marker := false) -> void:
	_score += 150 if type == int(HitObject.Score.INACCURATE) else 300 if [HitObject.Score.ACCURATE, HitObject.Score.FINISHER, HitObject.Score.ROLL].has(type) else 600 if type == int(HitObject.Score.SPINNER) else 0
	match type:
		HitObject.Score.ACCURATE:
			_accurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = taiclone.skin.accurate_judgement

		HitObject.Score.INACCURATE:
			_inaccurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = taiclone.skin.inaccurate_judgement

		HitObject.Score.MISS:
			_miss_count += 1
			_combo = 0
			_hit_notify_animation()
			judgement.texture = taiclone.skin.miss_judgement
			if marker:
				emit_signal("marker_added", type, taiclone.inacc_timing, taiclone.skin)

	## Comment
	var hit_count := _accurate_count + _inaccurate_count / 2.0

	combo.text = str(_combo)
	emit_signal("score_added", _score, (hit_count * 100 / (_accurate_count + _inaccurate_count + _miss_count) if hit_count else 0.0))


## Comment
func load_func(file_path: String) -> void:
	emit_signal("debug_text", "Loading... [Checking File]")
	if _f.open(file_path, File.READ):
		_load_finish("Invalid file!")
		return

	emit_signal("debug_text", "Loading... [Reading File]")

	## Comment
	var fus_version := "v0.0.2"

	if file_path.ends_with(".osu"):
		## Comment
		var audio_filename := ""

		## Comment
		var bg_file_name := ""

		## Comment
		var cur_bpm := -1.0

		## Comment
		var current_meter := 0

		## Comment
		var current_timing_data := []

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
		var total_cur_sv := 0.0

		while _f.get_position() < _f.get_len():
			## Comment
			var line := _f.get_line().strip_edges()

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
					var finisher := 1 << 2 & int(line_data[4])

					if 1 << 1 & int(line_data[3]):
						_append_note(notes, [time, total_cur_sv, NoteType.ROLL, float(line_data[7]) * int(line_data[6]) * 0.6 / cur_bpm / total_cur_sv, finisher])

					else:
						_append_note(notes, [time, total_cur_sv, NoteType.KAT if bool(((1 << 1) + (1 << 3)) & int(line_data[4])) else NoteType.DON, finisher])

				"TimingPoints":
					## Comment
					var uninherited := bool(int(line_data[6]))

					## Comment
					var timing := _csv_line([float(line_data[0]) / 1000, int(line_data[2]) if uninherited else 0, (60000 if uninherited else -100) / float(line_data[1])])

					if next_timing.empty():
						next_timing = timing

					else:
						current_timing_data.append(timing.join(","))

		_f.close()

		## Comment
		var folder_path := file_path.get_base_dir()

		file_path = _fus
		if _f.open(file_path, File.WRITE):
			_load_finish("Unable to create temporary .fus file!")
			return

		_f.store_string(_csv_line([fus_version, folder_path.plus_file(bg_file_name), folder_path.plus_file(audio_filename)] + notes).join("\n"))
		_f.close()

	if not file_path.ends_with(".fus"):
		_load_finish("Invalid file!")
		return

	if _f.open(file_path, File.READ):
		_load_finish("Unable to read temporary .fus file!")
		return

	if _f.get_line() != fus_version:
		_load_finish("Outdated .fus file!")
		return

	## Comment
	var bg_file_path := _f.get_line()

	## Comment
	var image := Image.new()

	if image.load(bg_file_path):
		push_warning("Background failed to load: %s." % bg_file_path)

	else:
		## Comment
		var newtexture := ImageTexture.new()

		newtexture.create_from_image(image, 0)
		taiclone.bg_changed(newtexture, Color("373737"))

	music.stream = AudioLoader.loadfile(_f.get_line())
	_reset()

	## Comment
	var cur_bpm := -1.0

	while _f.get_position() < _f.get_len():
		## Comment
		var line := _f.get_csv_line()

		## Comment
		var total_cur_sv := float(line[1]) * cur_bpm * 5.7

		match int(line[2]):
			NoteType.BARLINE:
				## Comment
				var note_object := preload("res://scenes/gameplay/bar_line.tscn").instance() as BarLine

				note_object.change_properties(float(line[0]), total_cur_sv)
				add_object(note_object)

			NoteType.DON, NoteType.KAT:
				## Comment
				var note_object := preload("res://scenes/gameplay/note.tscn").instance() as Note

				note_object.change_properties(float(line[0]), total_cur_sv, int(line[2]) == int(NoteType.KAT), bool(int(line[3])))
				add_object(note_object)

			NoteType.ROLL:
				## Comment
				var note_object := preload("res://scenes/gameplay/roll.tscn").instance() as Roll

				note_object.change_properties(float(line[0]), total_cur_sv, float(line[3]), bool(int(line[4])), cur_bpm)
				add_object(note_object)

			NoteType.SPINNER:
				## Comment
				var note_object := preload("res://scenes/gameplay/spinner_warn.tscn").instance() as SpinnerWarn

				note_object.change_properties(float(line[0]), total_cur_sv, float(line[3]), cur_bpm)
				add_object(note_object)
				if note_object.connect("object_added", self, "add_object"):
					push_warning("Attempted to connect SpinnerWarn object_added.")

			NoteType.TIMING_POINT:
				cur_bpm = float(line[1])

	_load_finish("Done!")


## Comment
func _barline(total_cur_sv: float, notes: Array, next_barline: float, current_meter: int, cur_bpm: float) -> float:
	_append_note(notes, [next_barline, total_cur_sv, NoteType.BARLINE])
	return next_barline + 60 * current_meter / cur_bpm


## Comment
func _hit_notify_animation() -> void:
	_judgement_tween = Root.new_tween(_judgement_tween, self).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := _judgement_tween.tween_property(judgement, "modulate:a", 0.0, 0.4).from(1.0)


## Comment
func _load_finish(new_text: String) -> void:
	_f.close()
	emit_signal("debug_text", new_text)


## Comment
func _reset(dispose := true) -> void:
	_accurate_count = 0
	_inaccurate_count = 0
	_miss_count = 0
	_combo = 0
	_score = 0
	add_score(0)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "queue_free" if dispose else "activate")
	_cur_time = taiclone.global_offset / 1000.0


## Comment
static func _append_note(notes: Array, line: Array) -> void:
	notes.append(_csv_line(line).join(","))


## Comment
static func _csv_line(line: Array) -> PoolStringArray:
	## Comment
	var csv_line := []

	for item in line:
		csv_line.append(str(item))

	return PoolStringArray(csv_line)


## Comment
static func _find_value(value: String, line: String, key: String) -> String:
	return line.trim_prefix(key).strip_edges() if line.begins_with(key) else value
