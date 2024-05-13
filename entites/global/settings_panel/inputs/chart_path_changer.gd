# TODO: roku u GOTTA refactor this, its a web of strange starts and ends and needs cleaning up desperately
class_name ChartPathChanger
extends VBoxContainer

var path_panel_scene := load("res://entites/global/settings_panel/inputs/path_panel.tscn")
var selected_path_panel: PathPanel

@onready var path_container := $Panel/ScrollContainer/VBoxContainer

func refresh_paths() -> void:
	for path_panel in path_container.get_children():
		path_panel.queue_free()
	
	for chart_path in Global.chart_paths:
		add_path(chart_path)

func add_path(chart_path: String) -> void:
	if not DirAccess.dir_exists_absolute(chart_path) or chart_path.is_empty():
		print("ChartPathChanger: Bad chart path attempted to add at ", chart_path)
		return
	
	print("ChartPathChanger: Adding chart path ", chart_path)
	var new_path: PathPanel = path_panel_scene.instantiate()
	new_path.set_path(chart_path)
	path_container.add_child(new_path)
	select_path(new_path)
	
	if Global.chart_paths.find(chart_path) == -1:
		Global.chart_paths.append(chart_path)
	#get_tree().get_first_node_in_group("Root").refresh_song_select()

# called by path panels
func select_path(target_path_panel: PathPanel) -> void:
	if selected_path_panel:
		selected_path_panel.self_modulate.v = .5
	
	selected_path_panel = target_path_panel
	selected_path_panel.self_modulate.v = 1

func delete_selected_path() -> void:
	Global.chart_paths.erase(selected_path_panel.get_child(0).text)
	selected_path_panel.queue_free()
