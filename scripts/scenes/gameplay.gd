class_name Gameplay
extends Node

signal reset

const CURRENT_CHART_DATA := {}

var cur_playing := false
var cur_time := 0.0

var acc_timing: float
var inacc_timing: float

var skin: SkinManager

onready var settings := $"debug/SettingsPanel" as SettingsPanel

onready var music := $"Music" as AudioStreamPlayer

onready var _barline_obj := preload("res://game/objects/bar_line.tscn")
onready var _note_obj := preload("res://game/objects/note_object.tscn")
onready var _roll_obj := preload("res://game/objects/roll_object.tscn")
onready var _spin_warn_obj := preload("res://game/objects/spinner_warn_object.tscn")

onready var _bg := $"Background" as TextureRect

onready var _obj_container := $"BarRight/HitPointOffset/ObjectContainers" as Control
onready var _etc_container := _obj_container.get_node("EtcContainer")
onready var _note_container := _obj_container.get_node("NoteContainer")

onready var _debug_text := $"debug/debugtext" as Label
onready var _file_input := $"debug/temploadchart/LineEdit" as LineEdit
onready var _fps_text := $"debug/fpstext" as Label


func _ready() -> void:
	acc_timing = 0.06
	inacc_timing = 0.145
	skin = SkinManager.new()


func _process(delta: float) -> void:
	if cur_playing:
		cur_time += delta
	_fps_text.text = "FPS: %s" % Engine.get_frames_per_second()


func find_value(key: String, section: String) -> String:
	for line in CURRENT_CHART_DATA[section]: # UNSAFE ArrayItem
		if str(line).begins_with(key):
			return str(line).substr(key.length())
	return ""


