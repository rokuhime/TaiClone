class_name Gameplay
extends Node

## Comment
signal new_marker(type, timing, skin)

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
var _drum_animation_tweens := [SceneTreeTween.new(), SceneTreeTween.new(), SceneTreeTween.new(), SceneTreeTween.new()]

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

## Comment
var _score_multiplier := 1.0

## Comment
var _timing_indicator_tween := SceneTreeTween.new()

onready var combo := $BarLeft/DrumVisual/Combo as Label
onready var debug_text := $debug/debugtext as Label
onready var fpstext := $debug/fpstext as Label
onready var judgement := $BarRight/HitPointOffset/Judgement as TextureRect
onready var line_edit := $debug/temploadchart/LineEdit as LineEdit
onready var music := $Music as AudioStreamPlayer
onready var obj_container := $BarRight/HitPointOffset/ObjectContainer as Control
onready var taiclone := $"/root" as Root
onready var timing_indicator := $BarLeft/TimingIndicator as Label
onready var ui_accuracy := $UI/Accuracy as Label
onready var ui_score := $UI/Score as Label


func _ready() -> void:
	late_early_changed()
	offset_changed()
	if _f.file_exists(_fus):
		load_func(_fus)


func _input(event: InputEvent) -> void:
	## Comment
	var inputs := []

	if event.is_action_pressed("LeftDon"):
		inputs.append("LeftDon")

	if event.is_action_pressed("LeftKat"):
		inputs.append("LeftKat")

	if event.is_action_pressed("RightDon"):
		inputs.append("RightDon")

	if event.is_action_pressed("RightKat"):
		inputs.append("RightKat")

	if inputs.empty():
		return

	for input_action in inputs:
		(get_node("DrumInteraction/%sAudio" % str(input_action)) as AudioStreamPlayer).play()

		## Comment
		var i := 0 if str(input_action) == "LeftDon" else 1 if str(input_action) == "LeftKat" else 2 if str(input_action) == "RightDon" else 3

		## Comment
		var tween: SceneTreeTween = Root.new_tween(_drum_animation_tweens[i], self).set_ease(Tween.EASE_OUT) # UNSAFE Variant

		## Comment
		var _tween := tween.tween_property(get_node("BarLeft/DrumVisual/" + str(input_action)), "self_modulate:a", 0.0, 0.2).from(1.0)

		_drum_animation_tweens[i] = tween # UNSAFE ArrayItem

	for i in range(obj_container.get_child_count()):
		## Comment
		var note = obj_container.get_child(i)

		if note is BarLine:
			continue

		## Comment
		var new_inputs: Array = note.hit(inputs.duplicate(), _cur_time + (taiclone.inacc_timing if note is Note else 0.0)) # UNSAFE Variant

		if inputs == new_inputs:
			break

		## Comment
		var scores: Array = new_inputs.pop_back() # UNSAFE Variant

		if scores == [HitObject.Score.FINISHED]:
			break

		for score in scores:
			_add_score(score) # UNSAFE Parameter
			if int(score) == int(HitObject.Score.MISS):
				return

		inputs = new_inputs
		if inputs.empty():
			break


func _process(delta: float) -> void:
	fpstext.text = "FPS: %s" % Engine.get_frames_per_second()
	if not music.playing:
		return

	_cur_time += delta
	for i in range(obj_container.get_child_count()):
		## Comment
		var note = obj_container.get_child(i)

		## Comment
		var score: int = note.miss_check(_cur_time - (taiclone.inacc_timing if note is Note else 0.0)) # UNSAFE Variant

		if note is BarLine or note is SpinnerWarn:
			continue

		if not score:
			break

		if score == int(HitObject.Score.FINISHED):
			continue

		_add_score(score)
		if score == int(HitObject.Score.MISS):
			emit_signal("new_marker", score, taiclone.inacc_timing, taiclone.skin)


## Comment
func auto_toggled(new_auto: bool) -> void:
	_auto = new_auto


## Comment
func change_indicator(timing: float) -> void:
	## Comment
	var num := str(int(timing * 1000))

	## Comment
	var late_early_simple_display := taiclone.late_early_simple_display < 2

	if timing > 0:
		timing_indicator.text = "LATE" if late_early_simple_display else "+" + num
		timing_indicator.modulate = taiclone.skin.late_color

	else:
		timing_indicator.text = "EARLY" if late_early_simple_display else num
		timing_indicator.modulate = taiclone.skin.early_color

	_timing_indicator_tween = Root.new_tween(_timing_indicator_tween, self).set_trans(Tween.TRANS_QUART)

	## Comment
	var _tween := _timing_indicator_tween.tween_property(timing_indicator, "self_modulate:a", 0.0, 0.5).from(1.0)


