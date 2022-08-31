class_name Gameplay
extends Node

## Comment
signal marker_added(type, timing)

## Comment
enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

## Comment
var _accurate_count := 0

## Comment
var _auto := false

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
var _l_don_tween := SceneTreeTween.new()

## Comment
var _l_kat_tween := SceneTreeTween.new()

## Comment
var _miss_count := 0

## Comment
var _r_don_tween := SceneTreeTween.new()

## Comment
var _r_kat_tween := SceneTreeTween.new()

## Comment
var _score := 0

## Comment
var _timing_indicator_tween := SceneTreeTween.new()

onready var combo := $BarLeft/DrumVisual/Combo as Label
onready var debug_text := $Debug/DebugText as Label
onready var f_don_aud := $FinisherDonAudio as AudioStreamPlayer
onready var f_kat_aud := $FinisherKatAudio as AudioStreamPlayer
onready var fpstext := $Debug/TempLoadChart/Text/FPS as Label
onready var judgement := $BarLeft/Judgement as TextureRect
onready var l_don_aud := $LeftDonAudio as AudioStreamPlayer
onready var l_don_obj := $BarLeft/DrumVisual/LeftDon as CanvasItem
onready var l_kat_aud := $LeftKatAudio as AudioStreamPlayer
onready var l_kat_obj := $BarLeft/DrumVisual/LeftKat as CanvasItem
onready var line_edit := $Debug/TempLoadChart/LineEdit as LineEdit
onready var music := $Music as AudioStreamPlayer
onready var obj_container := $BarLeft/ObjectContainer as Control
onready var r_don_aud := $RightDonAudio as AudioStreamPlayer
onready var r_don_obj := $BarLeft/DrumVisual/RightDon as CanvasItem
onready var r_kat_aud := $RightKatAudio as AudioStreamPlayer
onready var r_kat_obj := $BarLeft/DrumVisual/RightKat as CanvasItem
onready var root_viewport := $"/root" as Root
onready var timing_indicator := $BarLeft/TimingIndicator as Label
onready var ui_accuracy := $UI/Accuracy/Label as Label
onready var ui_score := $UI/Score as Label


func _ready() -> void:
	Root.send_signal(self, "late_early_changed", root_viewport, "late_early_changed")
	late_early_changed()
	l_don_obj.modulate.a = 0
	l_kat_obj.modulate.a = 0
	r_don_obj.modulate.a = 0
	r_kat_obj.modulate.a = 0
	_reset()

	#dev autoload map
#	if _f.file_exists(_fus):
#		load_func(_fus)


func _process(delta: float) -> void:
	fpstext.text = "FPS: %s" % Engine.get_frames_per_second()
	if not music.playing:
		return

	_cur_time += delta
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var note := obj_container.get_child(i) as HitObject

		if note.miss_check(_cur_time - (HitError.INACC_TIMING if note is Note else 0.0)):
			break


## Comment
func _unhandled_input(event: InputEvent) -> void:
	## Comment
	var inputs := [2]

	for key in Root.KEYS:
		if event.is_action_pressed(str(key)):
			inputs.append(str(key))
			match str(key):
				"LeftDon":
					_l_don_tween = _keypress_animation(_l_don_tween, l_don_obj)

				"LeftKat":
					_l_kat_tween = _keypress_animation(_l_kat_tween, l_kat_obj)

				"RightDon":
					_r_don_tween = _keypress_animation(_r_don_tween, r_don_obj)

				"RightKat":
					_r_kat_tween = _keypress_animation(_r_kat_tween, r_kat_obj)

	if Root.inputs_empty(inputs):
		return

	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var note := obj_container.get_child(i) as HitObject

		if note.hit(inputs, _cur_time + (HitError.INACC_TIMING if note is Note else 0.0)) or Root.inputs_empty(inputs):
			break

	for key in inputs:
		play_audio(str(key))


## Comment
func add_marker(timing: float, add: bool) -> void:
	timing -= HitError.INACC_TIMING

	var type := int(HitObject.Score.ACCURATE if abs(timing) < HitError.ACC_TIMING else HitObject.Score.INACCURATE if abs(timing) < HitError.INACC_TIMING else HitObject.Score.MISS)

	emit_signal("marker_added", type, timing)
	if add:
		add_score(type)


## Comment
func add_object(obj: HitObject, loaded := true) -> void:
	obj_container.add_child(obj)
	for i in range(obj_container.get_child_count()):
		if obj.end_time > (obj_container.get_child(i) as HitObject).end_time:
			obj_container.move_child(obj, i)
			break

	if loaded:
		return

	obj.apply_skin(root_viewport.skin)
	Root.send_signal(self, "audio_played", obj, "play_audio")
	Root.send_signal(self, "score_added", obj, "add_score")


## Comment
func add_score(type: int, marker := false) -> void:
	_score += 150 if type == int(HitObject.Score.INACCURATE) else 300 if [HitObject.Score.ACCURATE, HitObject.Score.FINISHER, HitObject.Score.ROLL].has(type) else 600 if type == int(HitObject.Score.SPINNER) else 0
	match type:
		HitObject.Score.ACCURATE:
			_accurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = root_viewport.skin.accurate_judgement

		HitObject.Score.INACCURATE:
			_inaccurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = root_viewport.skin.inaccurate_judgement

		HitObject.Score.MISS:
			_miss_count += 1
			_combo = 0
			_hit_notify_animation()
			judgement.texture = root_viewport.skin.miss_judgement
			if marker:
				emit_signal("marker_added", type, HitError.INACC_TIMING)

	## Comment
	var hit_count := _accurate_count + _inaccurate_count / 2.0

	combo.text = str(_combo)
	ui_score.text = "%010d" % _score
	ui_accuracy.text = "%2.2f" % (hit_count * 100 / (_accurate_count + _inaccurate_count + _miss_count) if hit_count else 0.0)


