# root of the scene; used for scene switching and things that persist between scenes
class_name Root
extends Control

enum GAMESTATE { MAIN_MENU, SONG_SELECT, GAMEPLAY, RESULTS }
const NAV_BAR_ENABLED_STATES := [GAMESTATE.SONG_SELECT, GAMESTATE.RESULTS]
var current_state: GAMESTATE
var current_state_node: Node
var gamestate_scenes := [
	load("res://scenes/main_menu/main_menu.tscn"),
	load("res://scenes/song_select/song_select.tscn"),
	load("res://scenes/gameplay/gameplay.tscn"),
	load("res://scenes/results/results.tscn")
]

@onready var blackout_overlay := $BlackoutOverlay
var blackout_lock := false

# this shouldnt be on root like this, should probably just make a player class or something.
var current_skin := SkinManager.new()

# roku note 2024-08-01
# how will you load different difficulties for local multiplayer? i dont know!
# thats a problem for future roku
var current_chart: Chart

@onready var music: AudioStreamPlayer = $Music
var default_background = load("res://assets/textures/dev_art/background.png")
@onready var background := $Background
@onready var default_sfx_audio_queuer: AudioQueuer = $AudioQueuer
@onready var corner_info: Label = $NavigationBars/Bottom/CornerInfo/Label

var navigation_bar_tweens := []
var navigation_bars_enabled := false
@onready var navigation_bar_buttons := [
	$NavigationBars/Bottom/Buttons/Button1, $NavigationBars/Bottom/Buttons/Button2, $NavigationBars/Bottom/Buttons/Button3
]
@onready var navigation_bar_labels := [
	$NavigationBars/Top/HBoxContainer/LeftInfo/TopLabel, $NavigationBars/Top/HBoxContainer/LeftInfo/BottomLabel,
	$NavigationBars/Top/HBoxContainer/RightInfo/TopLabel, $NavigationBars/Top/HBoxContainer/RightInfo/BottomLabel
]

# -------- system -------

func _ready():
	get_window().size = Vector2i(1280, 720)
	get_window().move_to_center()
	
	get_tree().root.files_dropped.connect(file_dropped)
	
	await get_tree().process_frame
	toggle_navigation_bars(false, false)
	change_state(GAMESTATE.MAIN_MENU, true)

func _process(delta):
	corner_info.text = ProjectSettings.get("application/config/version") + "\nFPS: " + str(Engine.get_frames_per_second())

# -------- ui ----------

# used to bundle ui sounds into one AudioQueuer, saves memory
func play_ui_sound(target_stream: AudioStream, offset := Vector2.ZERO):
	default_sfx_audio_queuer.play_audio(target_stream, offset)

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
func set_navbar_buttons(button_info: Array) -> void:
	var idx := 0
	for button in navigation_bar_buttons:
		# if the idx exists...
		if button_info.size() - 1 >= idx:
			# if theres valid info...
			if button_info[idx] != null:
				button.visible = true
				button.text = button_info[idx]
				idx += 1
				continue
		# no info given, make invisible
		button.visible = false
		idx += 1

# sets test part of navbar
# 0, 1 = left, 2, 3 = right
func set_navbar_text(text_info: Array) -> void:
	var idx := 0
	for label in navigation_bar_labels:
		# if the idx exists...
		if text_info.size() - 1 >= idx:
			# if theres valid info...
			if text_info[idx] != null:
				label.visible = true
				label.text = text_info[idx]
				idx += 1
				continue
		# no info given, make invisible
		label.visible = false
		idx += 1

# wipes previous connections, and returns the pressed signals from navbar buttons
func get_navigation_bar_signals() -> Array:
	var button_signals := []
	for button in navigation_bar_buttons:
		# add connect callable to array
		button_signals.append(button.pressed)
	return button_signals

# -------- changing states ----------

