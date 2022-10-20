extends Node

onready var obj_container := $"../Main/Display/HitPoint/ObjectContainer"
onready var root_viewport := $"/root" as Root
onready var editor := $"../"
var _f := File.new()

## the time for the first note in the chart
var _first_note_time := -1.0

## the time for the last note in the chart
var _last_note_time := -1.0

const DEFAULT_VELOCITY := 1750.0

func loadChart(filePath) -> void:
	if not _f.file_exists(filePath):
		print("Invalid file!")
		_f.close()
		return

	if _f.open(filePath, File.READ):
		print("Unable to read temporary .fus file!")
		return

	if _f.get_line() != ChartLoader.FUS_VERSION:
		print("Outdated .fus file!")
		return
	
	root_viewport.title = _f.get_line()
	root_viewport.preview = _f.get_line()
	root_viewport.od = _f.get_line()
	root_viewport.folder_path = _f.get_line()
	root_viewport.difficulty_name = _f.get_line()
	root_viewport.charter = _f.get_line()
	root_viewport.bg_file_name = _f.get_line()
	root_viewport.bg_changed(GlobalTools.texture_from_image(root_viewport.folder_path.plus_file(root_viewport.bg_file_name)), Color("373737"))
	root_viewport.audio_file_name = _f.get_line()
	root_viewport.music.stream = AudioLoader.load_file(root_viewport.folder_path.plus_file((root_viewport.audio_file_name)))
	root_viewport.artist = _f.get_line()

	## Comment
	var cur_bpm := -1.0

	while _f.get_position() < _f.get_len():
		## Comment
		var line_data := _f.get_csv_line()

		## Comment
		var timing := float(line_data[0])

		## Comment
		var total_cur_sv := float(line_data[1]) * cur_bpm * 5.7

		## Comment
		var note_type := int(line_data[2])

		if note_type > ChartLoader.NoteType.BARLINE:
			_first_note_time = min(_first_note_time if _first_note_time + 1 else timing, timing)
			_last_note_time = max(_last_note_time if _last_note_time + 1 else timing, timing)

		match note_type:
			ChartLoader.NoteType.BARLINE:
				## Comment
				var hit_object := root_viewport.bar_line_object.instance() as BarLine

				hit_object.change_properties(timing, total_cur_sv)
				add_object(hit_object)

			ChartLoader.NoteType.DON, ChartLoader.NoteType.KAT:
				## Comment
				var hit_object := root_viewport.note_object.instance() as Note

				hit_object.change_properties(timing, total_cur_sv, int(line_data[2]) == int(ChartLoader.NoteType.KAT), bool(int(line_data[3])))
				add_object(hit_object)

				GlobalTools.send_signal(self, "new_marker_added", hit_object, "add_marker")

			ChartLoader.NoteType.ROLL:
				## Comment
				var hit_object := root_viewport.roll_object.instance() as Roll

				hit_object.change_properties(timing, total_cur_sv, float(line_data[3]), bool(int(line_data[4])), cur_bpm)
				add_object(hit_object)

			ChartLoader.NoteType.SPINNER:
				## Comment
				var hit_object := root_viewport.spinner_warn_object.instance() as SpinnerWarn

				hit_object.change_properties(timing, total_cur_sv, float(line_data[3]), cur_bpm)
				add_object(hit_object)
				GlobalTools.send_signal(self, "object_added", hit_object, "add_object")

			ChartLoader.NoteType.TIMING_POINT:
				cur_bpm = float(line_data[1])

				## Comment
				var hit_object := root_viewport.timing_point_object.instance() as TimingPoint

				hit_object.change_properties(timing, int(line_data[3]), cur_bpm)
				add_object(hit_object)

	get_tree().call_group("HitObjects", "apply_skin")
	print("Done!")
	_f.close()
	return

func add_object(hit_object: HitObject, loaded := true) -> void:
	obj_container.add_child(hit_object)
	for i in range(obj_container.get_child_count()):
		if hit_object.end_time > (obj_container.get_child(i) as HitObject).end_time:
			obj_container.move_child(hit_object, i)
			hit_object.connect("gui_input", editor, "moused_over_object", [hit_object])
			break

	if loaded:
		return

	hit_object.apply_skin()
