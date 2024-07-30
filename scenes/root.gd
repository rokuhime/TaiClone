extends Control

enum GAMESTATE { MAIN_MENU, SONG_SELECT, GAMEPLAY, RESULTS }
var default_background = load("res://assets/textures/dev_art/background.png")
var current_state := GAMESTATE.MAIN_MENU
var current_state_node: Node
var gamestate_scenes := [
	null,
	load("res://scenes/song_select/song_select.tscn"),
	load("res://scenes/gameplay/gameplay.tscn"),
	load("res://scenes/results/results.tscn")
]

@onready var background := $Background
@onready var default_sfx_audio_queuer: AudioQueuer = $AudioQueuer
@onready var corner_info: Label = $PanelContainer/CornerInfo

func _ready():
	get_window().size = Vector2i(1280, 720)
	get_window().move_to_center()
	
	get_tree().root.files_dropped.connect(file_dropped)
	change_state(GAMESTATE.SONG_SELECT)

func _process(delta):
	corner_info.text = ProjectSettings.get("application/config/version") + "\nFPS: " + str(Engine.get_frames_per_second())

func change_state(requested_scene):
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
	return new_state_scene

func change_to_gameplay(requested_chart: Chart, auto_enabled: bool):
	change_state(GAMESTATE.GAMEPLAY).load_chart(requested_chart)
	current_state_node.auto_enabled = auto_enabled

# used to bundle ui sounds into one AudioQueuer, saves memory
func play_ui_sound(target_stream: AudioStream, offset := Vector2.ZERO):
	default_sfx_audio_queuer.play_audio(target_stream, offset)

func set_background(new_background: Texture2D):
	if new_background:
		background.texture = new_background
		return
	background.texture = default_background

func file_dropped(files: PackedStringArray) -> void:
	var target_file = files[0]
	if files.size() > 1:
		Global.push_console("Root", "Multiple files dropped! Only using first found file: %s" % target_file)
		
	var chart = ChartLoader.get_tc_metadata(ChartLoader.get_chart_path(target_file))
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	current_state_node.create_new_listing(chart)
	current_state_node.update_visual()

func refresh_song_select() -> void:
	if current_state != GAMESTATE.SONG_SELECT:
		# will automatically be done as its loaded atm
		change_state(GAMESTATE.SONG_SELECT)
		return
	current_state_node.refresh_listings_from_song_folders()

func change_to_results(score: Dictionary):
	if current_state != GAMESTATE.RESULTS:
		# will automatically be done as its loaded atm
		change_state(GAMESTATE.RESULTS)
	current_state_node.set_score(score)
