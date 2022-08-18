extends Node

signal new_marker(type, timing, skin)

enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

var _accurate_count := 0
var _auto := false
var _combo := 0
var _cur_time := 0.0
var _drum_animation_tweens := [SceneTreeTween.new(), SceneTreeTween.new(), SceneTreeTween.new(), SceneTreeTween.new()]
var _f := File.new()
var _fus := "user://debug.fus"
var _inaccurate_count := 0
var _judgement_tween := SceneTreeTween.new()
var _late_early_simple_display := true
var _miss_count := 0
var _score := 0
var _score_multiplier := 1.0
var _skin := SkinManager.new()
var _timing_indicator_tween := SceneTreeTween.new()

onready var debug_text := $debug/debugtext as Label
onready var hit_error := $UI/HitError as HitError
onready var judgement := $BarRight/HitPointOffset/Judgement as TextureRect
onready var music := $Music as AudioStreamPlayer
onready var obj_container := $BarRight/HitPointOffset/ObjectContainer as Control
onready var timing_indicator := $BarLeft/TimingIndicator as Label


func _ready() -> void:
	if _f.file_exists(_fus):
		load_func(_fus)


func _input(event: InputEvent) -> void:
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

	# keypress_animation function
	for input_action in inputs:
		(get_node("DrumInteraction/%sAudio" % str(input_action)) as AudioStreamPlayer).play()

		var i := 0 if str(input_action) == "LeftDon" else 1 if str(input_action) == "LeftKat" else 2 if str(input_action) == "RightDon" else 3

		var tween := _new_tween(_drum_animation_tweens[i]).set_ease(Tween.EASE_OUT)
		var _tween := tween.tween_property(get_node("BarLeft/DrumVisual/" + str(input_action)), "self_modulate", Color.transparent, 0.2).from(Color.white)
		_drum_animation_tweens[i] = tween # UNSAFE ArrayItem

	# check_input function
	for i in range(obj_container.get_child_count()):
		var note = obj_container.get_child(i)
		if note is BarLine or not note is HitObject:
			continue
		var new_inputs: Array = note.hit(inputs.duplicate(), _cur_time + (hit_error.inacc_timing if note is Note else 0.0))
		if inputs == new_inputs:
			break
		var scores: Array = new_inputs.pop_back() # UNSAFE Variant
		if scores == [HitObject.Score.FINISHED]:
			break
		for score in scores:
			_add_score(score)
			if int(score) == HitObject.Score.MISS:
				return
		inputs = new_inputs
		if inputs.empty():
			break


func _process(delta: float) -> void:
	($debug/fpstext as Label).text = "FPS: %s" % Engine.get_frames_per_second()

	if not music.playing:
		return
	_cur_time += delta

	# miss check
	for i in range(obj_container.get_child_count()):
		var note = obj_container.get_child(i)
		if not note is HitObject:
			continue
		var score := int(note.miss_check(_cur_time - (hit_error.inacc_timing if note is Note else 0.0)))
		if note is BarLine or note is SpinnerWarn:
			continue
		if not score:
			break
		if score == HitObject.Score.FINISHED:
			continue
		_add_score(score)
		if score == HitObject.Score.MISS:
			emit_signal("new_marker", score, hit_error.inacc_timing, _skin)


func auto_toggled(new_auto: bool) -> void:
	_auto = new_auto


func change_indicator(timing: float) -> void:
	var num := str(int(timing * 1000))
	if timing > 0:
		timing_indicator.text = "LATE" if _late_early_simple_display else "+" + num
		timing_indicator.modulate = Color("5a5aff")
	else:
		timing_indicator.text = "EARLY" if _late_early_simple_display else num
		timing_indicator.modulate = Color("ff5a5a")

	_timing_indicator_tween = _new_tween(_timing_indicator_tween).set_trans(Tween.TRANS_QUART)
	var _tween := _timing_indicator_tween.tween_property(timing_indicator, "self_modulate", Color.transparent, 0.5).from(Color.white)


func late_early_changed(new_value: int) -> void:
	_late_early_simple_display = new_value < 2
	timing_indicator.visible = new_value > 0


