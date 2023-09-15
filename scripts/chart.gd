class_name Chart

## The artist of this [Chart].
var artist := ""

## The path to the music of this [Chart].
var audio_file_name := ""

## The path to the background image of this [Chart].
var bg_file_name := ""

## The charter of this [Chart].
var charter := ""

## The difficulty name of this [Chart].
var difficulty_name := ""

## The name of the .fus file of this [Chart].
var file_name := ""

## The path to the folder containing the [member audio_file_name] and [member bg_file_name] of this [Chart].
var folder_path := ""

## The time to start playing the music on [SongSelect].
var preview_time := ""

## The title of this [Chart].
var song_title := ""

## The path to the folder containing the [member file_name] of this [Chart].
var taiclone_folder := ""


## Changes the properties of this [Chart].
func change_chart_properties(new_title: String, new_time: String, new_folder: String, new_difficulty: String, new_charter: String, new_bg: String, new_audio: String, new_artist: String, new_file := "", new_taiclone := "") -> void:
	artist = new_artist
	audio_file_name = new_audio
	bg_file_name = new_bg
	charter = new_charter
	difficulty_name = new_difficulty
	file_name = new_file
	folder_path = new_folder
	preview_time = new_time
	song_title = new_title
	taiclone_folder = new_taiclone


## Returns the chart info used for display.
func chart_info() -> String:
	return "%s - %s" % [difficulty_name, charter]


### Returns the full file path of the .fus file of this [Chart].
#func full_file_path() -> String:
#	return taiclone_folder.plus_file(file_name)

func tempdump() -> void:
	#var timing_point = [time:float, change_sv:bool, value:float, {kiai:bool omit_barline:bool}]
	pass

## Returns the song info used for display.
func song_info() -> String:
	return "%s - %s" % [artist, song_title]