## Comment
func late_early_changed() -> void:
	timing_indicator.visible = taiclone.late_early_simple_display > 0


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
	var starting_bpm := -1.0

	if file_path.ends_with(".osu"):
		## Comment
		var file_in_text := _f.get_as_text()

		_f.close()

		## Comment
		var section := ""

		## Comment
		var current_chart_data := {section: []}

		for line in file_in_text.split("\n", false):
			## Comment
			var line_str := str(line).strip_edges()

			if line_str.begins_with("[") and line_str.ends_with("]"):
				section = line_str.substr(1, line_str.length() - 2)
				current_chart_data[section] = [] # UNSAFE DictionaryItem

			else:
				current_chart_data[section].append(line_str) # UNSAFE DictionaryItem

		## Comment
		var folder_path := file_path.get_base_dir()

		file_path = _fus
		if _f.open(file_path, File.WRITE):
			_load_finish("Unable to create temporary .fus file!")
			return

		_f.store_line("v0.0.1")

		## Comment
		var events = current_chart_data["Events"]

		## Comment
		var bg_file_name: String = events[events.find("//Background and Video events") + 1] # UNSAFE Variant

		_f.store_line(folder_path.plus_file(bg_file_name.split(",")[2].replace("\"", "")))
		_f.store_line(folder_path.plus_file(_find_value("General", "AudioFilename: ", current_chart_data)))

		## Comment
		var next_barline := -1.0

		## Comment
		var current_timing_data := []

		for timing in current_chart_data["TimingPoints"]:
			## Comment
			var timing_array := str(timing).split(",") # split it to array

			## Comment
			var uninherited := bool(int(timing_array[6]))

			## Comment
			var time := float(timing_array[0]) / 1000

			## Comment
			var timing_value := (60000 if uninherited else -100) / float(timing_array[1])

			if uninherited and starting_bpm < 0:
				starting_bpm = timing_value
				next_barline = time

			current_timing_data.append([time, int(timing_array[2]) if uninherited else 0, timing_value])

		## Comment
		var map_sv_multiplier := float(_find_value("Difficulty", "SliderMultiplier:", current_chart_data))

		## Comment
		var cur_bpm := starting_bpm

		## Comment
		var cur_sv := 1.0

		## Comment
		var total_cur_sv := -1.0

		for note_data in current_chart_data["HitObjects"]:
			## Comment
			var note_array := str(note_data).split(",")

			## Comment
			var time := float(note_array[2]) / 1000

			if not current_timing_data.empty():
				while true:
					## Comment
					var next_timing: float = current_timing_data[0][0] # UNSAFE Variant

					if next_timing > time:
						break

					next_barline = _barline(total_cur_sv, next_timing, next_barline, cur_bpm)

					## Comment
					var timing: Array = current_timing_data.pop_front() # UNSAFE Variant

					if int(timing[1]):
						cur_bpm = float(timing[2])
						next_barline = float(timing[0])
						_f.store_csv_line([str(next_barline), str(cur_bpm), str(NoteType.TIMING_POINT)])

					else:
						cur_sv = float(timing[2])

					if current_timing_data.empty():
						break

			total_cur_sv = cur_bpm * cur_sv * map_sv_multiplier * 3
			next_barline = _barline(total_cur_sv, time, next_barline, cur_bpm, true)
			if 1 << 3 & int(note_array[3]): # spinner
				_f.store_csv_line([str(time), str(total_cur_sv), str(NoteType.SPINNER), str(float(note_array[5]) / 1000 - time)])
				continue

			## Comment
			var finisher := 1 << 2 & int(note_array[4])

			if 1 << 1 & int(note_array[3]): # roll
				_f.store_csv_line([str(time), str(total_cur_sv), str(NoteType.ROLL), str(float(note_array[7]) * int(note_array[6]) * 1.8 / total_cur_sv), str(finisher)])

			else:
				_f.store_csv_line([str(time), str(total_cur_sv), str(NoteType.KAT if bool(((1 << 1) + (1 << 3)) & int(note_array[4])) else NoteType.DON), str(finisher)])

		_f.close()

	if not file_path.ends_with(".fus"):
		_load_finish("Invalid file!")
		return

	if _f.open(file_path, File.READ):
		_load_finish("Unable to read temporary .fus file!")
		return

	if _f.get_line() != "v0.0.1":
		_load_finish("Outdated .fus file!")

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
	var cur_bpm := starting_bpm

	while true:
		## Comment
		var line := _f.get_csv_line()

		if Array(line) == [""]:
			break

		match int(line[2]):
			NoteType.BARLINE:
				## Comment
				var note_object := preload("res://scenes/gameplay/bar_line.tscn").instance() as BarLine
				note_object.change_properties(float(line[0]), float(line[1]))
				_add_note(note_object)

			NoteType.DON, NoteType.KAT:
				## Comment
				var note_object := preload("res://scenes/gameplay/note_object.tscn").instance() as Note
				note_object.change_properties(float(line[0]), float(line[1]), int(line[2]) == int(NoteType.KAT), bool(int(line[3])))
				_add_note(note_object)

			NoteType.ROLL:
				## Comment
				var note_object := preload("res://scenes/gameplay/roll_object.tscn").instance() as Roll
				note_object.change_properties(float(line[0]), float(line[1]), float(line[3]), bool(int(line[4])), cur_bpm)
				_add_note(note_object)

			NoteType.SPINNER:
				## Comment
				var note_object := preload("res://scenes/gameplay/spinner_warn_object.tscn").instance() as SpinnerWarn
				note_object.change_properties(float(line[0]), float(line[1]), float(line[3]), cur_bpm)
				_add_note(note_object)

			NoteType.TIMING_POINT:
				cur_bpm = float(line[1])

	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "skin", taiclone.skin)
	_load_finish("Done!")


