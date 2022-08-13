class_name SettingsPanel
extends CanvasItem

signal hit_error_toggled(new_visible)
signal late_early_changed(new_value)
signal offset_changed(new_value)
signal volume_set(channel, amount)

const KEYS := ["LeftDon", "LeftKat", "RightDon", "RightKat"]

var global_offset := 0.0

var _config_path := "user://config.ini"
var _currently_changing := ""

onready var dropdown := $V/Scroll/V/Resolution/Options as OptionButton
onready var fullscreen_toggle := $V/Scroll/V/Resolution/Fullscreen/Toggle as CheckBox
onready var hit_error_toggle := $V/Scroll/V/ExtraDisplays/HitError/Toggle as CheckBox
onready var late_early_drop := $V/Scroll/V/ExtraDisplays/LateEarly/Options as OptionButton


func _ready() -> void:
	# load config and all the variables
	var config_file := ConfigFile.new()
	if config_file.load(_config_path):
		print_debug("Config file not found.")

	for key in KEYS:
		var event = config_file.get_value("Keybinds", str(key), _event(str(key)))
		if not event is InputEvent:
			continue
		_change_key(event, str(key))

	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")
	call_deferred("late_early", int(config_file.get_value("Display", "LateEarly", 1)))

	call_deferred("hit_error", bool(config_file.get_value("Display", "HitError", 1)))

	var resolution := Vector2(config_file.get_value("Display", "ResolutionX", 1920), config_file.get_value("Display", "ResolutionY", 1080))
	OS.window_size = resolution
	OS.window_resizable = true

	var resolutions := [["16:9 | 1920x1080", Vector2(1920, 1080)], ["16:9 | 1280x720", Vector2(1280, 720)], ["16:9 | 1024x576", Vector2(1024, 576)], [], ["4:3 | 1280x1024", Vector2(1280, 1024)], ["4:3 | 1024x768", Vector2(1024, 768)], [], ["5:4 | 1025x820", Vector2(1025, 820)]]
	for i in resolutions.size():
		var item: Array = resolutions[i] # UNSAFE ArrayItem
		if item.empty():
			dropdown.add_separator()
		else:
			dropdown.add_item(str(item[0]))
			var item_resolution: Vector2 = item[1] # UNSAFE ArrayItem
			dropdown.set_item_metadata(int(i), item_resolution)
			if item_resolution == resolution:
				dropdown.select(int(i))

	toggle_fullscreen(bool(config_file.get_value("Display", "Fullscreen", 0)))

	call_deferred("change_offset", str(config_file.get_value("Audio", "GlobalOffset", 0)))
	var offset_text := $V/Scroll/V/Offset/LineEdit as LineEdit
	if global_offset:
		offset_text.text = str(global_offset)
	for i in range(3):
		emit_signal("volume_set", i, float(config_file.get_value("Audio", AudioServer.get_bus_name(i) + "Volume", 1)))

	save_settings()


func _input(event: InputEvent) -> void:
	if _currently_changing and (event is InputEventJoypadButton or event is InputEventKey):
		_change_key(event, _currently_changing)


func button_pressed(type: String) -> void:
	_change_text(type, not _currently_changing)
	_currently_changing = "" if _currently_changing else type


# this script stinks. gonna become obsolete when i get actual good settings going w
func change_offset(new_value: String) -> void:
	global_offset = float(new_value) / 1000
	print_debug("Offset set to %s." % global_offset)
	emit_signal("offset_changed", global_offset)


func change_res(index: int) -> void:
	print_debug("Resolution changed to %s." % dropdown.get_item_text(index))
	var new_size: Vector2 = dropdown.get_item_metadata(index) # UNSAFE Variant
	OS.window_size = new_size


func hit_error(new_visible: bool) -> void:
	hit_error_toggle.pressed = new_visible
	emit_signal("hit_error_toggled", new_visible)


func late_early(new_value: int) -> void:
	late_early_drop.select(new_value)
	emit_signal("late_early_changed", new_value)


func save_settings() -> void:
	var config_file := ConfigFile.new()

	print_debug("Saving keybinds config...")
	for key in KEYS:
		config_file.set_value("Keybinds", str(key), _event(str(key)))

	print_debug("Saving display config...")
	config_file.set_value("Display", "LateEarly", late_early_drop.selected)
	config_file.set_value("Display", "HitError", int(hit_error_toggle.pressed))
	var res := OS.window_size
	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)
	config_file.set_value("Display", "Fullscreen", int(fullscreen_toggle.pressed))

	print_debug("Saving audio config...")
	config_file.set_value("Audio", "GlobalOffset", global_offset)
	for i in range(3):
		config_file.set_value("Audio", AudioServer.get_bus_name(i) + "Volume", db2linear(AudioServer.get_bus_volume_db(i)))

	if config_file.save(_config_path):
		push_warning("Attempted to save configuration file.")
	else:
		print_debug("Saved configuration file.")


func toggle_fullscreen(new_visible: bool) -> void:
	print_debug("Fullscreen set to %s." % new_visible)
	OS.window_fullscreen = new_visible
	fullscreen_toggle.pressed = new_visible

	for i in range(dropdown.get_item_count()):
		dropdown.set_item_disabled(i, new_visible)


func toggle_settings() -> void:
	visible = not visible


func _change_key(event: InputEvent, button: String) -> void:
	# load_keybinds function
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)

	_currently_changing = ""
	_change_text(button)


func _change_text(button: String, pressed := false) -> void:
	var event := _event(button)
	var button_object := get_node("V/Scroll/V/Keybinds/%s/Button" % button) as Button
	button_object.text = "..." if pressed else "Joystick Button %s" % (event as InputEventJoypadButton).button_index if event is InputEventJoypadButton else OS.get_scancode_string((event as InputEventKey).scancode) if event is InputEventKey else ""


func _event(key: String) -> InputEvent:
	var event = InputMap.get_action_list(key)[0]
	if not event is InputEvent:
		return null
	return event
