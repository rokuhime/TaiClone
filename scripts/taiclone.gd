class_name TaiClone
extends SceneTree

var _gameplay: Gameplay


func _init() -> void:
	root.set_script(preload("res://scripts/root.gd"))
	_gameplay = preload("res://game/scenes/gameplay.tscn").instance() as Gameplay
	(_gameplay.get_node("VolumeControl") as CanvasItem).modulate = Color.transparent
	root.add_child(_gameplay)
	if root.connect("size_changed", _gameplay.get_node("debug/SettingsPanel"), "save_settings", [], CONNECT_DEFERRED):
		push_warning("Attempted to connect Root size_changed.")

	#(root.get_node("Gameplay") as CanvasItem).hide()
	#root.add_child(preload("res://game/scenes/main_menu.tscn").instance())


func _drop_files(files: PoolStringArray, _from_screen: int) -> void:
	_gameplay.load_func(files[0])