## Comment
func offset_changed() -> void:
	# TODO: Remove 1.9 scaling
	obj_container.rect_position = Vector2(taiclone.global_offset * -0.775, 0)


## Comment
func play_chart() -> void:
	_reset(music.playing)
	if music.playing:
		music.stop()

	else:
		music.play()


## Comment
func _add_note(note_object: Node) -> void:
	obj_container.add_child(note_object)
	note_object.add_to_group("HitObjects")


## Comment
func _add_score(type) -> void:
	if type is float:
		## Comment
		var timing := float(type) - taiclone.inacc_timing

		type = HitObject.Score.ACCURATE if timing < taiclone.acc_timing else HitObject.Score.INACCURATE if timing < taiclone.inacc_timing else HitObject.Score.MISS
		emit_signal("new_marker", type, timing, taiclone.skin)

	_score += int((150 if int(type) == int(HitObject.Score.INACCURATE) else 300 if [HitObject.Score.ACCURATE, HitObject.Score.FINISHER, HitObject.Score.ROLL].has(int(type)) else 600 if int(type) == int(HitObject.Score.SPINNER) else 0) * _score_multiplier)
	match int(type):
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

	## Comment
	var hit_count := _accurate_count + _inaccurate_count / 2.0

	combo.text = str(_combo)
	ui_score.text = "%010d" % _score
	ui_accuracy.text = "%2.2f" % (0.0 if hit_count == 0 else (hit_count * 100 / (_accurate_count + _inaccurate_count + _miss_count)))


## Comment
func _barline(total_cur_sv: float, time: float, next_barline: float, cur_bpm: float, equal := false) -> float:
	while true:
		## Comment
		var barline := int(next_barline * 1000) / 1000.0

		if barline < time or (equal and barline == time):
			_f.store_csv_line([str(barline), str(total_cur_sv), str(NoteType.BARLINE)])
			next_barline += 240 / cur_bpm

		else:
			break

	return next_barline


## Comment
func _find_value(section: String, key: String, current_chart_data: Dictionary) -> String:
	for line in current_chart_data[section]: # UNSAFE DictionaryItem
		if str(line).begins_with(key):
			return str(line).substr(key.length())

	return ""


## Comment
func _hit_notify_animation() -> void:
	_judgement_tween = Root.new_tween(_judgement_tween, self).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := _judgement_tween.tween_property(judgement, "self_modulate:a", 0.0, 0.4).from(1.0)


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
	_score_multiplier = 1
	_add_score(0)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "queue_free" if dispose else "activate")
	_cur_time = taiclone.global_offset / 1000.0