## Comment
func auto_toggled(new_auto: bool) -> void:
	_auto = new_auto


## Comment
func change_indicator(timing: float) -> void:
	timing_indicator.text = ("LATE" if timing > 0 else "EARLY") if root_viewport.late_early_simple_display < 2 else "%+d" % int(timing * 1000)
	timing_indicator.modulate = root_viewport.skin.late_color if timing > 0 else root_viewport.skin.early_color
	_timing_indicator_tween = root_viewport.new_tween(_timing_indicator_tween).set_trans(Tween.TRANS_QUART)

	## Comment
	var _tween := _timing_indicator_tween.tween_property(timing_indicator, "self_modulate:a", 0.0, 0.5).from(1.0)


## Comment
func late_early_changed() -> void:
	timing_indicator.visible = root_viewport.late_early_simple_display > 0


## Comment
func load_func(file_path := "") -> void:
	debug_text.text = "Loading... [Checking File]"
	if file_path == "":
		file_path = line_edit.text.replace("\\", "/")

	if _f.open(file_path, File.READ):
		_load_finish("Invalid file!")
		return

	debug_text.text = "Loading... [Reading File]"

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
		root_viewport.bg_changed(newtexture, Color("373737"))

	music.stream = AudioLoader.loadfile(_f.get_line())
	_reset()

	## Comment
	var cur_bpm := -1.0

	while _f.get_position() < _f.get_len():
		## Comment
		var line := _f.get_csv_line()

		## Comment
		var timing := float(line[0]) + root_viewport.global_offset / 1000.0

		## Comment
		var total_cur_sv := float(line[1]) * cur_bpm * 5.7

		match int(line[2]):
			NoteType.BARLINE:
				## Comment
				var note_object := preload("res://scenes/gameplay/bar_line.tscn").instance() as BarLine

				note_object.change_properties(timing, total_cur_sv)
				add_object(note_object)

			NoteType.DON, NoteType.KAT:
				## Comment
				var note_object := preload("res://scenes/gameplay/note.tscn").instance() as Note

				note_object.change_properties(timing, total_cur_sv, int(line[2]) == int(NoteType.KAT), bool(int(line[3])))
				add_object(note_object)
				Root.send_signal(self, "new_marker_added", note_object, "add_marker")

			NoteType.ROLL:
				## Comment
				var note_object := preload("res://scenes/gameplay/roll.tscn").instance() as Roll

				note_object.change_properties(timing, total_cur_sv, float(line[3]), bool(int(line[4])), cur_bpm)
				add_object(note_object)

			NoteType.SPINNER:
				## Comment
				var note_object := preload("res://scenes/gameplay/spinner_warn.tscn").instance() as SpinnerWarn

				note_object.change_properties(timing, total_cur_sv, float(line[3]), cur_bpm)
				add_object(note_object)
				Root.send_signal(self, "object_added", note_object, "add_object")

			NoteType.TIMING_POINT:
				cur_bpm = float(line[1])

	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "apply_skin", root_viewport.skin)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "connect", "audio_played", self, "play_audio")
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "connect", "score_added", self, "add_score")
	_load_finish("Done!")


## Comment
func play_audio(key: String) -> void:
	match key:
		"FinisherDon":
			f_don_aud.play()

		"FinisherKat":
			f_kat_aud.play()

		"LeftDon":
			l_don_aud.play()

		"LeftKat":
			l_kat_aud.play()

		"RightDon":
			r_don_aud.play()

		"RightKat":
			r_kat_aud.play()


## Comment
func play_chart() -> void:
	_reset(music.playing)
	music.stop()

	if not music.playing:
		music.play()


## Comment
func text_debug(text: String) -> void:
	debug_text.text = text


## Comment
func toggle_settings() -> void:
	if not root_viewport.remove_scene("SettingsPanel"):
		root_viewport.add_scene(preload("res://scenes/root/settings_panel.tscn").instance(), name)


## Comment
static func _append_note(notes: Array, line: Array) -> void:
	notes.append(_csv_line(line).join(","))


## Comment
static func _barline(total_cur_sv: float, notes: Array, next_barline: float, current_meter: int, cur_bpm: float) -> float:
	_append_note(notes, [next_barline, total_cur_sv, NoteType.BARLINE])
	return next_barline + 60 * current_meter / cur_bpm


## Comment
static func _csv_line(line: Array) -> PoolStringArray:
	## Comment
	var csv_line := []

	for key in line:
		csv_line.append(str(key))

	return PoolStringArray(csv_line)


## Comment
static func _find_value(value: String, line: String, key: String) -> String:
	return line.trim_prefix(key).strip_edges() if line.begins_with(key) else value


## Comment
func _hit_notify_animation() -> void:
	_judgement_tween = root_viewport.new_tween(_judgement_tween).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := _judgement_tween.tween_property(judgement, "modulate:a", 0.0, 0.4).from(1.0)


## Comment
func _keypress_animation(tween: SceneTreeTween, obj: CanvasItem) -> SceneTreeTween:
	tween = root_viewport.new_tween(tween).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := tween.tween_property(obj, "modulate:a", 0.0, 0.2).from(1.0)

	return tween


## Comment
func _load_finish(new_text: String) -> void:
	_f.close()
	debug_text.text = new_text


## Comment
func _reset(dispose := true) -> void:
	_accurate_count = 0
	_inaccurate_count = 0
	_miss_count = 0
	_combo = 0
	_score = 0
	add_score(-1)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "queue_free" if dispose else "activate")
	_cur_time = 0
