extends Node

const CONVERTED_CHART_FOLDER := "user://ConvertedCharts"
const SUPPORTED_CHART_FILETYPES := ["tc", "osu"]
var chart_paths := []
const GAMEPLAY_KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]
var player_name := "Player"

var root: Root
var music: AudioStreamPlayer
var volume_control: VolumeControl
var settings_panel: SettingsPanel
var database_manager: DatabaseManager
var focus_target: Node

# consider; judgement timing array. you could have as many judgements as you want,
# going from most accurate to inaccurate
# allows finer judgements if wanted and such
const ACC_TIMING := 0.03
const INACC_TIMING := 0.07
const MISS_TIMING := 0.15

var resolution_multiplier = 4.0
var global_offset := 0.0
var limit_barlines := true

# lowest level of priority that will appear to console
var console_filter := -2

var current_skin := SkinManager.new()

# -------- system --------

func _init() -> void:
	DisplayServer.window_set_title("TaiClone " + ProjectSettings.get_setting("application/config/version"), 0)

func _ready() -> void:
	root = get_tree().get_first_node_in_group("Root")
	music = get_tree().get_first_node_in_group("RootMusic")
	volume_control = get_tree().get_first_node_in_group("VolumeControl")
	settings_panel = get_tree().get_first_node_in_group("SettingsPanel")
	database_manager = get_tree().get_first_node_in_group("DatabaseManager")
	
	load_settings()

# -------- game management --------

func get_chart_folders() -> Array:
	return chart_paths + [CONVERTED_CHART_FOLDER]

func save_settings() -> void:
	var config_file := ConfigFile.new()
	
	config_file.set_value("General", "OfflinePlayerName", player_name)
	
	config_file.set_value("General", "ChartPaths", chart_paths)
	config_file.set_value("General", "GlobalOffset", global_offset)
	config_file.set_value("General", "LimitBarlines", limit_barlines)
	
	if Global.current_skin.file_path:
		config_file.set_value("Skin", "SkinDirectory", Global.current_skin.file_path)
	
	for bus_index in AudioServer.bus_count:
		config_file.set_value("Audio", AudioServer.get_bus_name(bus_index), db_to_linear(AudioServer.get_bus_volume_db(bus_index)))
	
	for key in Global.GAMEPLAY_KEYS:
		config_file.set_value("Keybinds", key, InputMap.action_get_events(key)[0])
	
	# save file
	var err = config_file.save("user://settings.cfg")
	if err != OK:
		push_console("Global", "Config failed to save with code %s" % err, 2)
		return
	push_console("Global", "Config saved!", 0)

func load_settings() -> void:
	var config_file := ConfigFile.new()
	var err = config_file.load("user://settings.cfg")
	if err != OK:
		push_console("Global", "Config failed to load user://settings.cfg with code %s" % err, 2)
		return
	
	player_name = config_file.get_value("General", "OfflinePlayerName", "Player")
	limit_barlines = config_file.get_value("General", "LimitBarlines", true)
	
	if config_file.get_value("General", "ChartPaths", null):
		chart_paths = config_file.get_value("General", "ChartPaths", null)
	global_offset = config_file.get_value("General", "GlobalOffset", 0)
	
	if config_file.get_value("Skin", "SkinDirectory", false):
		current_skin = SkinManager.new(config_file.get_value("Skin", "SkinDirectory", null))
	
	var audio_settings = config_file.get_section_keys("Audio")
	for setting in audio_settings:
		var bus_volume = config_file.get_value("Audio", setting, 1)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(setting), linear_to_db(bus_volume))
	
	var keybinds = {}
	var keys = config_file.get_section_keys("Keybinds")
	for key in keys:
		var keybind = config_file.get_value("Keybinds", key, null)
		if keybind:
			keybinds[key] = keybind
	
	settings_panel.load_keybinds(keybinds)
	push_console("Global", "Config loaded!")

# -------- system --------

func change_global_offset(new_offset: float) -> void:
	global_offset = new_offset
	save_settings()

# simple function to color and timestamp console messages
# -2 = step, -1 = generic, 0 = success, 1 = warning, 2 = error
func push_console(origin: String, message: String, urgency := -1) -> void:
	# roku note 2024-07-22
	# consider notification priority being the same as console priority, 
	# makes it easier to push notifs & have the console echo the same
	
	if console_filter > urgency:
		return
	
	var formatted_message := "[" + Time.get_time_string_from_system() + "] [color=%s]" + origin + "[/color]: "
	
	# color and timestamp origin
	match origin:
		"Global":
			formatted_message = formatted_message % "green"
		"Root":
			formatted_message = formatted_message % "orange"
		"ChartLoader":
			formatted_message = formatted_message % "magenta"
		"SongSelect":
			formatted_message = formatted_message % "cyan"
		"DatabaseManager":
			formatted_message = formatted_message % "red"
		_:
			formatted_message = formatted_message % "gray"
	
	# color message by urgency
	match urgency:
		-2: # step
			formatted_message += "[color=gray]" + message + "[/color]"
		0: # success
			formatted_message += "[color=green]" + message + "[/color]"
		1: # warning
			formatted_message += "[color=yellow]" + message + "[/color]"
		2: # error
			formatted_message += "[color=red]" + message + "[/color]"
		_:
			formatted_message += message
	
	print_rich(formatted_message)

# mandatory for ui objects that take gameplay/menu input away from the user
func change_focus(new_focus_target: Node = null) -> void:
	focus_target = new_focus_target
	
	# if were disabling the focus, make sure to stop the current focus
	if not focus_target:
		get_viewport().gui_release_focus()

# -------- etc --------

# shortcut to provide easy access to root
func get_root() -> Root:
	return root

# shortcut to make smooth tweens consistent
static func create_smooth_tween(target: Node, property: NodePath, final_val, duration: float, from = null) -> Tween:
	var new_tween = target.create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if from:
		new_tween.tween_property(target, property, final_val, duration).from(from)
	else:
		new_tween.tween_property(target, property, final_val, duration)
	return new_tween

static func get_accuracy(accurate_hits: int, inaccurate_hits: int, miss_count: int) -> float:
	var acc_hit_count : float = (accurate_hits + float(inaccurate_hits / 2.0))
	if acc_hit_count == 0:
		return 0.0
	return (acc_hit_count / float(accurate_hits + inaccurate_hits + miss_count)) * 100.0

static func get_hash(file_path: String) -> PackedByteArray:
	# Start a SHA-256 context.
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	# Open the file to hash.
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	# this is a little stupid thing for .tc files to ignore version and source
	file.get_line()
	file.get_line()
	
	# Update the context after reading each chunk.
	while not file.eof_reached():
		ctx.update(file.get_buffer(1028))
	# Get the computed hash.
	var res = ctx.finish()
	file.close()
	return res
