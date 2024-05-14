extends Node

const CONVERTED_CHART_FOLDER := "user://ConvertedCharts"
const SUPPORTED_CHART_FILETYPES := ["tc", "osu", "tja"]
var chart_paths := []
const GAMEPLAY_KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

var root: Control
var music: AudioStreamPlayer
var volume_control: VolumeControl
var settings_panel: SettingsPanel

# consider; judgement timing array. you could have as many judgements as you want,
# going from most accurate to inaccurate
# allows finer judgements if wanted and such
const ACC_TIMING := 0.03
const INACC_TIMING := 0.07

var resolution_multiplier = 4.0
var offset := 0.0

func _init() -> void:
	DisplayServer.window_set_title("TaiClone " + ProjectSettings.get_setting("application/config/version"), 0)

func _ready() -> void:
	root = get_tree().get_first_node_in_group("Root")
	music = get_tree().get_first_node_in_group("RootMusic")
	volume_control = get_tree().get_first_node_in_group("VolumeControl")
	settings_panel = get_tree().get_first_node_in_group("SettingsPanel")
	
	load_settings()

func get_chart_folders() -> Array:
	return chart_paths + [CONVERTED_CHART_FOLDER]

func save_settings() -> void:
	var config_file := ConfigFile.new()
	
	config_file.set_value("General", "ChartPaths", Global.chart_paths)
	
	for bus_index in AudioServer.bus_count:
		config_file.set_value("Audio", AudioServer.get_bus_name(bus_index), db_to_linear(AudioServer.get_bus_volume_db(bus_index)))
	
	for key in Global.GAMEPLAY_KEYS:
		config_file.set_value("Keybinds", key, InputMap.action_get_events(key)[0])
	
	# save file
	var err = config_file.save("user://settings.cfg")
	if err != OK:
		print("SettingsPanel: Config failed to save with code ", err)
		return
	print("SettingsPanel: Config saved!")

func load_settings() -> void:
	var config_file := ConfigFile.new()
	var err = config_file.load("user://settings.cfg")
	if err != OK:
		print("SettingsPanel: Config failed to load at user://settings.cfg with code ", err)
		return
	
	chart_paths = config_file.get_value("General", "ChartPaths", null)
	
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
	print("SettingsPanel: Config loaded!")

static func get_accuracy(accurate_hits: int, inaccurate_hits: int, miss_count: int) -> float:
	var acc_hit_count : float = (accurate_hits + float(inaccurate_hits / 2.0))
	if acc_hit_count == 0:
		return 0.0
	return (acc_hit_count / float(accurate_hits + inaccurate_hits + miss_count)) * 100.0

# shorthand to make setting bgs easier
func set_background(new_background: Texture2D):
	root.set_background(new_background)

#static func send_signal(signal_target: Node, signal_name: String, obj: Object, method: String) -> void:
	#if obj.connect(signal_name, signal_target, method):
		#push_warning("Attempted to connect %s %s." % [obj.get_class(), signal_name])
