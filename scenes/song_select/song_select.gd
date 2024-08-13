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
enum UPDATE_DEPTH { CONVERTED_CHARTS, NEW_CHARTS, UPDATE_CHARTS }

var dragging := false
const dragging_limit := 0.15
var drag_lock_timeout := 0.0
@onready var listing_scrollbar := $ListingScrollbar

@onready var scroll_echo_timer := $ScrollEchoTimer
const INITIAL_SROLL_ECHO_DELAY := 0.6
const SCROLL_ECHO_DELAY := 0.1

# -------- system -------

func _ready() -> void:
	Global.database_manager.restart_db()
	refresh_from_database()
	# this is laggy, dont leave on by default
	#refresh_from_chart_folders(true) # check for updates
	
	await get_tree().process_frame # delay 1 frame to ensure everything is loaded for update_visual
	
	# set navbar info
	get_parent().set_navbar_buttons(["Mods", null, "Play"])
	var button_signals = get_parent().get_navigation_bar_signals()
	button_signals[0].connect(mod_panel.toggle_visual)
	button_signals[2].connect(transition_to_gameplay)
	
	# if listings exist, apply listing data
	if listing_container.get_child_count():
		try_selecting_current_chart()
	
	# if the music hasnt started playing (after results screen), start it back up
	if not Global.get_root().music.get_playback_position():
		Global.get_root().on_music_end()
	
	scroll_echo_timer.timeout.connect(on_scroll_echo)

func _process(delta):
	if dragging:
		if not Input.get_mouse_button_mask() & MOUSE_BUTTON_MASK_RIGHT:
			dragging = false
	
	if drag_lock_timeout > 0:
		drag_lock_timeout -= delta
		return

func _unhandled_input(event) -> void:
	# refresh listings
	if event is InputEventKey and event.keycode == KEY_F5 and event.is_pressed():
		refresh_from_chart_folders()
		change_selected_listing(0, true)
	
	if event is InputEventKey and event.keycode == KEY_F1 and event.is_pressed():
		mod_panel.toggle_visual()
		
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		Global.get_root().back_button_pressed()
	
	# if were focused on a ui element, ignore any inputs
	if Global.focus_target:
		return
	
	if listing_container.get_child_count() > 0 and event.is_pressed():
		# cycle through listings
		if event.is_action_pressed("LeftKat"):
			change_selected_listing(-1)
			scroll_echo_timer.start(INITIAL_SROLL_ECHO_DELAY)
		
		elif event.is_action_pressed("RightKat"):
			change_selected_listing(1)
			scroll_echo_timer.start(INITIAL_SROLL_ECHO_DELAY)
		
		# select
		elif event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftDon") or event.is_action_pressed("ui_accept"):
			transition_to_gameplay()

func gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				dragging = true
	
	if not dragging or drag_lock_timeout > 0:
		return
	
	var mouse_y_position := remap(
		clampf(event.global_position.y / get_size().y, 0 + dragging_limit, 1 - dragging_limit), 
		0 + dragging_limit, 1 - dragging_limit,
		0, 1)
	var new_idx := roundi(mouse_y_position * (listing_container.get_child_count() - 1))
	
	if new_idx != selected_listing_idx:
		change_selected_listing(new_idx, true)
		drag_lock_timeout = 0.2

# -------- scanning for charts -------

# roku note 2024-07-22
# u gotta come up with better names to distinguish btwn refresh_from_chart_folders() and populate_from_chart_folder()
# just generally having a name for the chart's folder and a folder that holds charts would be REALLY USEFUL and LESS CONFUSING

func refresh_from_database() -> void:
	Global.push_console("SongSelect", "wiping existing listings...", -2)
	for listing in listing_container.get_children():
		listing.queue_free()
	await get_tree().process_frame
	
	Global.database_manager.clear_invalid_entries()
	Global.push_console("SongSelect", "refreshing databased charts!")
	
	var db_charts := Global.database_manager.get_all_charts()
	for db_entry in db_charts:
		var chart = Global.database_manager.db_entry_to_chart(db_entry)
		
		if chart:
			# ensure were not making a duplicate listing before adding
			# since not found == -1, add 1 to treat it as a boolean
			if not bool(find_listing_by_chart(chart) + 1):
				Global.push_console("SongSelect", "creating listing for %s - %s [%s]" % [
					chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],
					-2)
				create_listing(chart)
				continue
			# if a duplicate listing is found...
			Global.push_console("SongSelect", "ignoring duplicate chart: %s - %s [%s]" % [
				chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]], 1)
			continue
		Global.push_console("SongSelect", "corrupted/null chart: %s - %s [%s]" % [chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]], 2)
		continue
	
	Global.push_console("SongSelect", "done creating listings!", 0)
	await get_tree().process_frame
	sort_listings(ListingSort.SORT_TYPES.SONG_NAME)
	
	if listing_container.get_child_count():
		no_charts_warning.visible = false
		try_selecting_current_chart()
		return
	no_charts_warning.visible = true

