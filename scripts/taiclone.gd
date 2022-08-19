class_name TaiClone
extends SceneTree


func _init() -> void:
	root.set_script(preload("res://scripts/root.gd"))
	root.get_child(0).queue_free()
	root.add_child(preload("res://game/scenes/gameplay.tscn").instance())
	if root.connect("size_changed", root.get_node("Gameplay/debug/SettingsPanel"), "save_settings", [], CONNECT_DEFERRED):
		push_warning("Attempted to connect Root size_changed.")


func _drop_files(files: PoolStringArray, _from_screen: int) -> void:
	(root.get_node("Gameplay") as Gameplay).load_func(files[0])
