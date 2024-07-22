extends Control

var music: AudioStreamPlayer
var chart_listing_scene := preload("res://entites/songselect/chart_listing.tscn")

@onready var listing_container := $ListingContainer
var listing_container_tween: Tween

@export var selected_listing_idx := 0

const LISTING_SEPARATION := 10.0
const TUCK_AMOUNT := 150.0
const LISTING_MOVEMENT_TIME := 0.5

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
	update_visual()

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
		if not listing_size:
			listing_size = listing.size
		
		listing.position.y = (listing_size.y  + LISTING_SEPARATION) * i
		var listing_position := -listing_size.x if i == selected_listing_idx else -listing_size.x + TUCK_AMOUNT
		
		if listing.movement_tween:
			listing.movement_tween.kill()
		listing.movement_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		listing.movement_tween.tween_property(listing, "position:x", listing_position, LISTING_MOVEMENT_TIME)
		
		i += 1
	
	# move listing container to center selected chart
	if listing_container_tween:
		listing_container_tween.kill()
	listing_container_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	var selected_listing_location = (listing_size.y + LISTING_SEPARATION) * -selected_listing_idx
	print(selected_listing_location)
	listing_container_tween.tween_property(listing_container, "position:y", selected_listing_location, LISTING_MOVEMENT_TIME)

func _unhandled_input(event):
	# refresh listings
	#if event is InputEventKey and event.keycode == KEY_F5:
		#refresh_listings_from_song_folders()
	
	if listing_container.get_child_count() > 0:
		if event.is_action_pressed("LeftKat"):
			change_selected_listing(-1)
		elif event.is_action_pressed("RightKat"):
			change_selected_listing(1)
		elif event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftDon") or event.is_action_pressed("ui_accept"):
			#transition_to_gameplay()
			Global.push_console("SongSelectV2", "transition_to_gameplay()")

func change_selected_listing(idx: int, exact := false):
	if exact:
		selected_listing_idx = idx % listing_container.get_child_count()
	else:
		selected_listing_idx = wrap((selected_listing_idx + idx) % listing_container.get_child_count(), 0, listing_container.get_child_count())
	update_visual()
