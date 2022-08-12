class_name Gameplay
extends Node

signal new_marker(type, timing)

const CURRENT_CHART_DATA := {}

var acc_timing := 0.06
var inacc_timing := 0.145
var skin := SkinManager.new()

var _accurate_count := 0
var _auto := false
var _combo := 0
var _cur_bpm := -1.0
var _cur_time := 0.0
var _f := File.new()
var _inaccurate_count := 0
var _miss_count := 0
var _next_barline := -1.0
var _score := 0
var _score_multiplier := 1.0
var _total_cur_sv := -1.0

onready var settings := $"debug/SettingsPanel" as SettingsPanel

onready var music := $"Music" as AudioStreamPlayer

onready var _barline_obj := preload("res://game/objects/bar_line.tscn")
onready var _note_obj := preload("res://game/objects/note_object.tscn")
onready var _roll_obj := preload("res://game/objects/roll_object.tscn")
onready var _spin_warn_obj := preload("res://game/objects/spinner_warn_object.tscn")

onready var _bg := $"Background" as TextureRect

onready var _obj_container := $"BarRight/HitPointOffset/ObjectContainer" as Control

onready var _accurate_obj := $"BarRight/HitPointOffset/Judgements/JudgeAccurate" as CanvasItem
onready var _inaccurate_obj := $"BarRight/HitPointOffset/Judgements/JudgeInaccurate" as CanvasItem
onready var _miss_obj := $"BarRight/HitPointOffset/Judgements/JudgeMiss" as CanvasItem

onready var _l_don_obj := $"BarLeft/DrumVisual/LeftDon" as CanvasItem
onready var _l_kat_obj := $"BarLeft/DrumVisual/LeftKat" as CanvasItem
onready var _r_don_obj := $"BarLeft/DrumVisual/RightDon" as CanvasItem
onready var _r_kat_obj := $"BarLeft/DrumVisual/RightKat" as CanvasItem
onready var _combo_label := $"BarLeft/DrumVisual/Combo" as Label

onready var _score_label := $"UI/Score" as Label
onready var _accuracy_label := $"UI/Accuracy" as Label

onready var _debug_text := $"debug/debugtext" as Label
onready var _file_input := $"debug/temploadchart/LineEdit" as LineEdit
onready var _fps_text := $"debug/fpstext" as Label

onready var _l_don_aud := $"DrumInteraction/LeftDonAudio" as AudioStreamPlayer
onready var _l_kat_aud := $"DrumInteraction/LeftKatAudio" as AudioStreamPlayer
onready var _r_don_aud := $"DrumInteraction/RightDonAudio" as AudioStreamPlayer
onready var _r_kat_aud := $"DrumInteraction/RightKatAudio" as AudioStreamPlayer

onready var _tween := $"DrumInteraction/DrumAnimationTween" as Tween


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
		var obj: CanvasItem
		match str(input_action):
			"LeftDon":
				obj = _l_don_obj
				_l_don_aud.play()
			"LeftKat":
				obj = _l_kat_obj
				_l_kat_aud.play()
			"RightDon":
				obj = _r_don_obj
				_r_don_aud.play()
			"RightKat":
				obj = _r_kat_obj
				_r_kat_aud.play()
			_:
				push_warning("Unknown keypress animation.")
				return

		if not _tween.remove(obj, "self_modulate"):
			push_warning("Attempted to remove keypress animation tween.")
		if not _tween.interpolate_property(obj, "self_modulate", Color.white, Color.transparent, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT):
			push_warning("Attempted to tween keypress animation.")
		if not _tween.start():
			push_warning("Attempted to start keypress animation tween.")

	# check_input function
	for i in range(_obj_container.get_child_count()):
		var note = _obj_container.get_child(i)
		if note is BarLine or not note is HitObject:
			continue
		var new_inputs = note.hit(inputs.duplicate(), _cur_time + (inacc_timing if note is Note else 0.0))
		if str(inputs) == str(new_inputs):
			break
		var score := str(new_inputs.pop_back())
		if score == "finished":
			continue
		add_score(score)
		inputs = new_inputs # UNSAFE Variant
		if inputs.empty() or score == "miss":
			break


func _process(delta: float) -> void:
	_fps_text.text = "FPS: %s" % Engine.get_frames_per_second()

	if not music.playing:
		return
	_cur_time += delta

	# miss check
	for i in range(_obj_container.get_child_count()):
		var note = _obj_container.get_child(i)
		if not note is HitObject:
			continue
		var score := str(note.miss_check(_cur_time - (inacc_timing if note is Note else 0.0)))
		if note is BarLine or note is SpinnerWarn:
			continue
		if score == "":
			break
		if score == "finished":
			continue
		add_score(score)
		if score == "miss":
			emit_signal("new_marker", score, inacc_timing)


