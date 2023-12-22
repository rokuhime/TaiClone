extends Control

enum GAMESTATE { MAIN_MENU, SONG_SELECT, GAMEPLAY }
var current_state := GAMESTATE.MAIN_MENU
var current_state_node: Node
var gamestate_scenes := [
	null,
	load("res://scenes/song_select/song_select.tscn"),
	load("res://scenes/gameplay/gameplay.tscn")
]

@onready var background := $Background
@onready var default_sfx_audio_queuer: AudioQueuer = $AudioQueuer

func _ready():
	get_window().size = Vector2i(1280, 720)
	get_window().move_to_center()
	
	get_tree().root.files_dropped.connect(file_dropped)
	change_state(GAMESTATE.SONG_SELECT)

func change_state(requested_scene):
	current_state = requested_scene
	if current_state_node:
		current_state_node.queue_free()
	
	var new_state_scene: Node
	if requested_scene >= GAMESTATE.size():
		print("Root: invalid index called to change_state(), voided current_state_node and bailed!")
		return
	new_state_scene = gamestate_scenes[requested_scene].instantiate()
	current_state_node = new_state_scene
	add_child(current_state_node)
	move_child(current_state_node, 1)  # 1 to ensure the background stays at the bottom
	return new_state_scene

func change_to_gameplay(requested_chart: Chart):
	change_state(GAMESTATE.GAMEPLAY).load_chart(requested_chart)

# used to bundle ui sounds into one AudioQueuer, saves memory
func play_ui_sound(target_stream: AudioStream, offset := Vector2.ZERO):
	default_sfx_audio_queuer.play_audio(target_stream, offset)

func set_background():
	background.texture

func file_dropped(files: PackedStringArray) -> void:
	var target_file = files[0]
	if files.size() > 1:
		print("multiple files dropped! only using first found file, ", target_file)
		
	var chart = ChartLoader.get_chart(ChartLoader.get_chart_path(target_file, true))
	if current_state != GAMESTATE.SONG_SELECT:
		change_state(GAMESTATE.SONG_SELECT)
	current_state_node.create_new_listing(chart)
	current_state_node.update_visual()
