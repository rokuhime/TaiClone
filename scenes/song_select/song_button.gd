class_name SongButton
extends Button

## Comment
var chart := Chart.new()

onready var root_viewport := $"/root" as Root
onready var ranking := $Organizer/Rank as TextureRect
onready var song_info := $Organizer/Info/SongInfo as Label
onready var chart_info := $Organizer/Info/ChartInfo as Label
onready var rating_label := $Organizer/Info/Banners/Rating/Label as Label
onready var status_label := $Organizer/Info/Banners/Status/Label as Label


func _ready() -> void:
	add_to_group("Skinnables")
	add_to_group("Songs")
	apply_skin()
	chart_info.text = chart.chart_info()
	song_info.text = chart.song_info()
	rating_label.text = "?"
	status_label.text = "LOCAL"


func _pressed() -> void:
	## Comment
	var child_count := get_parent().get_child_count()

	## Comment
	var middle_index := int(child_count / 2.0)

	if get_index() == middle_index:
		root_viewport.add_blackout(root_viewport.gameplay)
		return

	for _i in range(abs(get_index() - middle_index)):
		if get_index() > middle_index:
			get_parent().move_child(get_parent().get_child(0), child_count - 1)

		else:
			get_parent().move_child(get_parent().get_child(child_count - 1), 0)

	get_tree().call_group("Songs", "change_song", chart.folder_path, middle_index)
	root_viewport.chart = chart


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	ranking.texture = root_viewport.skin.ranking_s_small


## Comment
func change_song(new_folder: String, middle_index: int) -> void:
	## Comment
	var size_y := rect_size.y

	margin_bottom = size_y / 2 + (get_index() - middle_index) * 145
	margin_top = margin_bottom - size_y
	if get_index() == middle_index:
		margin_left = -720
		margin_right = 0
		self_modulate = Color.white

	elif chart.folder_path == new_folder:
		margin_left = -664
		margin_right = 56
		self_modulate = Color("ffdf80")

	else:
		margin_left = -582
		margin_right = 138
		self_modulate = Color("80c0ff")
