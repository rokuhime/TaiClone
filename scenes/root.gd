# root of the scene; used for scene switching and things that persist between scenes
class_name Root
extends Control

# gamestate
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

@onready var options_panel := $SettingsPanel

# transitions
@onready var blackout_overlay := $BlackoutOverlay
var blackout_lock := false

# persisting data
@onready var timing_clock: TimingClock = $TimingClock
var current_chart: Chart
@onready var music: AudioStreamPlayer = $Music
@onready var background := $Background
var default_background = preload("res://assets/textures/dev_art/background.png")
@onready var default_sfx_audio_queuer: AudioQueuer = $AudioQueuer

# info
@onready var navigation_bars: NavigationBars = $NavigationBars
@onready var version_info: Control = $VersionInfo

# -------- system --------

func _ready():
	get_window().move_to_center()
	get_tree().root.files_dropped.connect(file_dropped)
	await get_tree().process_frame
	
	# ensure navbars are ready
	navigation_bars.toggle_navigation_bars(false, false)
	navigation_bars.back_button.pressed.connect(back_button_pressed)
	
	# default to the main menu
	change_state(GAMESTATE.MAIN_MENU, true)

func _process(delta):
	# set corner info text and ensure the position is correct
	version_info.get_child(0).text = ProjectSettings.get("application/config/version") + "\nFPS: " + str(Engine.get_frames_per_second())
	
	if Global.display_version:
		if not version_info.visible:
			version_info.visible = true
		
		var buffer := 8
		var version_info_pos := Vector2(
			options_panel.position.x - version_info.size.x - buffer,
			navigation_bars.get_node("Bottom").position.y - version_info.size.y - buffer
		)
	
		if version_info.position != version_info_pos:
			version_info.position = version_info_pos
	
	elif not Global.display_version and version_info.visible:
		version_info.visible = false

# -------- changing states --------

# changes gamestate, and returns the new gamestate's node
func change_state(requested_scene, hard_transition := false) -> Node:
	if requested_scene >= GAMESTATE.size():
		Global.push_console("Root", "invalid index called to change_state()!", 2)
		return current_state_node
	
	# fade to black to mask transition
	if not hard_transition:
		await blackout_transition(true)
	
	current_state = requested_scene
	if current_state_node:
		current_state_node.queue_free()
	
	# instantiate new scene and add to tree
	var new_state_scene: Node
	new_state_scene = gamestate_scenes[requested_scene].instantiate()
	current_state_node = new_state_scene
	add_child(current_state_node)
	move_child(current_state_node, background.get_index() + 1)  # ensures the background stays at the bottom
	
	if NAV_BAR_ENABLED_STATES.has(requested_scene):
		navigation_bars.toggle_navigation_bars(true)
	else:
		navigation_bars.toggle_navigation_bars(false, false)
	
	if not hard_transition:
		blackout_transition(false)
	return new_state_scene

# fades to black, for gamestate transitions
# courotine; await this whenever transitioning from state to state
func blackout_transition(fade_in: bool) -> void:
	# if currently doing a blackout transition (lock is on), ignore
	if blackout_lock:
		return
	blackout_lock = true
	
	# tween alpha of blackout_overlay
	blackout_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(blackout_overlay, "modulate:a", 1.0 if fade_in else 0.0, 0.25).from(0.0 if fade_in else 1.0)
	await tween.finished
	
	# if its faded out, hide it
	if not fade_in:
		blackout_overlay.visible = false
	
	# unlock and end courotine 
	blackout_lock = false

# universal back button on navbar/backspace
func back_button_pressed() -> void:
	Global.push_console("Root", "back button pressed!")
	match current_state:
		GAMESTATE.SONG_SELECT:
			change_state(GAMESTATE.MAIN_MENU)
		_:
			change_state(GAMESTATE.SONG_SELECT)

# -------- spesific state changes --------

# from song select: loads current chart into gameplay with given mods
func change_to_gameplay(enabled_mods: Array):
	navigation_bars.toggle_navigation_bars(false)
	await change_state(GAMESTATE.GAMEPLAY)
	current_state_node.load_chart(current_chart)
	current_state_node.enabled_mods = enabled_mods

# from gameplay: loads results screen with given score data
func change_to_results(score: ScoreData):
	if current_state != GAMESTATE.RESULTS:
		await change_state(GAMESTATE.RESULTS)
	current_state_node.set_score(score)

func refresh_song_select() -> void:
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	navigation_bars.toggle_navigation_bars(true)
	current_state_node.refresh_listings_from_song_folders()

# -------- chart --------

# changes current_chart to given chart, and applies music/background
func update_current_chart(new_chart: Chart, for_gameplay := false) -> void:
	current_chart = new_chart
	set_background(new_chart.chart_info["background_path"])
	set_music(AudioLoader.load_file(new_chart.chart_info["audio_path"]), for_gameplay)

# updates music. if not for_gameplay, play from preview point
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

# updates background
func set_background(bg_location) -> void:
	if bg_location:
		var new_background = ImageLoader.load_image(bg_location)
		if new_background is Texture2D:
			background.texture = new_background
			return
	
	background.texture = default_background

# loops music upon ending if applicable
func on_music_end() -> void:
	if current_state == GAMESTATE.SONG_SELECT:
		if current_chart:
			var prev_point = current_chart.chart_info["preview_point"] if current_chart.chart_info["preview_point"] else 0
			music.play(clamp(prev_point, 0, music.stream.get_length()))
	# TODO: if on main menu get random chart

# -------- other --------

# for one-shot/ui sounds
func play_oneshot_sound(target_stream: AudioStream, offset := Vector2.ZERO):
	default_sfx_audio_queuer.play_audio(target_stream, offset)

func file_dropped(files: PackedStringArray) -> void:
	var target_file = files[0]
	if files.size() > 1:
		Global.push_console("Root", "Multiple files dropped! Only using first found file: %s" % target_file)
		
	var chart = ChartLoader.get_tc_metadata(ChartLoader.get_chart_path(target_file))
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	current_state_node.create_new_listing(chart)
	current_state_node.update_visual()