func load_func() -> void:
	_debug_text.text = "Loading... [Checking File]"
	var file_path := _file_input.text.replace("\\", "/")
	var f := File.new()
	if f.open(file_path, File.READ) == OK:
		_debug_text.text = "Loading... [Reading File]"

		# load_and_process_all function
		# todo: make more adaptable between .osu and all file formats
		if file_path.ends_with(".osu"):
			# load chart file
			var file_in_text := f.get_as_text()
			f.close()
			CURRENT_CHART_DATA.clear()
			var section := ""
			CURRENT_CHART_DATA[section] = [] # UNSAFE ArrayItem
			for line in file_in_text.split("\n", false):
				var line_str := str(line).strip_edges()
				if line_str.begins_with("[") and line_str.ends_with("]"):
					section = line_str.substr(1, line_str.length() - 2)
					CURRENT_CHART_DATA[section] = [] # UNSAFE ArrayItem
				else:
					CURRENT_CHART_DATA[section].append(line_str) # UNSAFE ArrayItem

			# load_and_process_background function
			var folder_path := file_path.get_base_dir()
			var events = CURRENT_CHART_DATA["Events"]
			var bg_file_name = events[events.find("//Background and Video events") + 1] # UNSAFE ArrayItem
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
			for sub_id in range(_obj_container.get_child_count()):
				var sub_container := _obj_container.get_child(sub_id)
				for note in range(sub_container.get_child_count()):
					sub_container.get_child(note).queue_free()
			emit_signal("reset")

			# load_and_process_chart function

			var cur_bpm := -1.0
			var next_barline := -1.0
			# get timing points
			var current_timing_data := []
			for timing in CURRENT_CHART_DATA["TimingPoints"]:
				var timing_array := str(timing).split(",") # split it to array
				var uninherited := bool(int(timing_array[6]))
				var time := float(timing_array[0]) / 1000
				var timing_value := (60000 if uninherited else -100) / float(timing_array[1])
				if uninherited and cur_bpm < 0:
					cur_bpm = timing_value
					next_barline = time
				# store timing points in svArr, 0 = timing 1 = type 2 = value
				current_timing_data.append([time, int(timing_array[2]) if uninherited else 0, timing_value])

			# note speed is bpm * sv
			var map_sv_multiplier := float(find_value("SliderMultiplier:", "Difficulty"))

			var cur_sv := 1.0

			var fus_file := File.new()
			var no_error := fus_file.open("user://debug.fus", File.WRITE) == OK
			if no_error:
				fus_file.store_line("v0.0.1")

			# tee hee
			var total_cur_sv := cur_bpm * cur_sv * map_sv_multiplier * 3

			# spawn notes
			var notes := []

			for note_data in CURRENT_CHART_DATA["HitObjects"]:
				# split up the line by commas
				var note_array := str(note_data).split(",")

				# set timing
				var time := float(note_array[2]) / 1000

				# check sv
				if not current_timing_data.empty():
					var next_timing := float(current_timing_data[0][0]) # UNSAFE ArrayItem
					while next_timing <= time:
						while next_barline < next_timing:
							var note_object := _barline_obj.instance() as BarLine
							note_object.change_properties(next_barline, total_cur_sv)
							_etc_container.add_child(note_object)
							note_object.add_to_group("HitObjects")
							if no_error:
								fus_file.store_csv_line([str(next_barline), str(total_cur_sv), "1"])
							next_barline += 240 / cur_bpm
						var timing = current_timing_data.pop_front()
						if timing[1] == 0: # UNSAFE ArrayItem
							cur_sv = float(timing[2]) # UNSAFE ArrayItem
						else:
							cur_bpm = float(timing[2]) # UNSAFE ArrayItem
							if no_error:
								fus_file.store_csv_line([str(timing[0]), str(cur_bpm), "0"]) # UNSAFE ArrayItem
						total_cur_sv = cur_bpm * cur_sv * map_sv_multiplier * 3
						if current_timing_data.empty():
							break
						next_timing = float(current_timing_data[0][0])

				while next_barline <= time:
					var note_object := _barline_obj.instance() as BarLine
					note_object.change_properties(next_barline, total_cur_sv)
					_etc_container.add_child(note_object)
					note_object.add_to_group("HitObjects")
					if no_error:
						fus_file.store_csv_line([str(next_barline), str(total_cur_sv), "1"])
					next_barline += 240 / cur_bpm

				# figure out what kind of note it is
				# osu keeps type as an int that references bytes
				if 1 << 3 & int(note_array[3]): # spinner
					var length := float(note_array[5]) / 1000 - time
					var note_object := _spin_warn_obj.instance() as SpinnerWarn
					note_object.change_properties(time, total_cur_sv, length, cur_bpm)
					_etc_container.add_child(note_object)
					note_object.add_to_group("HitObjects")
					if no_error:
						fus_file.store_csv_line([str(time), str(total_cur_sv), "5", str(length)])
					notes.append({"length": length, "noteType": 5, "time": time})
					continue

				# finisher check
				var finisher := bool(1 << 2 & int(note_array[4]))

				if 1 << 1 & int(note_array[3]): # roll
					var length := float(note_array[7]) * int(note_array[6]) * 600 / total_cur_sv

					var note_object := _roll_obj.instance() as Roll
					note_object.change_properties(time, total_cur_sv, length, finisher, cur_bpm)
					_etc_container.add_child(note_object)
					note_object.add_to_group("HitObjects")
					if no_error:
						fus_file.store_csv_line([str(time), str(total_cur_sv), "4", str(length), str(finisher)])
					notes.append({"finisher": finisher, "length": length, "noteType": 4, "time": time})
					continue

				# normal note
				var note_type := int(bool(((1 << 1) + (1 << 3)) & int(note_array[4]))) + 2
				var note_object := _note_obj.instance() as Note
				note_object.change_properties(time, total_cur_sv, note_type, finisher)
				_note_container.add_child(note_object)
				note_object.add_to_group("HitObjects")
				if no_error:
					fus_file.store_csv_line([str(time), str(total_cur_sv), str(note_type), str(finisher)])
				notes.append({"finisher": finisher, "noteType": note_type, "time": time})
			fus_file.close()

			# load_and_process_song function
			# get audio file name and separate it in the file
			# load audio file and apply to song player
			music.stream = AudioLoader.loadfile(folder_path.plus_file(find_value("AudioFilename: ", "General")))

		else:
			f.close()
			_debug_text.text = "Invalid file!"
			return

		_debug_text.text = "Done!"
	else:
		f.close()
		_debug_text.text = "Invalid file!"


func offset_changed() -> void:
	# this is fundamentally flawed due to everything being scaled by 1.9
	# it's a close approximation but should be fixed once scaling is removed
	_obj_container.rect_position = Vector2(settings.global_offset * -775, 0)


func play_chart() -> void:
	emit_signal("reset")
	if music.playing:
		music.stop()
	else:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "activate")
		cur_time = 0
		music.play()
	cur_playing = music.playing
	print_debug(cur_playing)
