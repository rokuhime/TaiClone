extends Control

enum GAMESTATE { MAIN_MENU, SONG_SELECT, GAMEPLAY, RESULTS }
const NAV_BAR_ENABLED_STATES := [GAMESTATE.SONG_SELECT, GAMESTATE.RESULTS]
var current_state := GAMESTATE.MAIN_MENU
var current_state_node: Node
var gamestate_scenes := [
	null,
	load("res://scenes/song_select/song_select.tscn"),
	load("res://scenes/gameplay/gameplay.tscn"),
	load("res://scenes/results/results.tscn")
]

var default_background = load("res://assets/textures/dev_art/background.png")
@onready var background := $Background
@onready var default_sfx_audio_queuer: AudioQueuer = $AudioQueuer
@onready var corner_info: Label = $NavigationBars/Bottom/CornerInfo/Label

var navigation_bar_tweens := []
var navigation_bars_enabled := false
@onready var navigation_bar_buttons := [
	$NavigationBars/Bottom/Buttons/Button1, $NavigationBars/Bottom/Buttons/Button2, $NavigationBars/Bottom/Buttons/Button3
]

func _ready():
	get_window().size = Vector2i(1280, 720)
	get_window().move_to_center()
	
	get_tree().root.files_dropped.connect(file_dropped)
	
	await get_tree().process_frame
	toggle_navigation_bars(false, false)
	change_state(GAMESTATE.SONG_SELECT)

func _process(delta):
	corner_info.text = ProjectSettings.get("application/config/version") + "\nFPS: " + str(Engine.get_frames_per_second())

# -------- ui ----------

# used to bundle ui sounds into one AudioQueuer, saves memory
func play_ui_sound(target_stream: AudioStream, offset := Vector2.ZERO):
	default_sfx_audio_queuer.play_audio(target_stream, offset)

func set_background(new_background: Texture2D):
	if new_background:
		background.texture = new_background
		return
	background.texture = default_background

func toggle_navigation_bars(enabled: bool, smooth_transition := true) -> void:
	navigation_bars_enabled = enabled
	
	# end any ongoing navbar tweens
	if not navigation_bar_tweens.is_empty():
		for tween in navigation_bar_tweens:
			tween.kill()
	
	var top_bar := $NavigationBars/Top as ColorRect
	var bottom_bar := $NavigationBars/Bottom as ColorRect
	var screen_size = size.y
	
	if enabled:
		var top_tween := Global.create_smooth_tween()
		var bottom_tween := Global.create_smooth_tween()
		# slide into view
		top_tween.tween_property(top_bar, "position:y", 0, 0.5 if smooth_transition else 0)
		bottom_tween.tween_property(bottom_bar, "position:y", screen_size - bottom_bar.size.y, 0.5 if smooth_transition else 0)
		
		navigation_bar_tweens = [top_tween, bottom_tween]
		return
	
	var top_tween := Global.create_smooth_tween()
	var bottom_tween := Global.create_smooth_tween()
	# slide out of view
	top_tween.tween_property(top_bar, "position:y", -top_bar.size.y, 0.5 if smooth_transition else 0)
	bottom_tween.tween_property(bottom_bar, "position:y", screen_size, 0.5 if smooth_transition else 0)
	
	# set vars to allow killing them early if needed
	navigation_bar_tweens = [top_tween, bottom_tween]

# sets navbar button text
func set_navigation_bar_info(nav_info: Array) -> void:
	var idx := 0
	for button in navigation_bar_buttons:
		# if the idx exists...
		if nav_info.size() - 1 >= idx:
			# if theres valid info...
			if nav_info[idx] != null:
				button.visible = true
				button.text = nav_info[idx]
				idx += 1
				continue
		# no info given, make invisible
		button.visible = false
		idx += 1

# wipes previous connections, and returns the pressed signals from navbar buttons
func get_navigation_bar_signals() -> Array:
	var button_signals := []
	for button in navigation_bar_buttons:
		# add connect callable to array
		button_signals.append(button.pressed)
	return button_signals

# -------- changing states ----------

func change_state(requested_scene) -> Node:
	current_state = requested_scene
	if current_state_node:
		current_state_node.queue_free()
	
	var new_state_scene: Node
	if requested_scene >= GAMESTATE.size():
		printerr("Root: invalid index called to change_state(), voided current_state_node and bailed!")
		return
	new_state_scene = gamestate_scenes[requested_scene].instantiate()
	current_state_node = new_state_scene
	add_child(current_state_node)
	move_child(current_state_node, 1)  # 1 to ensure the background stays at the bottom
	
	if NAV_BAR_ENABLED_STATES.has(requested_scene):
		toggle_navigation_bars(true)
	else:
		toggle_navigation_bars(false, false)
	
	return new_state_scene

func change_to_gameplay(requested_chart: Chart, auto_enabled: bool):
	toggle_navigation_bars(false)
	change_state(GAMESTATE.GAMEPLAY).load_chart(requested_chart)
	current_state_node.auto_enabled = auto_enabled

func change_to_results(score: Dictionary):
	if current_state != GAMESTATE.RESULTS:
		# will automatically be done as its loaded atm
		change_state(GAMESTATE.RESULTS)
	current_state_node.set_score(score)

func refresh_song_select() -> void:
	if current_state != GAMESTATE.SONG_SELECT:
		# will automatically be done as its loaded atm
		change_state(GAMESTATE.SONG_SELECT)
		return
	toggle_navigation_bars(true)
	current_state_node.refresh_listings_from_song_folders()

# -------- other ----------

func file_dropped(files: PackedStringArray) -> void:
	var target_file = files[0]
	if files.size() > 1:
		Global.push_console("Root", "Multiple files dropped! Only using first found file: %s" % target_file)
		
	var chart = ChartLoader.get_tc_metadata(ChartLoader.get_chart_path(target_file))
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	current_state_node.create_new_listing(chart)
	current_state_node.update_visual()
