class_name Root
# warning-ignore-all:unused_class_variable
extends Viewport

## Signals HitError when the value of [member hit_error] has changed.
signal hit_error_changed

## Signals [Gameplay] when the value of [member late_early_simple_display] has changed.
signal late_early_changed

## The [Array] of customizable key-binds used in [Gameplay].
const KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

## The path to the storage file that contains [member game_path].
const STORAGE_PATH := "user://storage.ini"

## The [AudioStreamPlayer] playing music.
var music := $Root/Music as AudioStreamPlayer

## Comment
var chart := Chart.new()

## Comment
var bar_line_object := load("res://scenes/hitobjects/bar_line.tscn") as PackedScene

## Comment
var bars := load("res://scenes/bars/bars.tscn") as PackedScene

## Comment
var gameplay := load("res://scenes/gameplay/gameplay.tscn") as PackedScene

## Comment
var hit_marker := load("res://scenes/gameplay/hit_marker.tscn") as PackedScene

## Comment
var main_menu := load("res://scenes/main_menu.tscn") as PackedScene

## Comment
var note_object := load("res://scenes/hitobjects/note.tscn") as PackedScene

## Comment
var results := load("res://scenes/results.tscn") as PackedScene

## Comment
var roll_object := load("res://scenes/hitobjects/roll.tscn") as PackedScene

## The [PackedScene] used to instance [SettingsPanel].
var settings_panel := load("res://scenes/settings_panel/settings_panel.tscn") as PackedScene

## Comment
var song_button_object := load("res://scenes/song_select/song_button.tscn") as PackedScene

## Comment
var song_select := load("res://scenes/song_select/song_select.tscn") as PackedScene

## Comment
var spinner_object := load("res://scenes/hitobjects/spinner.tscn") as PackedScene

## Comment
var spinner_warn_object := load("res://scenes/hitobjects/spinner_warn.tscn") as PackedScene

## Comment
var tick_object := load("res://scenes/hitobjects/tick.tscn") as PackedScene

## Comment
var timing_point_object := load("res://scenes/hitobjects/timing_point.tscn") as PackedScene

## Comment
var skin := SkinManager.new(SkinManager.DEFAULT_SKIN_PATH)

## Comment
var accuracy := ""

## Comment
var game_path := OS.get_user_data_dir()

## Comment
var skin_path := ""

## Comment
var songs_folder := ""

## Comment
var box_black := GlobalTools.get_alpha_texture("res://textures/box_neutral.png", Color.black)

## Comment
var box_flat := GlobalTools.get_image_texture("res://textures/box_flat.png")

## Comment
var box_neutral := GlobalTools.get_image_texture("res://textures/box_neutral.png")

## Comment
var box_white := GlobalTools.get_alpha_texture("res://textures/box_neutral.png", Color.white)

## Comment
var button_black := GlobalTools.get_alpha_texture("res://textures/button_neutral.png", Color.black)

## Comment
var button_white := GlobalTools.get_alpha_texture("res://textures/button_neutral.png", Color.white)

## Comment
var edge_black := GlobalTools.get_edge_texture(button_black.get_data(), box_black.get_data())

## Comment
var edge_white := GlobalTools.get_edge_texture(button_white.get_data(), box_white.get_data())

## Comment
var hit_error := true

## Comment
var settings_save := false

## Comment
var accurate_count := 0

## Comment
var combo := 0

## Comment
var early_count := 0

## Comment
var f_accurate_count := 0

## Comment
var f_inaccurate_count := 0

## Comment
var global_offset := 0

## Comment
var inaccurate_count := 0

## Comment
var late_count := 0

## Comment
var late_early_simple_display := 1

## Comment
var max_combo := 0

## Comment
var miss_count := 0

## Comment
var score := 0

## Comment
var _blackout := load("res://scenes/blackout.tscn") as PackedScene

## Comment
var _next_scene := PackedScene.new()

## Comment
var _background := $"Root/Background" as TextureRect


func _init() -> void:
	## Comment
	var storage_file := File.new()

	if not storage_file.open(STORAGE_PATH, File.READ):
		game_path = storage_file.get_as_text()
		storage_file.close()

	## The configuration file that's used to load settings.
	var c_file := ConfigFile.new()

	if c_file.load(_config_path()):
		print_debug("Config file not found.")

	for key in KEYS:
		## [member key] as a [String].
		var key_string := str(key)

		## The key-bind for this [member key].
		var keybind := str(c_file.get_value("Keybinds", key_string, ""))

		## The key-bind value for this [member key].
		var keybind_value := keybind.substr(1)

		match keybind.left(1):
			"J":
				## The new [InputEventJoypadButton] to associate with this [member key].
				var event := InputEventJoypadButton.new()

				event.button_index = int(keybind_value)
				change_key(event, key_string)

			"K":
				## The new [InputEventKey] to associate with this [member key].
				var event := InputEventKey.new()

				event.scancode = OS.find_scancode_from_string(keybind_value)
				change_key(event, key_string)

	late_early_simple_display = int(c_file.get_value("Display", "LateEarly", 1))
	hit_error = bool(c_file.get_value("Display", "HitError", 1))
	res_changed(Vector2(c_file.get_value("Display", "ResolutionX", 1920), c_file.get_value("Display", "ResolutionY", 1080)))
	toggle_fullscreen(bool(c_file.get_value("Display", "Fullscreen", 0)))
	change_skin(str(c_file.get_value("Display", "SkinPath", SkinManager.DEFAULT_SKIN_PATH)))
	global_offset = int(c_file.get_value("Audio", "GlobalOffset", 0))
	songs_folder = str(c_file.get_value("Debug", "SongsFolder", game_path))
	for i in range(AudioServer.bus_count):
		AudioServer.set_bus_volume_db(i, linear2db(float(c_file.get_value("Audio", AudioServer.get_bus_name(i) + "Volume", 1))))

	## Comment
	var _scene := add_scene(main_menu.instance())

	# linux cursor
	Input.set_custom_mouse_cursor(skin.cursor_texture, Input.CURSOR_BUSY, skin.cursor_texture.get_size() / 2)

	# windows cursor
	#Input.set_custom_mouse_cursor(skin.cursor_texture, Input.CURSOR_ARROW, skin.cursor_texture.get_size() / 2)

	settings_save = true


