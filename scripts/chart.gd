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

## The path to the folder containing the [member file_name] of this [Chart].
var taiclone_folder_path := ""

## The title of this [Chart].
var title := ""


## Set the properties of this [Chart] using another [Chart].
## new_chart ([Chart]): The [Chart] to copy properties from.
func change_chart(new_chart: Chart) -> void:
	artist = new_chart.artist
	audio_file_name = new_chart.audio_file_name
	bg_file_name = new_chart.bg_file_name
	charter = new_chart.charter
	difficulty_name = new_chart.difficulty_name
	file_name = new_chart.file_name
	folder_path = new_chart.folder_path
	taiclone_folder_path = new_chart.taiclone_folder_path
	title = new_chart.title


## Returns the chart info used for display.
func chart_info() -> String:
	return "%s - %s" % [difficulty_name, charter]


## Returns the full file path of the .fus file of this [Chart].
func file_path() -> String:
	return folder_path.plus_file(file_name)


## Set the properties of this [Chart].
func set_chart_properties(new_title: String, new_difficulty: String, new_charter: String, new_bg: String, new_audio: String, new_artist: String, new_folder := "", new_file := "", new_taiclone := "") -> void:
	artist = new_artist
	audio_file_name = new_audio
	bg_file_name = new_bg
	charter = new_charter
	difficulty_name = new_difficulty
	file_name = new_file
	folder_path = new_folder
	taiclone_folder_path = new_taiclone
	title = new_title


## Returns the song info used for display.
func song_info() -> String:
	return "%s - %s" % [artist, title]
