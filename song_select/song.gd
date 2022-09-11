class_name Song
extends Control

## Comment
var folder_path := ""

## Comment
var _artist := ""

## Comment
var _audio_filename := ""

## Comment
var _bg_file_name := ""

## Comment
var _charter := ""

## Comment
var _difficulty_name := ""

## Comment
var _title := ""

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
	chart_info.text = "%s - %s" % [_difficulty_name, _charter]
	song_info.text = "%s - %s" % [_artist, _title]
	rating_label.text = "?"
	status_label.text = "LOCAL"


## Comment
func apply_skin() -> void:
	ranking.texture = root_viewport.skin.ranking_s_small


## Comment
func change_properties(new_title: String, new_name: String, new_folder: String, new_charter: String, new_bg: String, new_audio: String, new_artist: String) -> void:
	folder_path = new_folder
	_artist = new_artist
	_audio_filename = new_audio
	_bg_file_name = new_bg
	_charter = new_charter
	_difficulty_name = new_name
	_title = new_title


## Comment
func change_song(new_folder: String, middle_index: int) -> void:
	rect_position.y = 475 + (get_index() - middle_index) * 145
	if get_index() == middle_index:
		margin_left = -720
		margin_right = 0
		self_modulate = Color.white

	elif folder_path == new_folder:
		margin_left = -664
		margin_right = 56
		self_modulate = Color("ffdf80")

	else:
		margin_left = -582
		margin_right = 138
		self_modulate = Color("80c0ff")
