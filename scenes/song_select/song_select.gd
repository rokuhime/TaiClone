class_name SongSelect
extends Control

var music: AudioStreamPlayer
var chart_listing_scene := preload("res://entites/songselect/chart_listing.tscn")

@onready var listing_container := $ListingContainer
var listing_container_tween: Tween

@export var selected_listing_idx := 0
var last_selected_listing_idx := -1

const LISTING_SEPARATION := 10.0
const TUCK_AMOUNT := 150.0
const LISTING_MOVEMENT_TIME := 0.5

var auto_enabled := false

func _ready():
	music = get_tree().get_first_node_in_group("RootMusic")
	
	refresh_from_chart_folders()
	await get_tree().process_frame # delay 1 frame to ensure everything is loaded for update_visual
	
	if listing_container.get_child_count():
		apply_listing_data(listing_container.get_child(0))
	update_visual(true)

# --- loading listings ---

# roku note 2024-07-22
# u gotta come up with better names to distinguish btwn populate_from_folder() and populate_from_chart_folder()
# just generally having a name for the chart's folder and a folder that holds charts would be REALLY USEFUL and LESS CONFUSING

# hard updates do every folder, otherwise only scan converted chart folder (temporary)
func refresh_from_chart_folders(hard_update := false) -> void:
	Global.push_console("SongSelect", "refreshing converted charts!")
	populate_from_chart_folder(Global.CONVERTED_CHART_FOLDER)
	
	# cycle through chart folders to convert
	if hard_update:
		Global.push_console("SongSelect", "scanning through global chart folders...")
		for folder in Global.get_chart_folders():
			if !DirAccess.dir_exists_absolute(folder) or folder.is_empty():
				Global.push_console("SongSelect", "bad folder in global chart folder array: %s" % folder, 2)
				continue
			
			Global.push_console("SongSelect", "finding chart folders in: %s" % folder)
			for chart_folder in DirAccess.get_directories_at(folder):
				populate_from_chart_folder(folder.path_join(chart_folder))
				
	Global.push_console("SongSelect", "done refreshing charts!", 0)
	update_visual(true)

