class_name TaiClone
extends SceneTree

## Ran on startup, absolute root script of the project.

## Comment
var _volume_control := preload("res://root/volume_control.tscn")

## Comment
var _root := preload("res://root/root.gd")

## The root viewport that's used when requiring [Root]-specific functions.
var _root_viewport: Root


func _init() -> void:
	root.set_script(_root)
	_root_viewport = root as Root
	GlobalTools.send_signal(_root_viewport, "screen_resized", self, "save_settings")

	## The configuration file that's used to load settings.
	var config_file := ConfigFile.new()

	if config_file.load(_root_viewport.game_path.plus_file(Root.CONFIG_PATH)):
		print_debug("Config file not found.")

	for key in Root.KEYS:
		## The key-bind for this [member key].
		var new_event := str(config_file.get_value("Keybinds", str(key), ""))

		## The key-bind value for this [member key].
		var event_value := new_event.substr(1)

		match new_event.left(1):
			"J":
				## Comment
				var event := InputEventJoypadButton.new()

				event.button_index = int(event_value)
				_root_viewport.change_key(event, str(key))

			"K":
				## Comment
				var event := InputEventKey.new()

				event.scancode = OS.find_scancode_from_string(event_value)
				_root_viewport.change_key(event, str(key))

			_:
				_root_viewport.change_key(GlobalTools.get_event(str(key)), str(key))

	_root_viewport.late_early_simple_display = int(config_file.get_value("Display", "LateEarly", 1))
	_root_viewport.hit_error = bool(config_file.get_value("Display", "HitError", 1))
	_root_viewport.res_changed(Vector2(config_file.get_value("Display", "ResolutionX", 1920), config_file.get_value("Display", "ResolutionY", 1080)))
	_root_viewport.toggle_fullscreen(bool(config_file.get_value("Display", "Fullscreen", 0)))
	_root_viewport.global_offset = int(config_file.get_value("Audio", "GlobalOffset", 0))

	## The [VolumeControl] instance. It requires initialization before being added as a scene.
	var volume_control := _volume_control.instance() as VolumeControl

	volume_control.modulate.a = 0
	_root_viewport.add_scene(volume_control)
	for i in range(AudioServer.bus_count):
		volume_control.set_volume(i, float(config_file.get_value("Audio", AudioServer.get_bus_name(i) + "Volume", 1)))

	_root_viewport.add_scene(_root_viewport.main_menu.instance())
	_root_viewport.settings_save = true


func _drop_files(files: PoolStringArray, _from_screen: int) -> void:
	ChartLoader.load_chart(files[0])
	_root_viewport.add_blackout(_root_viewport.gameplay)