func add_score(type: String) -> void:
	if type.is_valid_float():
		var timing := float(type) - inacc_timing
		type = "accurate" if timing < acc_timing else "inaccurate" if timing < inacc_timing else "miss"
		emit_signal("new_marker", type, timing)

	_score += int((150 if type == "inaccurate" else 300 if ["accurate", "finisher", "roll"].has(type) else 600 if type == "spinner" else 0) * _score_multiplier)

	var obj: CanvasItem
	match type:
		"accurate":
			_accurate_count += 1
			_combo += 1
			obj = _accurate_obj
		"inaccurate":
			_inaccurate_count += 1
			_combo += 1
			obj = _inaccurate_obj
		"miss":
			_miss_count += 1
			_combo = 0
			obj = _miss_obj

	var hit_count := _accurate_count + _inaccurate_count / 2.0

	_combo_label.text = str(_combo)
	_score_label.text = "%010d" % _score
	_accuracy_label.text = "%2.2f" % (0.0 if hit_count == 0 else (hit_count * 100 / (_accurate_count + _inaccurate_count + _miss_count)))

	# hit_notify_animation function
	if obj == null:
		return

	if not _tween.remove(obj, "self_modulate"):
		push_warning("Attempted to remove hit animation tween.")
	if not _tween.interpolate_property(obj, "self_modulate", Color.white, Color.transparent, 0.4, Tween.TRANS_LINEAR, Tween.EASE_OUT):
		push_warning("Attempted to tween hit animation.")
	if not _tween.start():
		push_warning("Attempted to start hit animation tween.")


func auto_toggled(new_auto: bool) -> void:
	_auto = new_auto


func barline(time: float, equal := false) -> void:
	while true:
		var next_barline := int(_next_barline * 1000) / 1000.0
		if next_barline < time or (equal and next_barline == time):
			var note_object := _barline_obj.instance() as BarLine
			note_object.change_properties(next_barline, _total_cur_sv)
			_obj_container.add_child(note_object)
			note_object.add_to_group("HitObjects")
			_f.store_csv_line([str(next_barline), str(_total_cur_sv), "1"])
			_next_barline += 240 / _cur_bpm
		else:
			return


func find_value(section: String, key: String) -> String:
	for line in CURRENT_CHART_DATA[section]: # UNSAFE DictionaryItem
		if str(line).begins_with(key):
			return str(line).substr(key.length())
	return ""


