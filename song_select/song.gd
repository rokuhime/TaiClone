extends Node

onready var root_viewport := $"/root" as Root
onready var ranking := $Organizer/Rank as TextureRect
onready var rating_label := $Organizer/Info/Banners/Rating/Label as Label
onready var status_label := $Organizer/Info/Banners/Status/Label as Label
onready var scroll_label := $Organizer/Info/Banners/Scroll/Label as Label
onready var manual_label := $Organizer/Info/Banners/Manual/Label as Label


func _ready() -> void:
	add_to_group("Skinnables")
	apply_skin()


## Comment
func apply_skin() -> void:
	ranking.texture = root_viewport.skin.ranking_s_small
	rating_label.text = "8.01"
	status_label.text = "RANKED"
	scroll_label.text = "SCROLL"
	manual_label.text = "MANUAL"
