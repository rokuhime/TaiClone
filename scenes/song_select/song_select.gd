class_name SongSelect
extends Control

var chart_listing_scene := preload("res://entites/songselect/chart_listing.tscn")
@onready var mod_panel := $ModPanel as ModPanel

@onready var listing_container := $ListingContainer
var listing_container_tween: Tween
@export var selected_listing_idx := 0
var last_selected_listing_idx := -1

const LISTING_SEPARATION := 10.0
const TUCK_AMOUNT := 150.0
const LISTING_MOVEMENT_TIME := 0.5

@onready var no_charts_warning := $no_charts_warning

# -------- system -------

func _ready() -> void:
	refresh_from_chart_folders()
	await get_tree().process_frame # delay 1 frame to ensure everything is loaded for update_visual
	
	# set navbar info
	get_parent().set_navbar_buttons(["Mods", null, "Play"])
	var button_signals = get_parent().get_navigation_bar_signals()
	button_signals[0].connect(mod_panel.toggle_visual)
	button_signals[2].connect(transition_to_gameplay)
	
	# if listings exist, apply listing data
	if listing_container.get_child_count():
		# if theres a current chart loaded, try to jump to it
		if Global.get_root().current_chart:
			var current_chart_listing_idx := find_listing_by_chart(Global.get_root().current_chart)
			change_selected_listing(current_chart_listing_idx, true)
		
		# if theres no current chart, just load the first listing
		else:
			apply_listing_data(listing_container.get_child(0))
	update_visual(true)

func _unhandled_input(event) -> void:
	# refresh listings
	if event is InputEventKey and event.keycode == KEY_F5 and event.is_pressed():
		refresh_from_chart_folders(true)
		change_selected_listing(0, true)
	
	if event is InputEventKey and event.keycode == KEY_F1 and event.is_pressed():
		mod_panel.toggle_visual()
		
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		Global.get_root().back_button_pressed()
	
	# if were focused on a ui element, ignore any inputs
	if Global.focus_target:
		return
	
	if listing_container.get_child_count() > 0:
		# cycle through listings
		if event.is_action_pressed("LeftKat"):
			change_selected_listing(-1)
		elif event.is_action_pressed("RightKat"):
			change_selected_listing(1)
		
		# select
		elif event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftDon") or event.is_action_pressed("ui_accept"):
			transition_to_gameplay()

# -------- loading listings -------

# roku note 2024-07-22
# u gotta come up with better names to distinguish btwn refresh_from_chart_folders() and populate_from_chart_folder()
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
	sort_listings(ListingSort.SORT_TYPES.SONG_NAME)
	
	if listing_container.get_child_count():
		no_charts_warning.visible = false
		return
	no_charts_warning.visible = true

# removes existing selected_via_mouse signals from listings and updates them for their new idx
func update_listing_click_signal() -> void:
	for listing in listing_container.get_children():
		for sig in listing.get_signal_connection_list("selected_via_mouse"):
			listing.disconnect("selected_via_mouse", sig["callable"])
		listing.selected_via_mouse.connect(
			handle_listing_input.bind( listing_container.get_children().find(listing) )
		)

func sort_listings(sort_type: ListingSort.SORT_TYPES) -> void:
	Global.push_console("SongSelect", "sorting listings by %s!" % str(sort_type))
	
	# use godot's built in array sort
	var sorted_listings := listing_container.get_children()
	sorted_listings.sort_custom(ListingSort.get_sort_callable(sort_type))
	
	# adjust listings in listing_container to match sorted_listings order
	var i := 1
	var sorted := false
	
	while not sorted:
		# assume sorted until proven wrong
		sorted = true
		for listing in listing_container.get_children():
			if listing.get_index() != sorted_listings.find(listing):
				# had to change index of listing, change bool back to false
				sorted = false
				listing_container.move_child(listing, sorted_listings.find(listing))
		i += 1
	
	update_listing_click_signal()
	Global.push_console("SongSelect", "sorted after %s attempts!" % i)
	update_visual(true)

# creates listings from a folder containing chart files
func populate_from_chart_folder(folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(folder_path) and folder_path != Global.CONVERTED_CHART_FOLDER:
		Global.push_console("SongSelect", "attempted to populate from bad folder: %s" % folder_path, 2)
	Global.push_console("SongSelect", "populating from: %s" % folder_path)
	
	for file in DirAccess.get_files_at(folder_path):
		if ChartLoader.SUPPORTED_FILETYPES.has(file.get_extension()):
			var chart := ChartLoader.get_tc_metadata(ChartLoader.get_chart_path(folder_path + "/" + file)) as Chart
			if chart:
				# ensure were not making a duplicate listing before adding
				# since not found == -1, add 1 to treat it as a boolean
				if not bool(find_listing_by_chart(chart) + 1):
					Global.push_console("SongSelect", "added chart %s - %s [%s]" % [
						chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],
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

# goes through existing chart listings, returns the index if a chart's hash is the same as the given chart
func find_listing_by_chart(chart: Chart) -> int:
	for listing in listing_container.get_children():
		if listing is ChartListing:
			if chart.hash == listing.chart.hash:
				return listing.get_index()
	return -1

# -------- changing listing position/selection -------

func change_selected_listing(idx: int, exact := false) -> void:
	if not listing_container.get_child_count():
		return
	
	last_selected_listing_idx = selected_listing_idx
	
	if exact:
		selected_listing_idx = idx % listing_container.get_child_count()
	else:
		selected_listing_idx = wrap((selected_listing_idx + idx) % listing_container.get_child_count(), 0, listing_container.get_child_count())
	apply_listing_data(listing_container.get_child(selected_listing_idx))
	update_visual()

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
			# update navbar text if we're looking at the selected listing
			if i == selected_listing_idx and listing.chart.chart_info:
				get_parent().set_navbar_text([
					listing.chart.chart_info["song_title"] + " - " + listing.chart.chart_info["song_artist"],
					listing.chart.chart_info["chart_title"] + " - " + listing.chart.chart_info["chart_artist"]
					])
			
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

# applies bg/audio
func apply_listing_data(listing: ChartListing) -> void:
	Global.get_root().update_current_chart(listing.chart)

# -------- other -------

func handle_listing_input(index: int) -> void:
	if index == selected_listing_idx:
		transition_to_gameplay()
		return
	change_selected_listing(index, true)

func transition_to_gameplay() -> void:
	var selected_mods := mod_panel.get_selected_mods()
	var auto_enabled = selected_mods.has(0)
	Global.get_root().change_to_gameplay(auto_enabled)