func change_state(requested_scene, hard_transition := false) -> Node:
	if not hard_transition:
		await blackout_transition(true)
	
	current_state = requested_scene
	if current_state_node:
		current_state_node.queue_free()
	
	var new_state_scene: Node
	if requested_scene >= GAMESTATE.size():
		Global.push_console("Root", "invalid index called to change_state(), voided current_state_node and bailed!", 2)
		return
	new_state_scene = gamestate_scenes[requested_scene].instantiate()
	current_state_node = new_state_scene
	add_child(current_state_node)
	move_child(current_state_node, 1)  # 1 to ensure the background stays at the bottom
	
	if NAV_BAR_ENABLED_STATES.has(requested_scene):
		toggle_navigation_bars(true)
	else:
		toggle_navigation_bars(false, false)
	
	if not hard_transition:
		blackout_transition(false)
	return new_state_scene

# courotine; await this whenever transitioning from state to state
func blackout_transition(fade_in: bool) -> void:
	# if currently transitioning, do not interupt it
	if blackout_lock:
		return
	blackout_lock = true
	# ensure its visible
	blackout_overlay.visible = true
	
	var tween = create_tween()
	tween.tween_property(blackout_overlay, "modulate:a", 1.0 if fade_in else 0.0, 0.25).from(0.0 if fade_in else 1.0)
	await tween.finished
	
	# if its faded out, hide it to save processing power
	if not fade_in:
		blackout_overlay.visible = false
	
	# unlock and emit that its ready
	blackout_lock = false

func back_button_pressed() -> void:
	match current_state:
		GAMESTATE.SONG_SELECT:
			change_state(GAMESTATE.MAIN_MENU)
		_:
			change_state(GAMESTATE.SONG_SELECT)

func change_to_gameplay(auto_enabled: bool):
	toggle_navigation_bars(false)
	await change_state(GAMESTATE.GAMEPLAY)
	current_state_node.load_chart(current_chart)
	current_state_node.auto_enabled = auto_enabled

func change_to_results(score: ScoreInstance):
	if current_state != GAMESTATE.RESULTS:
		await change_state(GAMESTATE.RESULTS)
	current_state_node.set_score(score)

func refresh_song_select() -> void:
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	toggle_navigation_bars(true)
	current_state_node.refresh_listings_from_song_folders()

# -------- chart ----------

func update_current_chart(new_chart: Chart, for_gameplay := false) -> void:
	current_chart = new_chart
	set_background(new_chart.chart_info["background_path"])
	set_music(AudioLoader.load_file(new_chart.chart_info["audio_path"]), for_gameplay)

# updates music
func set_music(new_audio: AudioStream, for_gameplay: bool) -> void:
	if not new_audio:
		music.stop()
		music.stream = null
		return
	
	if for_gameplay:
		music.stop()
	
	# if there is a currently playing song...
	if music.stream:
		# check if new song is .ogg, if the current song is .ogg aswell check it
		if new_audio is AudioStreamOggVorbis and music.stream is AudioStreamOggVorbis:
			if new_audio.packet_sequence.packet_data == music.stream.packet_sequence.packet_data:
				return
		
		# if theyre both not .ogg
		elif not music.stream is AudioStreamOggVorbis and not new_audio is AudioStreamOggVorbis:
			# if the songs are the same, dont change
			if music.stream.data == new_audio.data:
				return
	
	# has to be different, set audio
	music.stream = new_audio
	
	# get preview timing, and play
	if not for_gameplay:
		var prev_point := 0.0
		prev_point = current_chart.chart_info["preview_point"] if current_chart.chart_info["preview_point"] else 0
		music.play(clamp(prev_point, 0, music.stream.get_length()))

func set_background(bg_location) -> void:
	if bg_location:
		var new_background = ImageLoader.load_image(bg_location)
		if new_background is Texture2D:
			background.texture = new_background
			return
	
	background.texture = default_background

func on_music_end() -> void:
	if current_state == GAMESTATE.SONG_SELECT:
		if current_chart:
			var prev_point = current_chart.chart_info["preview_point"] if current_chart.chart_info["preview_point"] else 0
			music.play(clamp(prev_point, 0, music.stream.get_length()))

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