# creates listings from a folder containing chart files
func populate_from_chart_folder(folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(folder_path) and folder_path != Global.CONVERTED_CHART_FOLDER:
		Global.push_console("SongSelect", "attempted to populate from bad folder: %s" % folder_path, 2)
	Global.push_console("SongSelect", "populating from: %s" % folder_path)
	
	for file in DirAccess.get_files_at(folder_path):
		if ChartLoader.SUPPORTED_FILETYPES.has(file.get_extension()):
			var chart := ChartLoader.get_chart(ChartLoader.get_chart_path(folder_path + "/" + file)) as Chart
			if chart:
				# ensure were not making a duplicate listing before adding
				if not listing_exists(chart):
					Global.push_console("SongSelect", "added chart %s - %s [%s]" % [
						chart.chart_info["Song_Title"], chart.chart_info["Song_Artist"], chart.chart_info["Chart_Title"]],
						-2)
					create_listing(chart)
					continue
					
				Global.push_console("SongSelect", "ignoring duplicate chart: %s" % file, 1)
				continue
			Global.push_console("SongSelect", "corrupted/null chart: %s" % file, 2)
			continue

func create_listing(chart: Chart) -> ChartListing:
	var listing := chart_listing_scene.instantiate() as ChartListing
	listing.init(chart)
	listing.selected_via_mouse.connect(handle_listing_input.bind(listing_container.get_child_count()))
	listing_container.add_child(listing)
	
	return listing

# goes through existing chart listings, returns true if a chart's hash is the same as the given chart
func listing_exists(chart: Chart) -> bool:
	for listing in listing_container.get_children():
		if listing is ChartListing:
			if chart.hash == listing.chart.hash:
				return true
	return false

# --- changing listing position/selection ---

func _unhandled_input(event):
	# refresh listings
	if event is InputEventKey and event.keycode == KEY_F5:
		refresh_from_chart_folders(true)
	
	if listing_container.get_child_count() > 0:
		# cycle through listings
		if event.is_action_pressed("LeftKat"):
			change_selected_listing(-1)
		elif event.is_action_pressed("RightKat"):
			change_selected_listing(1)
		
		# select
		elif event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftDon") or event.is_action_pressed("ui_accept"):
			transition_to_gameplay()

# changes position of listings and listingcontainer
# hard updates ensure all listing positions are correct, otherwise only changes last selected and currently selected
func update_visual(hard_update := false) -> void:
	var i := 0
	var listing_size: Vector2
	
	for listing in listing_container.get_children():
		# if past the two changing listings and not updating every listing, bail out. nothing else to change
		if not hard_update and i > selected_listing_idx and i > last_selected_listing_idx:
			break
		
		# ensure we have a listing size
		if not listing_size:
			listing_size = listing.size
		
		if [last_selected_listing_idx, selected_listing_idx].has(i) or hard_update:
			# set y position of listing
			listing.position.y = ((listing_size.y  + LISTING_SEPARATION) * i) - (listing_size.y / 2)
			var listing_position_x := -listing_size.x if i == selected_listing_idx else -listing_size.x + TUCK_AMOUNT
			
			# ensure listing tween is good to go, then set x position via tween
			if listing.movement_tween:
				listing.movement_tween.kill()
			listing.movement_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			listing.movement_tween.tween_property(listing, "position:x", listing_position_x, LISTING_MOVEMENT_TIME)
		i += 1
	
	# move listing container to center selected chart
	if listing_container_tween:
		listing_container_tween.kill()
	listing_container_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# position of the selected listing
	var selected_listing_location = (listing_size.y + LISTING_SEPARATION) * -selected_listing_idx
	# center with middle of screen and middle of listing
	var listing_container_y_pos = get_parent().size.y / 2 + selected_listing_location
	
	listing_container_tween.tween_property(listing_container, "position:y", listing_container_y_pos, LISTING_MOVEMENT_TIME)

func change_selected_listing(idx: int, exact := false) -> void:
	last_selected_listing_idx = selected_listing_idx
	
	if exact:
		selected_listing_idx = idx % listing_container.get_child_count()
	else:
		selected_listing_idx = wrap((selected_listing_idx + idx) % listing_container.get_child_count(), 0, listing_container.get_child_count())
	apply_listing_data(listing_container.get_child(selected_listing_idx))
	update_visual()

# applies bg/audio
func apply_listing_data(listing: ChartListing) -> void:
	Global.set_background(listing.chart.background)
	
	# play preview
	if not listing.chart.audio:
		return
	
	# if there is a currently playing song...
	if music.stream:
		# check if new song is .ogg, if the current song is .ogg aswell check it
		if listing.chart.audio is AudioStreamOggVorbis and music.stream is AudioStreamOggVorbis:
			if listing.chart.audio.packet_sequence.packet_data == music.stream.packet_sequence.packet_data:
				return
		
		# if theyre both not .ogg
		elif not music.stream is AudioStreamOggVorbis and not listing.chart.audio is AudioStreamOggVorbis:
			# if the songs are the same, dont change
			if music.stream.data == listing.chart.audio.data:
				return
	
	# set song, get preview timing, and play
	music.stream = listing.chart.audio
	var prev_point: float = listing.chart.chart_info["PreviewPoint"] if listing.chart.chart_info["PreviewPoint"] else 0
	music.play(clamp(prev_point, 0, music.stream.get_length()))

func toggle_auto(new_auto: bool) -> void:
	auto_enabled = new_auto

func transition_to_gameplay() -> void:
	get_tree().get_first_node_in_group("Root").change_to_gameplay(listing_container.get_child(selected_listing_idx).chart, auto_enabled)

func handle_listing_input(index: int) -> void:
	if index == selected_listing_idx:
		transition_to_gameplay()
		return
	change_selected_listing(index, true)
