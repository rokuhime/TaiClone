class_name TaiClone
extends SceneTree


func _init() -> void:
	root.set_script(preload("res://scripts/root.gd"))

	## Comment
	var taiclone := root as Root

	if connect("screen_resized", taiclone, "res_changed", [OS.window_size]):
		push_warning("Attempted to connect TaiClone screen_resized.")

	## Comment
	var config_file := ConfigFile.new()

	if config_file.load(taiclone.config_path):
		print_debug("Config file not found.")

	for key in taiclone.KEYS:
		## Comment
		var event: InputEvent = config_file.get_value("Keybinds", str(key), Root.event(str(key))) # UNSAFE Variant

		taiclone.change_key(event, str(key))

	taiclone.late_early_simple_display = int(config_file.get_value("Display", "LateEarly", 1))
	taiclone.hit_error = bool(config_file.get_value("Display", "HitError", 1))
	taiclone.change_res(Vector2(config_file.get_value("Display", "ResolutionX", 1920), config_file.get_value("Display", "ResolutionY", 1080)))
	taiclone.toggle_fullscreen(bool(config_file.get_value("Display", "Fullscreen", 0)))
	taiclone.global_offset = int(config_file.get_value("Audio", "GlobalOffset", 0))

	## Comment
	var volume_control := preload("res://scenes/volume_control.tscn").instance() as VolumeControl

	volume_control.modulate.a = 0
	taiclone.add_scene(volume_control)
	for i in range(taiclone.vols):
		volume_control.set_volume(i, float(config_file.get_value("Audio", AudioServer.get_bus_name(i) + "Volume", 1)))

	## Comment
	var gameplay := preload("res://scenes/gameplay/gameplay.tscn").instance() as Gameplay

	taiclone.add_scene(gameplay)

	# Load Scene == FOR DEBUG ONLY ==
	#(root.get_node("Gameplay") as CanvasItem).hide()
	#root.add_child(preload("res://scenes/main_ui.tscn").instance())


func _drop_files(files: PoolStringArray, _from_screen: int) -> void:
	if root.has_node("Gameplay"):
		(root.get_node("Gameplay") as Gameplay).load_func(files[0])
