class_name SettingsPanel
extends CanvasItem

signal hit_error_toggled(new_visible)
signal late_early_changed(new_value)
signal offset_changed(new_value)
signal volume_set(channel, amount)

const KEYS := ["LeftDon", "LeftKat", "RightDon", "RightKat"]

var _config_path := "user://config.ini"
var _currently_changing := ""

onready var dropdown := $Scroll/V/Resolution/Options as OptionButton
onready var fullscreen_toggle := $Scroll/V/Resolution/Fullscreen/Toggle as CheckBox
onready var hit_error_toggle := $Scroll/V/ExtraDisplays/HitError/Toggle as CheckBox
onready var late_early_drop := $Scroll/V/ExtraDisplays/LateEarly/Options as OptionButton
onready var taiclone := $"/root" as Root


func _ready() -> void:
	# load config and all the variables
	var config_file := ConfigFile.new()
	if config_file.load(_config_path):
		print_debug("Config file not found.")

	for key in KEYS:
		var event = config_file.get_value("Keybinds", str(key), _event(str(key)))
		if not event is InputEvent:
			continue
		_change_key(event, str(key), false)

	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")
	call_deferred("late_early", int(config_file.get_value("Display", "LateEarly", 1)), false)

	call_deferred("hit_error", bool(config_file.get_value("Display", "HitError", 1)), false)

	var resolution := Vector2(config_file.get_value("Display", "ResolutionX", 1920), config_file.get_value("Display", "ResolutionY", 1080))
	OS.window_size = resolution
	OS.window_resizable = true

	var resolutions := [["16:9 | 1920x1080", Vector2(1920, 1080)], ["16:9 | 1280x720", Vector2(1280, 720)], ["16:9 | 1024x576", Vector2(1024, 576)], [], ["4:3 | 1440x1080", Vector2(1440, 1080)], ["4:3 | 1024x768", Vector2(1024, 768)], [], ["5:4 | 1280x1024", Vector2(1280, 1024)], ["5:4 | 1025x820", Vector2(1025, 820)]]
	for i in resolutions.size():
		var item: Array = resolutions[i] # UNSAFE Variant
		if item.empty():
			dropdown.add_separator()
		else:
			dropdown.add_item(str(item[0]))
			var item_resolution: Vector2 = item[1] # UNSAFE Variant
			dropdown.set_item_metadata(int(i), item_resolution)
			if item_resolution == resolution:
				dropdown.select(int(i))

	toggle_fullscreen(bool(config_file.get_value("Display", "Fullscreen", 0)), false)

	call_deferred("change_offset", str(config_file.get_value("Audio", "GlobalOffset", 0)), false)
	var offset_text := $Scroll/V/Offset/LineEdit as LineEdit
	if taiclone.global_offset:
		offset_text.text = str(taiclone.global_offset)
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
func change_offset(new_value: String, settings_save := true) -> void:
	taiclone.global_offset = float(new_value) / 1000
	emit_signal("offset_changed", taiclone.global_offset)
	if settings_save:
		save_settings()


func change_res(new_size: Vector2) -> void:
	OS.window_resizable = false
	OS.window_size = new_size
	taiclone.size = new_size
	OS.window_resizable = true


func hit_error(new_visible: bool, settings_save := true) -> void:
	hit_error_toggle.pressed = new_visible
	emit_signal("hit_error_toggled", new_visible)
	if settings_save:
		save_settings()


func late_early(new_value: int, settings_save := true) -> void:
	late_early_drop.select(new_value)
	emit_signal("late_early_changed", new_value)
	if settings_save:
		save_settings()


func res_changed(index: int) -> void:
	var new_size: Vector2 = dropdown.get_item_metadata(index) # UNSAFE Variant
	change_res(new_size)
	save_settings()


func save_settings() -> void:
	var config_file := ConfigFile.new()

	for key in KEYS:
		config_file.set_value("Keybinds", str(key), _event(str(key)))

	config_file.set_value("Display", "LateEarly", late_early_drop.selected)
	config_file.set_value("Display", "HitError", int(hit_error_toggle.pressed))
	var res := OS.window_size
	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)
	config_file.set_value("Display", "Fullscreen", int(fullscreen_toggle.pressed))

	config_file.set_value("Audio", "GlobalOffset", taiclone.global_offset)
	for i in range(3):
		config_file.set_value("Audio", AudioServer.get_bus_name(i) + "Volume", db2linear(AudioServer.get_bus_volume_db(i)))

	if config_file.save(_config_path):
		push_warning("Attempted to save configuration file.")


func toggle_fullscreen(new_visible: bool, settings_save := true) -> void:
	OS.window_fullscreen = new_visible
	fullscreen_toggle.pressed = new_visible

	for i in range(dropdown.get_item_count()):
		dropdown.set_item_disabled(i, new_visible)
	if settings_save:
		save_settings()


func toggle_settings() -> void:
	visible = not visible


func _change_key(event: InputEvent, button: String, settings_save := true) -> void:
	# load_keybinds function
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)

	_currently_changing = ""
	_change_text(button)
	if settings_save:
		save_settings()


func _change_text(button: String, pressed := false) -> void:
	var event := _event(button)
	var button_object := get_node("Scroll/V/Keybinds/%s/Button" % button) as Button
	button_object.text = "..." if pressed else "Joystick Button %s" % (event as InputEventJoypadButton).button_index if event is InputEventJoypadButton else OS.get_scancode_string((event as InputEventKey).scancode) if event is InputEventKey else ""


func _event(key: String) -> InputEvent:
	var event = InputMap.get_action_list(key)[0]
	if not event is InputEvent:
		return null
	return event
