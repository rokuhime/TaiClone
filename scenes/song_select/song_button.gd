class_name SongButton
extends Node

## Comment
var chart := Chart.new()

onready var root_viewport := $"/root" as Root
onready var clickable := $Clickable as Clickable
onready var ranking := $Clickable/Organizer/Rank as TextureRect
onready var song_info := $Clickable/Organizer/Info/SongInfo as Label
onready var chart_info := $Clickable/Organizer/Info/ChartInfo as Label
onready var rating_label := $Clickable/Organizer/Info/Banners/Rating/Label as Label
onready var status_label := $Clickable/Organizer/Info/Banners/Status/Label as Label


func _ready() -> void:
	chart_info.text = chart.chart_info()
	song_info.text = chart.song_info()
	rating_label.text = "?"
	status_label.text = "LOCAL"


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	ranking.texture = root_viewport.skin.ranking_s_small


## Comment
func change_song(new_folder: String) -> void:
	## Comment
	var size_x := clickable.rect_size.x

	if root_viewport.chart == chart:
		clickable.margin_left = 0
		clickable.self_modulate = Color.white
		clickable.background.self_modulate = Color.white

	elif chart.folder_path == new_folder:
		clickable.margin_left = 56
		clickable.self_modulate = Color("ffdf80")
		clickable.background.self_modulate = Color("ffdf80")

	else:
		clickable.margin_left = 138
		clickable.self_modulate = Color("80c0ff")
		clickable.background.self_modulate = Color("80c0ff")

	clickable.margin_right = clickable.margin_left + size_x


func clickable_clicked() -> void:
	if root_viewport.chart == chart:
		root_viewport.add_blackout(root_viewport.gameplay)
		return

	get_tree().call_group("Songs", "change_song", chart.folder_path)
	root_viewport.chart = chart
