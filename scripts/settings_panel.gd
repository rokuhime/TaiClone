class_name SettingsPanel
extends CanvasItem

signal hit_error_toggled(new_visible)
signal late_early_changed(new_value)
signal offset_changed

var global_offset := 0.0

var _config_path := "user://config.ini"

onready var _root := $"/root" as Viewport
onready var _v := $"ScrollContainer/VBoxContainer"

onready var _dropdown := _v.get_node("Resolution/OptionButton") as OptionButton
onready var _keybind_changer := _v.get_node("Keybinds") as KeybindChanger


func _ready() -> void:
	# load config and all the variables
	var config_file := ConfigFile.new()
	if config_file.load(_config_path) != OK:
		print_debug("Config file not found.")
		save_settings()
		return
	for key in config_file.get_section_keys("Keybinds"):
		_keybind_changer.change_key(str(key), config_file.get_value("Keybinds", str(key)))

	var sections := config_file.get_sections()

	if "Display" in sections:
		change_res(Vector2(config_file.get_value("Display", "ResolutionX"), config_file.get_value("Display", "ResolutionY")))

	if "Gameplay" in sections:
		change_offset(str(config_file.get_value("Gameplay", "GlobalOffset")))

	var late_early_drop := _v.get_node("ExtraDisplays/LateEarly/OptionButton") as OptionButton
	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")

	var offset_text := _v.get_node("Audio/Offset/LineEdit") as LineEdit
	if global_offset != 0:
		offset_text.text = str(global_offset)

	_dropdown.add_item("16:9 | 1920x1080")
	_dropdown.set_item_metadata(0, Vector2(1920, 1080))
	_dropdown.add_item("16:9 | 1280x720")
	_dropdown.set_item_metadata(1, Vector2(1280, 720))
	_dropdown.add_item("16:9 | 1024x576")
	_dropdown.set_item_metadata(2, Vector2(1024, 576))
	_dropdown.add_separator()
	_dropdown.add_item("4:3 | 1280x1024")
	_dropdown.set_item_metadata(4, Vector2(1280, 1024))
	_dropdown.add_item("4:3 | 1024x768")
	_dropdown.set_item_metadata(5, Vector2(1024, 768))
	_dropdown.add_separator()
	_dropdown.add_item("5:4 | 1025x820")
	_dropdown.set_item_metadata(7, Vector2(1025, 820))


# this script stinks. gonna become obsolete when i get actual good settings going w
func change_offset(new_value: String) -> void:
	global_offset = float(new_value) / 1000
	print_debug("Offset set to %s." % global_offset)
	emit_signal("offset_changed")


func change_res(new_size: Vector2) -> void:
	OS.window_size = new_size
	_root.size = new_size


func hit_error(new_visible: bool) -> void:
	emit_signal("hit_error_toggled", new_visible)


func late_early(new_value: int) -> void:
	emit_signal("late_early_changed", new_value)


func res_changed(index: int) -> void:
	print_debug("Resolution changed to %s." % _dropdown.get_item_text(index))
	change_res(_dropdown.get_item_metadata(index))


func save_settings() -> void:
	var config_file := ConfigFile.new()

	print_debug("Saving keybinds config...")
	for key in _keybind_changer.KEYBINDS:
		config_file.set_value("Keybinds", str(key), _keybind_changer.KEYBINDS[key])

	print_debug("Saving resolution config...")
	var res := _root.size
	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)

	config_file.set_value("Gameplay", "GlobalOffset", global_offset)

	if config_file.save(_config_path) == OK:
		print_debug("Saved configuration file.")
	else:
		push_warning("Attempted to save configuration file.")


func toggle_fullscreen(new_visible: bool) -> void:
	print_debug("Fullscreen set to %s." % new_visible)
	OS.window_fullscreen = new_visible

	for i in range(_dropdown.get_item_count()):
		_dropdown.set_item_disabled(i, new_visible)


func toggle_settings() -> void:
	visible = !visible
