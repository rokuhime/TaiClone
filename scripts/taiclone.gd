class_name TaiClone
extends SceneTree

## Ran on startup, absolute root script of the project.


func _init() -> void:
	root.set_script(preload("res://scripts/root.gd"))

	## The root viewport that's used when requiring [Root]-specific functions.
	var taiclone := root as Root

	Root.send_signal(taiclone, "screen_resized", self, "save_settings", ["save_settings"])

	## The configuration file that's used to load settings.
	var config_file := ConfigFile.new()

	if config_file.load(Root.CONFIG_PATH):
		print_debug("Config file not found.")

	for key in Root.KEYS:
		## The key-bind for this [member key].
		var new_event := str(config_file.get_value("Keybinds", str(key), ""))

		## The key-bind value for this [member key].
		var event_value := new_event.substr(1)

		match new_event.left(1):
			"J":
				var event := InputEventJoypadButton.new()
				event.button_index = int(event_value)
				taiclone.change_key(event, str(key))

			"K":
				var event := InputEventKey.new()
				event.scancode = OS.find_scancode_from_string(event_value)
				taiclone.change_key(event, str(key))

			_:
				taiclone.change_key(Root.event(str(key)), str(key))

	taiclone.late_early_simple_display = int(config_file.get_value("Display", "LateEarly", 1))
	taiclone.hit_error = bool(config_file.get_value("Display", "HitError", 1))
	taiclone.change_res(Vector2(config_file.get_value("Display", "ResolutionX", 1920), config_file.get_value("Display", "ResolutionY", 1080)))
	taiclone.toggle_fullscreen(bool(config_file.get_value("Display", "Fullscreen", 0)))
	taiclone.global_offset = int(config_file.get_value("Audio", "GlobalOffset", 0))

	## The [VolumeControl] instance. It requires initialization before being added as a scene.
	var volume_control := preload("res://scenes/root/volume_control.tscn").instance() as VolumeControl

	volume_control.modulate.a = 0
	taiclone.add_scene(volume_control)
	for i in range(AudioServer.bus_count):
		volume_control.set_volume(i, float(config_file.get_value("Audio", AudioServer.get_bus_name(i) + "Volume", 1)))

	taiclone.add_scene(preload("res://scenes/gameplay/gameplay.tscn").instance())
	taiclone.settings_save = true

	# Load Scene == FOR DEBUG ONLY ==
	#(root.get_node("Gameplay") as CanvasItem).hide()
	#root.add_child(preload("res://scenes/main_ui.tscn").instance())


func _drop_files(files: PoolStringArray, _from_screen: int) -> void:
	if root.has_node("Gameplay"):
		(root.get_node("Gameplay") as Gameplay).load_func(files[0])