func load_func(file_path := "") -> void:
	debug_text.text = "Loading... [Checking File]"
	if file_path == "":
		file_path = ($debug/temploadchart/LineEdit as LineEdit).text.replace("\\", "/")
	if _f.open(file_path, File.READ):
		_load_finish("Invalid file!")
		return
	debug_text.text = "Loading... [Reading File]"

	var starting_bpm := -1.0

	# load_and_process_all function
	if file_path.ends_with(".osu"):
		# load chart file
		var file_in_text := _f.get_as_text()
		_f.close()
		var section := ""
		var current_chart_data := {section: []}
		for line in file_in_text.split("\n", false):
			var line_str := str(line).strip_edges()
			if line_str.begins_with("[") and line_str.ends_with("]"):
				section = line_str.substr(1, line_str.length() - 2)
				current_chart_data[section] = [] # UNSAFE DictionaryItem
			else:
				current_chart_data[section].append(line_str) # UNSAFE DictionaryItem

		var folder_path := file_path.get_base_dir()
		file_path = _fus
		if _f.open(file_path, File.WRITE):
			_load_finish("Unable to create temporary .fus file!")
			return
		_f.store_line("v0.0.1")

		# load_and_process_background function
		var events = current_chart_data["Events"]
		var bg_file_name: String = events[events.find("//Background and Video events") + 1] # UNSAFE Variant
		_f.store_line(folder_path.plus_file(bg_file_name.split(",")[2].replace("\"", "")))

		# load_and_process_song function
		# get audio file name and separate it in the file
		_f.store_line(folder_path.plus_file(_find_value("General", "AudioFilename: ", current_chart_data)))

		# load_and_process_chart function
		var next_barline := -1.0

		# get timing points
		var current_timing_data := []
		for timing in current_chart_data["TimingPoints"]:
			var timing_array := str(timing).split(",") # split it to array
			var uninherited := bool(int(timing_array[6]))
			var time := float(timing_array[0]) / 1000
			var timing_value := (60000 if uninherited else -100) / float(timing_array[1])
			if uninherited and starting_bpm < 0:
				starting_bpm = timing_value
				next_barline = time
			# store timing points in svArr, 0 = timing 1 = type 2 = value
			current_timing_data.append([time, int(timing_array[2]) if uninherited else 0, timing_value])

		# note speed is bpm * sv
		var map_sv_multiplier := float(_find_value("Difficulty", "SliderMultiplier:", current_chart_data))

		var cur_bpm := starting_bpm
		var cur_sv := 1.0
		var total_cur_sv := -1.0

		# spawn notes
		for note_data in current_chart_data["HitObjects"]:
			# split up the line by commas
			var note_array := str(note_data).split(",")

			# set timing
			var time := float(note_array[2]) / 1000

			# check sv
			if not current_timing_data.empty():
				var next_timing: float = current_timing_data[0][0] # UNSAFE Variant
				while next_timing <= time:
					next_barline = _barline(total_cur_sv, next_timing, next_barline, cur_bpm)
					var timing: Array = current_timing_data.pop_front() # UNSAFE Variant
					if int(timing[1]):
						cur_bpm = float(timing[2])
						next_barline = float(timing[0])
						_f.store_csv_line([str(next_barline), str(cur_bpm), str(NoteType.TIMING_POINT)])
					else:
						cur_sv = float(timing[2])
					if current_timing_data.empty():
						break
					next_timing = float(current_timing_data[0][0])

			# tee hee
			total_cur_sv = cur_bpm * cur_sv * map_sv_multiplier * 3

			next_barline = _barline(total_cur_sv, time, next_barline, cur_bpm, true)

			# figure out what kind of note it is
			# osu keeps type as an int that references bytes
			if 1 << 3 & int(note_array[3]): # spinner
				_f.store_csv_line([str(time), str(total_cur_sv), str(NoteType.SPINNER), str(float(note_array[5]) / 1000 - time)])
				continue

			# finisher check
			var finisher := 1 << 2 & int(note_array[4])

			if 1 << 1 & int(note_array[3]): # roll
				_f.store_csv_line([str(time), str(total_cur_sv), str(NoteType.ROLL), str(float(note_array[7]) * int(note_array[6]) * 1.8 / total_cur_sv), str(finisher)])
				continue

			# normal note
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

	# load_and_process_background function
	var bg_file_path := _f.get_line()
	var image := Image.new()
	if image.load(bg_file_path):
		push_warning("Background failed to load: %s." % bg_file_path)
	else:
		var newtexture := ImageTexture.new()
		newtexture.create_from_image(image, 0)
		($Background as TextureRect).texture = newtexture

	# load_and_process_song function
	# load audio file and apply to song player
	music.stream = AudioLoader.loadfile(_f.get_line())

	# wipe_past_chart function
	_reset()

	# load_and_process_chart function
	var cur_bpm := starting_bpm
	while true:
		var line := _f.get_csv_line()
		if Array(line) == [""]:
			break
		var note_node: Node
		match int(line[2]):
			NoteType.BARLINE:
				var note_object := preload("res://game/objects/gameplay/bar_line.tscn").instance() as BarLine
				note_object.change_properties(float(line[0]), float(line[1]))
				note_node = note_object
			NoteType.DON, NoteType.KAT:
				var note_object := preload("res://game/objects/gameplay/note_object.tscn").instance() as Note
				note_object.change_properties(float(line[0]), float(line[1]), int(line[2]) == NoteType.KAT, bool(int(line[3])))
				note_node = note_object
			NoteType.ROLL:
				var note_object := preload("res://game/objects/gameplay/roll_object.tscn").instance() as Roll
				note_object.change_properties(float(line[0]), float(line[1]), float(line[3]), bool(int(line[4])), cur_bpm)
				note_node = note_object
			NoteType.SPINNER:
				var note_object := preload("res://game/objects/gameplay/spinner_warn_object.tscn").instance() as SpinnerWarn
				note_object.change_properties(float(line[0]), float(line[1]), float(line[3]), cur_bpm)
				note_node = note_object
			NoteType.TIMING_POINT:
				cur_bpm = float(line[1])
				continue
		obj_container.add_child(note_node)
		if note_node != null:
			note_node.add_to_group("HitObjects")

	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "skin", _skin)
	_load_finish("Done!")


