class_name Root
extends Viewport

# first and main object of the project

## Comment
signal hit_error_toggled

## Comment
signal late_early_changed

## Comment
const KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

## Comment
const RESOLUTIONS := ["16:9,1920,1080", "16:9,1280,720", "16:9,1024,576", "", "4:3,1440,1080", "4:3,1024,768", "", "5:4,1280,1024", "5:4,1025,820"]

## Comment
var config_path := "user://config.ini"

## Comment
var hit_error := true

## Comment
var late_early_simple_display := 1

## Comment
var settings_save := false

## Comment
var vols := AudioServer.bus_count

## Comment
var acc_timing: float

## Comment
var global_offset: int

## Comment
var inacc_timing: float

## Comment
var skin: SkinManager

## Comment
onready var background: TextureRect


func _init() -> void:
	global_offset = 0
	acc_timing = 0.03
	inacc_timing = 0.07
	skin = SkinManager.new()
	background = $"Background" as TextureRect


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
	add_child_below_node(get_node(parent_node) if has_node(parent_node) else background, new_scene)


## Comment
func bg_changed(newtexture: Texture, newmodulate := Color.white) -> void:
	background.modulate = newmodulate
	background.texture = newtexture


## Comment
func change_key(event: InputEvent, button: String) -> void:
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)
	save_settings("change_key")


## Comment
func change_res(index := -1) -> void:
	## Comment
	var new_size := OS.window_size if index == -1 else item_resolution(str(RESOLUTIONS.slice(index, index)[0]).split(",", false))

	OS.window_resizable = false
	OS.window_size = new_size
	size = new_size
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
	for i in range(vols):
		config_file.set_value("Audio", AudioServer.get_bus_name(i) + "Volume", db2linear(AudioServer.get_bus_volume_db(i)))

	if config_file.save(config_path):
		push_warning("Attempted to save configuration file.")

	else:
		print_debug(debug)


## Comment
func toggle_fullscreen(new_visible: bool) -> void:
	OS.window_fullscreen = new_visible
	save_settings("toggle_fullscreen")
