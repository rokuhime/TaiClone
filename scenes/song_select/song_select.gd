extends Control

var music: AudioStreamPlayer
var listings := []
var chart_listing_scene := preload("res://entites/songselect/chart_listing.tscn")

@onready var listing_container := $ListingContainer
var list_movement_tween: Tween

@export var selected_list_idx := 0

var unselected_tuck_amount := 100.0

# Called when the node enters the scene tree for the first time.
func _ready():
	music = get_tree().get_first_node_in_group("RootMusic")
	
	refresh_listings_from_song_folders()
	if not listings.is_empty():
		select_listing(listings[selected_list_idx])

func _unhandled_key_input(event):
	# refresh listings
	if event is InputEventKey and event.keycode == KEY_F5:
		refresh_listings_from_song_folders()
	
	if listings.size() > 0:
		if event.is_action_pressed("LeftKat"):
			selected_list_idx = listings.size() - 1 if selected_list_idx - 1 < 0 else selected_list_idx - 1
			select_listing(listings[selected_list_idx])
		elif event.is_action_pressed("RightKat"):
			selected_list_idx = (selected_list_idx + 1) % listings.size()
			select_listing(listings[selected_list_idx])
		elif event.is_action_pressed("LeftDon") or event.is_action_pressed("LeftDon"):
			transition_to_gameplay()

func refresh_listings_from_song_folders() -> void:
	print("SongSelect: refreshing song listings...")
	# roku note 2023-12-29
	# no matter what listings cant be fully cleared, listings.clear() doesnt work nor does below
	# it just leaves null values for some reason, which breaks menu navigation
	# see line 66 mayb
	listings = []
	for listing in listing_container.get_children():
		listing.queue_free()
	
	for chart_folder in Global.get_chart_folders():
		print("SongSelect: scanning chart folder ", chart_folder)
		if !DirAccess.dir_exists_absolute(chart_folder) or chart_folder.is_empty():
			print("SongSelect: cant access chart folder at ", chart_folder)
			continue
		
		# get chart files
		if chart_folder == Global.CONVERTED_CHART_FOLDER:
			add_charts_from_folder(chart_folder)
		
		else:
			for inner_chart_folder in DirAccess.get_directories_at(chart_folder):
				add_charts_from_folder(chart_folder + "/" + inner_chart_folder)
	
	update_visual()

func add_charts_from_folder(directory: String) -> void:
	print("SongSelect: adding charts from ", directory)
	var diraccess = DirAccess.open(directory)
	for file_name in diraccess.get_files():
		if Global.SUPPORTED_CHART_FILETYPES.has(file_name.get_extension()):
			var chart = ChartLoader.get_chart(ChartLoader.get_chart_path(directory + "/" + file_name), true)
			if chart == null:
				continue
			if not listing_already_exists(chart):
				create_new_listing(chart)

func create_new_listing(chart: Chart) -> void:
	var new_chart_listing = chart_listing_scene.instantiate()
	new_chart_listing.init(chart)
	listing_container.add_child(new_chart_listing)

func select_listing(listing: ChartListing) -> void:
	listings[selected_list_idx].selected = false
	selected_list_idx = listings.find(listing)
	update_visual()
	
	# TODO: check before setting? it would be annoying to get from here for not much performance increase
	# none the less would be a good idea
	Global.set_background(listings[selected_list_idx].chart.background)
	
	# play preview
	if listings[selected_list_idx].chart.audio != null:
		if music.stream != null:
			# if last selected song and new song are same, dont change preview
			if music.stream.data == listings[selected_list_idx].chart.audio.data:
				return
		
		# set song, get preview timing, and play
		music.stream = listings[selected_list_idx].chart.audio
		var prev_point: float = listings[selected_list_idx].chart.chart_info["PreviewPoint"] if listings[selected_list_idx].chart.chart_info["PreviewPoint"] else 0
		music.play(prev_point)

func update_visual() -> void:
	var listing_size: Vector2
	var list_idx := 0
	
	for listing in listing_container.get_children():
		if not listings.has(listing) and listing != null:
			listings.append(listing)
		
		# get default position
		if !listing_size:
			listing_size = listing.size
		#var default_position := Vector2(listing_size.x, listing_size.y / 2) * -1
		
		# stop any current tweens
		if listing.movement_tween:
			listing.movement_tween.kill()
		
		var new_pos := Vector2.ZERO
		new_pos.x = -listing.size.x if listings[selected_list_idx] == listing else -listing.size.x + unselected_tuck_amount
		new_pos.y = list_idx * listing.size.y
		
		listing.movement_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		listing.movement_tween.tween_property(listing, "position", new_pos, 0.2)
		
		list_idx += 1
	
	if list_movement_tween:
		list_movement_tween.kill()
	
	list_movement_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	list_movement_tween.tween_property(
		listing_container, 
		"position", 
		Vector2(get_viewport_rect().size.x, (get_viewport_rect().size.y / 2) - (selected_list_idx * listing_size.y)), 
		0.5 )

func transition_to_gameplay() -> void:
	var selected_chart = ChartLoader.get_chart(listings[selected_list_idx].chart.file_path)
	get_tree().get_first_node_in_group("Root").change_to_gameplay(selected_chart)

# TODO: check hash instead
func listing_already_exists(chart: Chart) -> bool:
	for listing in listing_container.get_children():
		if listing.chart.chart_info == chart.chart_info:
			return true
	return false
