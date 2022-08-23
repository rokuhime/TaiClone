class_name TaiClone
extends SceneTree

## Comment
var _root: Root


func _init() -> void:
	root.set_script(preload("res://scripts/root.gd"))
	_root = root as Root

	## Comment
	var volume_control := preload("res://scenes/volume_control.tscn").instance() as VolumeControl

	volume_control.modulate.a = 0
	_root.add_scene(volume_control)

	## Comment
	var gameplay := preload("res://scenes/gameplay/gameplay.tscn").instance() as Gameplay

	## Comment
	var settings_panel := gameplay.get_node("debug/SettingsPanel")

	_root.add_scene(gameplay)

	if volume_control.connect("volume_changed", settings_panel, "save_settings"):
		push_warning("Attempted to connect VolumeControl volume_changed.")

	if root.connect("size_changed", settings_panel, "save_settings"):
		push_warning("Attempted to connect Root size_changed.")

	# Load Scene == FOR DEBUG ONLY ==
	#(root.get_node("Gameplay") as CanvasItem).hide()
	#root.add_child(preload("res://scenes/main_ui.tscn").instance())


func _drop_files(files: PoolStringArray, _from_screen: int) -> void:
	if root.has_node("Gameplay"):
		(root.get_node("Gameplay") as Gameplay).load_func(files[0])
