class_name TaiClone
extends SceneTree


func _init() -> void:
	root.set_script(preload("res://scripts/root.gd"))
	root.get_child(0).queue_free()
	root.add_child(preload("res://game/scenes/gameplay.tscn").instance())