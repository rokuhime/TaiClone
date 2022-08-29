class_name Root
extends Viewport

## The first and primary object of the project.

## Signals [HitError] when the value of [member hit_error] has changed.
signal hit_error_toggled

## Signals [Gameplay] when the value of [member late_early_simple_display] has changed.
signal late_early_changed

## Comment
const CONFIG_PATH := "user://config.ini"

## Comment
const KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

## Comment
var global_offset := 0

## Comment
var hit_error := true

## Comment
var late_early_simple_display := 1

## Comment
var settings_save := false

## Comment
var skin: SkinManager

## Comment
var _background := $"Background" as TextureRect


func _init() -> void:
	skin = SkinManager.new()


## Comment
static func event(key: String) -> InputEvent:
	return InputMap.get_action_list(key)[0]


## Comment
static func inputs_empty(inputs: Array) -> bool:
	return int(inputs[0]) > inputs.size()


## Comment
static func item_resolution(item: Array) -> Vector2:
	return Vector2(int(item[1]), int(item[2]))


## Comment
static func send_signal(signal_target: Node, signal_name: String, obj: Object, method: String, binds := []) -> void:
	if obj.connect(signal_name, signal_target, method, binds):
		push_warning("Attempted to connect %s %s." % [obj.get_class(), signal_name])


## Comment
func add_scene(new_scene: Node, parent_node := "") -> void:
	add_child_below_node(get_node(parent_node) if has_node(parent_node) else _background, new_scene)


## Comment
func bg_changed(newtexture: Texture, newmodulate := Color.white) -> void:
	_background.modulate = newmodulate
	_background.texture = newtexture


## Comment
func change_key(event: InputEvent, button: String) -> void:
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)
	save_settings("change_key")


## Comment
func change_res(new_size: Vector2) -> void:
	OS.window_resizable = false
	OS.window_size = new_size
	OS.window_resizable = true
	save_settings("change_res")


## Comment
func hit_error_toggled(new_visible: bool) -> void:
	hit_error = new_visible
	emit_signal("hit_error_toggled")
	save_settings("hit_error_toggled")


## Comment
func late_early(new_value: int) -> void:
	late_early_simple_display = new_value
	emit_signal("late_early_changed")
	save_settings("late_early")


## Comment
func new_tween(old_tween: SceneTreeTween) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return get_tree().create_tween()


## Comment
func remove_scene(old_scene: String) -> bool:
	if has_node(old_scene):
		get_node(old_scene).queue_free()
		return true

	return false


## Comment
func save_settings(debug: String) -> void:
	if not settings_save:
		return

	## Comment
	var config_file := ConfigFile.new()

	for key in KEYS:
		## Comment
		var new_event := event(str(key))

		config_file.set_value("Keybinds", str(key), ("J%s" % (new_event as InputEventJoypadButton).button_index) if new_event is InputEventJoypadButton else ("K%s" % OS.get_scancode_string((new_event as InputEventKey).scancode)) if new_event is InputEventKey else "")

	config_file.set_value("Display", "LateEarly", late_early_simple_display)
	config_file.set_value("Display", "HitError", int(hit_error))

	## Comment
	var res := OS.window_size

	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)
	config_file.set_value("Display", "Fullscreen", int(OS.window_fullscreen))
	config_file.set_value("Audio", "GlobalOffset", global_offset)
	for i in range(AudioServer.bus_count):
		config_file.set_value("Audio", AudioServer.get_bus_name(i) + "Volume", db2linear(AudioServer.get_bus_volume_db(i)))

	if config_file.save(CONFIG_PATH):
		push_warning("Attempted to save configuration file.")

	else:
		print_debug(debug)


## Comment
func toggle_fullscreen(new_visible: bool) -> void:
	OS.window_fullscreen = new_visible
	save_settings("toggle_fullscreen")
