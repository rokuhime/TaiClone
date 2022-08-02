class_name SettingsPanel
extends CanvasItem

signal hit_error_toggled(new_visible)
signal late_early_changed(new_value)
signal offset_changed
signal volume_set(channel, amount)

const KEYBINDS := {}

var global_offset := 0.0

var _config_path := "user://config.ini"
var _currently_changing := ""

onready var _dropdown := $"V/Scroll/V/Resolution/Options" as OptionButton
onready var _left_don_butt := $"V/Scroll/V/Keybinds/LeftDon/Button" as Button
onready var _left_kat_butt := $"V/Scroll/V/Keybinds/LeftKat/Button" as Button
onready var _right_don_butt := $"V/Scroll/V/Keybinds/RightDon/Button" as Button
onready var _right_kat_butt := $"V/Scroll/V/Keybinds/RightKat/Button" as Button


func _ready() -> void:
	# load config and all the variables
	var config_file := ConfigFile.new()
	if config_file.load(_config_path) != OK:
		print_debug("Config file not found.")
		save_settings()
		return

	for key in config_file.get_section_keys("Keybinds"):
		var event = config_file.get_value("Keybinds", str(key))
		if not event is InputEvent:
			continue
		change_key(str(key), event)
	for button in ["LeftDon", "LeftKat", "RightDon", "RightKat"]:
		var event = InputMap.get_action_list(str(button))[0]
		if not event is InputEvent:
			continue
		change_text(str(button), event)

	OS.window_size = Vector2(config_file.get_value("Display", "ResolutionX", 1920), config_file.get_value("Display", "ResolutionY", 1080))

	change_offset(str(config_file.get_value("Audio", "GlobalOffset", 0)))
	for i in range(3):
		emit_signal("volume_set", i, float(config_file.get_value("Audio", AudioServer.get_bus_name(i) + "Volume", 1)))

	var late_early_drop := $"V/Scroll/V/ExtraDisplays/LateEarly/Options" as OptionButton
	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")

	var offset_text := $"V/Scroll/V/Offset/LineEdit" as LineEdit
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


func _input(event: InputEvent) -> void:
	if _currently_changing != "":
		if event is InputEventJoypadButton or event is InputEventKey:
			change_key(_currently_changing, event)
			button_pressed(_currently_changing)
		else:
			push_warning("Unsupported InputEvent type.")


func button_pressed(type: String) -> void:
	if _currently_changing == "":
		_currently_changing = type
		change_text(_currently_changing, InputEvent.new(), true)
	else:
		var event = InputMap.get_action_list(_currently_changing)[0]
		change_text(_currently_changing, event) # UNSAFE ArrayItem
		_currently_changing = ""


func change_key(button: String, event: InputEvent) -> void:
	# load_keybinds function
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)

	_currently_changing = ""
	KEYBINDS[button] = event # UNSAFE DictionaryEntry
	change_text(button, event)


# this script stinks. gonna become obsolete when i get actual good settings going w
func change_offset(new_value: String) -> void:
	global_offset = float(new_value) / 1000
	print_debug("Offset set to %s." % global_offset)
	emit_signal("offset_changed")


func change_res(index: int) -> void:
	print_debug("Resolution changed to %s." % _dropdown.get_item_text(index))
	var new_size = _dropdown.get_item_metadata(index)
	OS.window_size = new_size # UNSAFE Variant


func change_text(button: String, event: InputEvent, pressed := false) -> void:
	var button_object: Button
	match button:
		"LeftDon":
			button_object = _left_don_butt
		"LeftKat":
			button_object = _left_kat_butt
		"RightDon":
			button_object = _right_don_butt
		"RightKat":
			button_object = _right_kat_butt
		_:
			push_warning("Unknown input.")
			return
	if event is InputEventJoypadButton:
		button_object.text = "Joystick Button %s" % (event as InputEventJoypadButton).button_index
	elif event is InputEventKey:
		button_object.text = OS.get_scancode_string((event as InputEventKey).scancode)
	else:
		button_object.text = "..."
	button_object.pressed = pressed


func hit_error(new_visible: bool) -> void:
	emit_signal("hit_error_toggled", new_visible)


func late_early(new_value: int) -> void:
	emit_signal("late_early_changed", new_value)


func save_settings() -> void:
	var config_file := ConfigFile.new()

	print_debug("Saving keybinds config...")
	for key in KEYBINDS:
		var event = KEYBINDS[key]
		if not event is InputEvent:
			continue
		config_file.set_value("Keybinds", str(key), event)

	print_debug("Saving display config...")
	var res := OS.window_size
	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)

	print_debug("Saving audio config...")
	config_file.set_value("Audio", "GlobalOffset", global_offset)
	for i in range(3):
		config_file.set_value("Audio", AudioServer.get_bus_name(i) + "Volume", db2linear(AudioServer.get_bus_volume_db(i)))

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