## Comment
func add_blackout(next_scene: PackedScene) -> void:
	_next_scene = next_scene

	## Comment
	var _scene := add_scene(_blackout.instance(), ["VolumeControl", "SettingsPanel", "Bars", get_child(1).name])


## Comment
func add_scene(new_scene: Node, nodes := ["Root"]) -> Node:
	## Comment
	var new_name := new_scene.name

	if not has_node(new_name) or new_name == get_child(1).name:
		for node_name in nodes:
			if has_node(str(node_name)):
				add_child_below_node(get_node(str(node_name)), new_scene)
				get_tree().call_group("Skinnables", "apply_skin")
				return new_scene

	new_scene.queue_free()
	return get_node(new_name)


## Comment
func bg_changed(new_texture: Texture, new_modulate := Color.white) -> void:
	_background.modulate = new_modulate
	_background.texture = new_texture


## Comment
func change_key(event: InputEvent, button: String) -> void:
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)
	save_settings()


## Comment
func change_skin(new_text := SkinManager.DEFAULT_SKIN_PATH) -> void:
	skin = SkinManager.new(new_text)
	skin_path = new_text
	save_settings()
	get_tree().call_group("Skinnables", "apply_skin")


## Comment
func hit_error_toggled(new_visible: bool) -> void:
	hit_error = new_visible
	emit_signal("hit_error_changed")
	save_settings()


## Comment
func late_early(new_value: int) -> void:
	late_early_simple_display = new_value
	emit_signal("late_early_changed")
	save_settings()


## Comment
func new_tween(old_tween: SceneTreeTween) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return get_tree().create_tween()


## Comment
func remove_blackout() -> void:
	remove_scene(get_child(1).name)

	## Comment
	var _scene := add_scene(_next_scene.instance())

	remove_scene("Blackout")


## Comment
func remove_scene(old_scene: String) -> void:
	if has_node(old_scene):
		(get_node(old_scene) as Scene).scene_removed()


## Comment
func res_changed(new_size: Vector2) -> void:
	OS.window_resizable = false
	OS.window_size = new_size
	OS.window_resizable = true
	save_settings()


## Comment
func save_settings() -> void:
	if not settings_save:
		return

	## Comment
	var config_file := ConfigFile.new()

	for key in KEYS:
		## Comment
		var event := GlobalTools.get_event(str(key))

		config_file.set_value("Keybinds", str(key), ("J%s" % (event as InputEventJoypadButton).button_index) if event is InputEventJoypadButton else ("K%s" % OS.get_scancode_string((event as InputEventKey).scancode)) if event is InputEventKey else "")

	config_file.set_value("Display", "LateEarly", late_early_simple_display)
	config_file.set_value("Display", "HitError", int(hit_error))

	## Comment
	var res := OS.window_size

	config_file.set_value("Display", "ResolutionX", res.x)
	config_file.set_value("Display", "ResolutionY", res.y)
	config_file.set_value("Display", "Fullscreen", int(OS.window_fullscreen))
	config_file.set_value("Display", "SkinPath", skin_path)
	config_file.set_value("Audio", "GlobalOffset", global_offset)
	for i in range(AudioServer.bus_count):
		config_file.set_value("Audio", AudioServer.get_bus_name(i) + "Volume", db2linear(AudioServer.get_bus_volume_db(i)))

	config_file.set_value("Debug", "SongsFolder", songs_folder)
	if config_file.save(_config_path()):
		push_warning("Attempted to save configuration file.")


## Comment
func taiclone_songs_folder() -> String:
	return game_path.plus_file("Songs")


## Comment
func toggle_fullscreen(new_visible: bool) -> void:
	OS.window_fullscreen = new_visible
	save_settings()


## Comment
func toggle_settings() -> void:
	if has_node("SettingsPanel"):
		remove_scene("SettingsPanel")

	else:
		## Comment
		var _scene := add_scene(settings_panel.instance(), ["Bars", get_child(1).name])


## Comment
func _config_path() -> String:
	return game_path.plus_file("config.ini")