func offset_changed(new_value: float) -> void:
	# this is fundamentally flawed due to everything being scaled by 1.9
	# it's a close approximation but should be fixed once scaling is removed
	obj_container.rect_position = Vector2(new_value * -775, 0)


func play_chart() -> void:
	_reset(music.playing)
	if music.playing:
		music.stop()
	else:
		music.play()


func _add_score(type) -> void:
	if type is float:
		var timing := float(type) - hit_error.inacc_timing
		type = HitObject.Score.ACCURATE if timing < hit_error.acc_timing else HitObject.Score.INACCURATE if timing < hit_error.inacc_timing else HitObject.Score.MISS
		emit_signal("new_marker", type, timing, _skin)

	_score += int((150 if int(type) == HitObject.Score.INACCURATE else 300 if [HitObject.Score.ACCURATE, HitObject.Score.FINISHER, HitObject.Score.ROLL].has(int(type)) else 600 if int(type) == HitObject.Score.SPINNER else 0) * _score_multiplier)

	match int(type):
		HitObject.Score.ACCURATE:
			_accurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = _skin.accurate_judgement
		HitObject.Score.INACCURATE:
			_inaccurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = _skin.inaccurate_judgement
		HitObject.Score.MISS:
			_miss_count += 1
			_combo = 0
			_hit_notify_animation()
			judgement.texture = _skin.miss_judgement

	var hit_count := _accurate_count + _inaccurate_count / 2.0

	($BarLeft/DrumVisual/Combo as Label).text = str(_combo)
	($UI/Score as Label).text = "%010d" % _score
	($UI/Accuracy as Label).text = "%2.2f" % (0.0 if hit_count == 0 else (hit_count * 100 / (_accurate_count + _inaccurate_count + _miss_count)))


func _barline(total_cur_sv: float, time: float, next_barline: float, cur_bpm: float, equal := false) -> float:
	while true:
		var barline := int(next_barline * 1000) / 1000.0
		if barline < time or (equal and barline == time):
			_f.store_csv_line([str(barline), str(total_cur_sv), str(NoteType.BARLINE)])
			next_barline += 240 / cur_bpm
		else:
			break
	return next_barline


func _load_finish(new_text: String) -> void:
	_f.close()
	debug_text.text = new_text


func _find_value(section: String, key: String, current_chart_data: Dictionary) -> String:
	for line in current_chart_data[section]: # UNSAFE DictionaryItem
		if str(line).begins_with(key):
			return str(line).substr(key.length())
	return ""


func _hit_notify_animation() -> void:
	_judgement_tween = _new_tween(_judgement_tween).set_ease(Tween.EASE_OUT)
	var _tween := _judgement_tween.tween_property(judgement, "self_modulate", Color.transparent, 0.4).from(Color.white)


# Stop a previous tween and return the new tween to use going forward.
func _new_tween(old_tween: SceneTreeTween) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return create_tween()


func _reset(dispose := true) -> void:
	_accurate_count = 0
	_inaccurate_count = 0
	_miss_count = 0

	_combo = 0
	_score = 0
	_score_multiplier = 1
	_add_score(0)

	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "queue_free" if dispose else "activate")
	_cur_time = ($debug/SettingsPanel as SettingsPanel).global_offset
