extends Control

var music: AudioStreamPlayer
var chart_listing_scene := preload("res://entites/songselect/chart_listing.tscn")

@onready var listing_container := $ListingContainer
var list_movement_tween: Tween

@export var selected_listing_idx := 0

func populate_from_folder(folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(folder_path):
		Global.push_console("SongSelectV2", "attempted to populate from bad folder: %s" % folder_path, 2)
	Global.push_console("SongSelectV2", "populating from: %s" % folder_path)
	
	for file in DirAccess.get_files_at(folder_path):
		if ChartLoader.SUPPORTED_FILETYPES.has(file.get_extension()):
			var chart := ChartLoader.get_chart(ChartLoader.get_chart_path(folder_path + "/" + file)) as Chart
			
			# ensure were not making a duplicate listing before adding
			if not listing_exists(chart):
				Global.push_console("SongSelectV2", "added chart %s - %s [%s]" % [
					chart.chart_info["Song_Title"], chart.chart_info["Song_Artist"], chart.chart_info["Chart_Title"]
					])
				create_listing(chart)
				continue
				
			Global.push_console("SongSelectV2", "ignoring duplicate chart: %s" % file, 1)
			continue
			
		Global.push_console("SongSelectV2", "bad filetype: %s" % file, 2)
		continue
	
	Global.push_console("SongSelectV2", "finished!", 0)

func create_listing(chart: Chart) -> ChartListing:
	var listing := chart_listing_scene.instantiate() as ChartListing
	listing.init(chart)
	listing_container.add_child(listing)
	return listing

# goes through existing chart listings, returns true if a chart's hash is the same as the given chart
func listing_exists(chart: Chart) -> bool:
	for listing in listing_container.get_children():
		if listing is ChartListing:
			if chart.hash == listing.chart.hash:
				return true
	return false

func update_visual() -> void:
	var i := 0
	var listing_size: Vector2
	for listing in listing_container.get_children():
		if listing_size == null:
			listing_size = listing.size
		listing.position = Vector2(0, listing_size.y * i - selected_listing_idx)