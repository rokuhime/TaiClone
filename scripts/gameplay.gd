class_name Gameplay
extends Node

var global_offset := 0.0
var skin := SkinManager.new()
var version := "v0.2 - volume slider go brrr"

var _config_path := "user://config.ini"

onready var _root := $"/root" as Viewport

onready var _drum_visual := $"BarLeft/DrumVisual" as Node
onready var l_don_obj := _drum_visual.get_node("LeftDon") as CanvasItem
onready var l_kat_obj := _drum_visual.get_node("LeftKat") as CanvasItem
onready var r_don_obj := _drum_visual.get_node("RightDon") as CanvasItem
onready var r_kat_obj := _drum_visual.get_node("RightKat") as CanvasItem

onready var _judgements := $"BarRight/HitPointOffset/Judgements" as Node
onready var accurate_obj := _judgements.get_node("JudgeAccurate") as CanvasItem
onready var inaccurate_obj := _judgements.get_node("JudgeInaccurate") as CanvasItem
onready var miss_obj := _judgements.get_node("JudgeMiss") as CanvasItem

onready var keybind_changer := $"debug/SettingsPanel/ScrollContainer/VBoxContainer/Keybinds" as KeybindChanger

onready var hit_manager := $"HitManager" as HitManager
onready var music := $"Music" as AudioStreamPlayer


func _ready() -> void:
	# load config and all the variables
	var config_file := ConfigFile.new()
	if config_file.load(_config_path) != OK:
		print_debug("Config file not found.")
		save_config()
		return
	for key in config_file.get_section_keys("Keybinds"):
		keybind_changer.change_key(str(key), config_file.get_value("Keybinds", str(key)))

	var sections := config_file.get_sections()

	if "Display" in sections:
		_root.size = Vector2(config_file.get_value("Display", "ResolutionX"), config_file.get_value("Display", "ResolutionY"))

	if "Gameplay" in sections:
		global_offset = float(config_file.get_value("Gameplay", "GlobalOffset"))


func save_config() -> void:
	var config_file := ConfigFile.new()

	print_debug("Saving keybinds config...")
	for key in keybind_changer.KEYBINDS:
		config_file.set_value("Keybinds", str(key), keybind_changer.KEYBINDS[key])

	print_debug("Saving resolution config...")
	var res := _root.size
	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)

	config_file.set_value("Gameplay", "GlobalOffset", global_offset)

	if config_file.save(_config_path) == OK:
		print_debug("Saved configuration file.")
	else:
		push_warning("Attempted to save configuration file.")
