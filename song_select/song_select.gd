extends Scene

onready var root_viewport := $"/root" as Root
onready var charts := $Charts


func _ready() -> void:
	load_metadata(root_viewport.game_path.plus_file(root_viewport.SONGS_FOLDER))
	Engine.target_fps = 120

	## Comment
	var middle_index := int(charts.get_child_count() / 2.0)

	get_tree().call_group("Songs", "change_song", (charts.get_child(middle_index) as Song).folder_path, middle_index)
	root_viewport.music.play()


## Comment
func load_metadata(folder_path: String) -> void:
	## Comment
	var directory := Directory.new()

	assert(not directory.open(folder_path), "Unable to open songs folder.")
	assert(not directory.list_dir_begin(true), "Unable to read songs folder.")

	## Comment
	var f := File.new()

	while true:
		## Comment
		var file_name := directory.get_next()

		if directory.current_is_dir():
			load_metadata(folder_path.plus_file(file_name))

		elif file_name:
			if f.open(folder_path.plus_file(file_name), File.READ):
				f.close()
				continue

			if f.get_line() != ChartLoader.FUS_VERSION:
				f.close()
				continue

			## Comment
			var song_button := root_viewport.song_button_object.instance() as Song

			song_button.change_properties(f.get_line(), f.get_line(), folder_path, f.get_line(), f.get_line(), f.get_line(), f.get_line())
			f.close()
			charts.add_child(song_button)

		else:
			return
