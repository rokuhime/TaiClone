class_name Root
extends Viewport

## Comment
const KEYS := ["LeftDon", "LeftKat", "RightDon", "RightKat"]

## Comment
var config_path := "user://config.ini"

## Comment
var hit_error := true

## Comment
var late_early_simple_display := 1

## Comment
var vols := AudioServer.bus_count

## Comment
var acc_timing: float

## Comment
var global_offset: float

## Comment
var inacc_timing: float

## Comment
var skin: SkinManager

## Comment
onready var background: TextureRect


func _init() -> void:
	acc_timing = 0.06
	global_offset = 0
	inacc_timing = 0.145
	skin = SkinManager.new()
	background = $"Background" as TextureRect
	if connect("size_changed", self, "size_changed"):
		push_warning("Attempted to connect Root size_changed.")


## Comment
static func event(key: String) -> InputEvent:
	return InputMap.get_action_list(key)[0]


## Comment
static func new_tween(old_tween: SceneTreeTween, node: Node) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return node.create_tween()


## Comment
func add_scene(new_scene: Node) -> void:
	add_child_below_node(background, new_scene)


## Comment
func bg_changed(newtexture: Texture, newmodulate := Color.white) -> void:
	background.modulate = newmodulate
	background.texture = newtexture


## Comment
func save_settings(debug: String) -> void:
	## Comment
	var config_file := ConfigFile.new()

	for key in KEYS:
		config_file.set_value("Keybinds", str(key), event(str(key)))

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
func size_changed() -> void:
	print_debug("size_changed")