func load_func() -> void:
	_debug_text.text = "Loading... [Checking File]"
	var file_path := _file_input.text.replace("\\", "/")
	if _f.open(file_path, File.READ) == OK:
		_debug_text.text = "Loading... [Reading File]"

		# load_and_process_all function
		# todo: make more adaptable between .osu and all file formats
		if file_path.ends_with(".osu"):
			# load chart file
			var file_in_text := _f.get_as_text()
			_f.close()
			CURRENT_CHART_DATA.clear()
			var section := ""
			CURRENT_CHART_DATA[section] = [] # UNSAFE DictionaryItem
			for line in file_in_text.split("\n", false):
				var line_str := str(line).strip_edges()
				if line_str.begins_with("[") and line_str.ends_with("]"):
					section = line_str.substr(1, line_str.length() - 2)
					CURRENT_CHART_DATA[section] = [] # UNSAFE DictionaryItem
				else:
					CURRENT_CHART_DATA[section].append(line_str) # UNSAFE DictionaryItem

			# load_and_process_background function
			var folder_path := file_path.get_base_dir()
			var events = CURRENT_CHART_DATA["Events"]
			var bg_file_name = events[events.find("//Background and Video events") + 1] # UNSAFE DictionaryItem
			var bg_file_path := folder_path.plus_file(str(bg_file_name).split(",")[2].replace("\"", ""))
			var image := Image.new()
			if image.load(bg_file_path) == OK:
				var newtexture := ImageTexture.new()
				newtexture.create_from_image(image, 0)
				_bg.texture = newtexture
			else:
				# Failed
				push_warning("Background failed to load: %s." % bg_file_path)

			# wipe_past_chart function
			reset()

			# load_and_process_chart function

			# get timing points
			var current_timing_data := []
			for timing in CURRENT_CHART_DATA["TimingPoints"]:
				var timing_array := str(timing).split(",") # split it to array
				var uninherited := bool(int(timing_array[6]))
				var time := float(timing_array[0]) / 1000
				var timing_value := (60000 if uninherited else -100) / float(timing_array[1])
				if uninherited and _cur_bpm < 0:
					_cur_bpm = timing_value
					_next_barline = time
				# store timing points in svArr, 0 = timing 1 = type 2 = value
				current_timing_data.append([time, int(timing_array[2]) if uninherited else 0, timing_value])

			# note speed is bpm * sv
			var map_sv_multiplier := float(find_value("Difficulty", "SliderMultiplier:"))

			var cur_sv := 1.0

			if _f.open("user://debug.fus", File.WRITE) != OK:
				_f.close()
				_debug_text.text = "Unable to create temporary .fus file."
				return
			_f.store_line("v0.0.1")

			# spawn notes
			for note_data in CURRENT_CHART_DATA["HitObjects"]:
				# split up the line by commas
				var note_array := str(note_data).split(",")

				# set timing
				var time := float(note_array[2]) / 1000

				# check sv
				if not current_timing_data.empty():
					var next_timing := float(current_timing_data[0][0]) # UNSAFE ArrayItem
					while next_timing <= time:
						barline(next_timing)
						var timing = current_timing_data.pop_front()
						if timing[1] == 0: # UNSAFE ArrayItem
							cur_sv = float(timing[2]) # UNSAFE ArrayItem
						else:
							_cur_bpm = float(timing[2]) # UNSAFE ArrayItem
							_next_barline = float(timing[0]) # UNSAFE ArrayItem
							_f.store_csv_line([str(_next_barline), str(_cur_bpm), "0"])
						if current_timing_data.empty():
							break
						next_timing = float(current_timing_data[0][0])

				# tee hee
				_total_cur_sv = _cur_bpm * cur_sv * map_sv_multiplier * 3

				barline(time, true)

				# figure out what kind of note it is
				# osu keeps type as an int that references bytes
				if 1 << 3 & int(note_array[3]): # spinner
					var length := float(note_array[5]) / 1000 - time
					var note_object := _spin_warn_obj.instance() as SpinnerWarn
					note_object.change_properties(time, _total_cur_sv, length, _cur_bpm)
					_obj_container.add_child(note_object)
					note_object.add_to_group("HitObjects")
					_f.store_csv_line([str(time), str(_total_cur_sv), "5", str(length)])
					continue

				# finisher check
				var finisher := bool(1 << 2 & int(note_array[4]))

				if 1 << 1 & int(note_array[3]): # roll
					var length := float(note_array[7]) * int(note_array[6]) * 600 / _total_cur_sv

					var note_object := _roll_obj.instance() as Roll
					note_object.change_properties(time, _total_cur_sv, length, finisher, _cur_bpm)
					_obj_container.add_child(note_object)
					note_object.add_to_group("HitObjects")
					_f.store_csv_line([str(time), str(_total_cur_sv), "4", str(length), str(finisher)])
					continue

				# normal note
				var note_type := int(bool(((1 << 1) + (1 << 3)) & int(note_array[4])))
				var note_object := _note_obj.instance() as Note
				note_object.change_properties(time, _total_cur_sv, note_type, finisher)
				_obj_container.add_child(note_object)
				note_object.add_to_group("HitObjects")
				_f.store_csv_line([str(time), str(_total_cur_sv), str(note_type + 2), str(finisher)])
			_f.close()
			get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "skin", skin)

			# load_and_process_song function
			# get audio file name and separate it in the file
			# load audio file and apply to song player
			music.stream = AudioLoader.loadfile(folder_path.plus_file(find_value("General", "AudioFilename: ")))

		else:
			_f.close()
			_debug_text.text = "Invalid file!"
			return

		_debug_text.text = "Done!"
	else:
		_f.close()
		_debug_text.text = "Invalid file!"


func offset_changed() -> void:
	# this is fundamentally flawed due to everything being scaled by 1.9
	# it's a close approximation but should be fixed once scaling is removed
	_obj_container.rect_position = Vector2(settings.global_offset * -775, 0)


func play_chart() -> void:
	reset()
	if music.playing:
		music.stop()
	else:
		music.play()


func reset() -> void:
	_accurate_count = 0
	_inaccurate_count = 0
	_miss_count = 0

	_combo = 0
	_score = 0
	_score_multiplier = 1
	add_score("")

	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "queue_free" if music.playing else "activate")
	_cur_time = settings.global_offset
