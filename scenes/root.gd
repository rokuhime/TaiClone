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
var current_skin := SkinManager.new("/home/roku/Games/osu!/osu!/Skins/- Taikodachi")

# roku note 2024-08-01
# how will you load different difficulties for local multiplayer? i dont know!
# thats a problem for future roku
var current_chart: Chart

@onready var music: AudioStreamPlayer = $Music
var default_background = load("res://assets/textures/dev_art/background.png")
@onready var background := $Background
@onready var default_sfx_audio_queuer: AudioQueuer = $AudioQueuer
@onready var navigation_bars: NavigationBars = $NavigationBars

@onready var corner_info: Control = $CornerInfo
var corner_info_tween: Tween

# -------- system -------

func _ready():
	get_window().size = Vector2i(1280, 720)
	get_window().move_to_center()
	
	get_tree().root.files_dropped.connect(file_dropped)
	
	await get_tree().process_frame
	navigation_bars.toggle_navigation_bars(false, false)
	change_state(GAMESTATE.MAIN_MENU, true)
	navigation_bars.back_button.pressed.connect(back_button_pressed)

func _process(delta):
	corner_info.get_child(0).text = ProjectSettings.get("application/config/version") + "\nFPS: " + str(Engine.get_frames_per_second())
	var buffer := size.x - (corner_info.position.x + corner_info.size.x) # distance between corner_info and the very right side of the screen
	corner_info.position.y = navigation_bars.get_node("Bottom").position.y - corner_info.size.y - buffer

# -------- ui ----------

# used to bundle ui sounds into one AudioQueuer, saves memory
func play_ui_sound(target_stream: AudioStream, offset := Vector2.ZERO):
	default_sfx_audio_queuer.play_audio(target_stream, offset)

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
	move_child(current_state_node, 3)  # 1 to ensure the background stays at the bottom
	
	if NAV_BAR_ENABLED_STATES.has(requested_scene):
		navigation_bars.toggle_navigation_bars(true)
		
	else:
		navigation_bars.toggle_navigation_bars(false, false)
	
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
	Global.push_console("Root", "back button pressed!")
	match current_state:
		GAMESTATE.SONG_SELECT:
			change_state(GAMESTATE.MAIN_MENU)
		_:
			change_state(GAMESTATE.SONG_SELECT)

func change_to_gameplay(enabled_mods: Array):
	navigation_bars.toggle_navigation_bars(false)
	await change_state(GAMESTATE.GAMEPLAY)
	current_state_node.load_chart(current_chart)
	current_state_node.enabled_mods = enabled_mods

func change_to_results(score: ScoreData):
	if current_state != GAMESTATE.RESULTS:
		await change_state(GAMESTATE.RESULTS)
	current_state_node.set_score(score)

func refresh_song_select() -> void:
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	navigation_bars.toggle_navigation_bars(true)
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
	# TODO: if on main menu get random chart

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