## scan each chart folder for charts, adds/updates charts and removes invalid conversions
func refresh_from_chart_folders() -> void:
	Global.push_console("SongSelect", "cleaning converted charts folder...")
	# check convertedcharts for charts that dont exist anymore
	for converted_chart in DirAccess.get_files_at(Global.CONVERTED_CHART_FOLDER):
		var chart := ChartLoader.get_tc_metadata(Global.CONVERTED_CHART_FOLDER.path_join(converted_chart))
		
		# if origin listed, but doesn't exist...
		if chart.chart_info["origin_path"]:
			if not FileAccess.file_exists(chart.chart_info["origin_path"]):
				DirAccess.remove_absolute(Global.CONVERTED_CHART_FOLDER.path_join(converted_chart))
				Global.push_console("SongSelect", "deleted converted chart with invalid origin: %s - %s [%s]" % [
							chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],)
	
	# cycle through chart folders to convert
	Global.push_console("SongSelect", "scanning through global chart folder for changes...")
	for folder in Global.get_chart_folders():
		if !DirAccess.dir_exists_absolute(folder) or folder.is_empty():
			Global.push_console("SongSelect", "bad folder in global chart folder array: %s" % folder, 2)
			continue
		
		Global.push_console("SongSelect", "finding chart folders in: %s" % folder)
		for chart_folder in DirAccess.get_directories_at(folder):
			populate_from_chart_folder(folder.path_join(chart_folder))
	
	Global.push_console("SongSelect", "done scanning chart folders!", 0)
	
	# load the newly fixed listings
	await get_tree().process_frame
	Global.database_manager.clear_invalid_entries()
	refresh_from_database()

## creates db entries from a folder containing chart files
func populate_from_chart_folder(folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(folder_path) and folder_path != Global.CONVERTED_CHART_FOLDER:
		Global.push_console("SongSelect", "attempted to populate from bad folder: %s" % folder_path, 2)
	Global.push_console("SongSelect", "populating from: %s" % folder_path)
	
		
	for file in DirAccess.get_files_at(folder_path):
		if not ChartLoader.SUPPORTED_FILETYPES.has(file.get_extension()):
			continue
		
		var chart := ChartLoader.get_tc_metadata(ChartLoader.get_chart_path(folder_path + "/" + file)) as Chart
		if chart:
			# if it doesnt exist in the db, make a new entry
			if not Global.database_manager.exists_in_db(chart):
				Global.push_console("SongSelect", "Adding database entry for %s - %s [%s]" % [
					chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],)
				Global.database_manager.add_db_entry("charts", DatabaseManager.chart_to_db_entry(chart))

			
			# if the hash is different, assume it needs to be updated. otherwise assume its identical
			else:
				var db_entry := Global.database_manager.get_db_entry(chart)
				if db_entry["hash"] != chart.hash:
					Global.database_manager.update_chart(chart)
			continue
		
		Global.push_console("SongSelect", "corrupted/null chart: %s" % file, 2)
		continue

# -------- loading listings -------

## removes existing selected_via_mouse signals from listings and updates them for their new idx
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
	await get_tree().process_frame # delay 1 frame to ensure everything is loaded for update_visual
	update_visual(true)

func create_listing(chart: Chart) -> ChartListing:
	var listing := chart_listing_scene.instantiate() as ChartListing
	listing.init(chart)
	listing.selected_via_mouse.connect(handle_listing_input.bind(listing_container.get_child_count()))
	listing_container.add_child(listing)
	
	return listing

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
	listing_scrollbar.update_visual(selected_listing_idx, listing_container.get_child_count())

## changes position of listings and listingcontainer
## hard updates ensure all listing positions are correct, otherwise only changes last selected and currently selected
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
					listing.chart.chart_info["chart_title"] + " - " + listing.chart.chart_info["chart_artist"],
					"%s charts loaded" % listing_container.get_child_count()])
			
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
	if hard_update:
		Global.push_console("SongSelect", "Hard-updated visual!")

# applies bg/audio
func apply_listing_data(listing: ChartListing) -> void:
	Global.get_root().update_current_chart(listing.chart)

func try_selecting_current_chart() -> void:
	# if theres a current chart loaded, try to jump to it
	if Global.get_root().current_chart:
		var current_chart_listing_idx := find_listing_by_chart(Global.get_root().current_chart)
		change_selected_listing(current_chart_listing_idx, true)
	
	# if theres no current chart, just load the first listing
	else:
		apply_listing_data(listing_container.get_child(0))

# -------- other -------

# TODO: rename to something about idx this isnt clear at first glance
## goes through existing chart listings, returns the index if a chart's hash is the same as the given chart
func find_listing_by_chart(chart: Chart) -> int:
	for listing in listing_container.get_children():
		if listing is ChartListing:
			if chart.hash == listing.chart.hash:
				return listing.get_index()
	return -1

func find_listing_by_filepath(file_path: String) -> int:
	for listing in listing_container.get_children():
		if listing is ChartListing:
			var listing_path: String = listing.chart.chart_info["origin_path"] if listing.chart.chart_info["origin"] else listing.chart.file_path
			if file_path == listing_path:
				return listing.get_index()
	return -1

func handle_listing_input(index: int) -> void:
	if index == selected_listing_idx:
		transition_to_gameplay()
		return
	change_selected_listing(index, true)

func transition_to_gameplay() -> void:
	var selected_mods := mod_panel.get_selected_mods()
	var auto_enabled = selected_mods.has(0)
	Global.get_root().change_to_gameplay(auto_enabled)

# for echoing left/right kat inputs to change listing
func on_scroll_echo() -> void:
	if Input.is_action_pressed("LeftKat"):
		change_selected_listing(-1)
		scroll_echo_timer.start(SCROLL_ECHO_DELAY)
	elif Input.is_action_pressed("RightKat"):
		change_selected_listing(1)
		scroll_echo_timer.start(SCROLL_ECHO_DELAY)
