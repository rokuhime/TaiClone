extends Scene

onready var root_viewport := $"/root" as Root
onready var charts := $Charts


func _ready() -> void:
	Engine.target_fps = 120
	load_metadata(root_viewport.taiclone_songs_folder())
	if charts.get_child_count():
		(charts.get_child(0) as Button)._pressed()

	root_viewport.add_scene(root_viewport.bars.instance(), ["SongSelect"])

	## Comment
	var bars_object := root_viewport.get_node("Bars") as Bars

	bars_object.back_scene = root_viewport.main_menu
	bars_object.play_date.hide()


## Comment
func load_metadata(folder_path: String) -> void:
	## Comment
	var directory := Directory.new()

	if directory.open(folder_path):
		print_debug("Songs folder not found.")
		return

	assert(not directory.list_dir_begin(true), "Unable to read songs folder.")

	## Comment
	var f := File.new()

	while true:
		## Comment
		var file_name := directory.get_next()

		if not file_name:
			return

		if directory.current_is_dir():
			load_metadata(folder_path.plus_file(file_name))
			continue

		if f.open(folder_path.plus_file(file_name), File.READ):
			f.close()
			continue

		if f.get_line() != ChartLoader.FUS_VERSION:
			f.close()
			continue

		## Comment
		var song_button := root_viewport.song_button_object.instance() as SongButton

		song_button.chart.change_chart_properties(f.get_line(), f.get_line(), f.get_line(), f.get_line(), f.get_line(), f.get_line(), f.get_line(), f.get_line(), file_name, folder_path)
		f.close()
		charts.add_child(song_button)
