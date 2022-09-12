class_name TaiClone
extends SceneTree

## The [Root] [Script] that's used in initialization.
const ROOT := preload("res://scenes/root.gd")


func _init() -> void:
	root.set_script(ROOT)
	GlobalTools.send_signal(root, "screen_resized", self, "save_settings")
	(root as Root).change_root_properties()


func _input_event(event: InputEvent) -> void:
	## The [member ROOT] instance that's used when requiring [Root]-specific functions.
	var root_viewport := root as Root

	if event is InputEventKey:
		## [member event] as an [InputEventKey].
		var k_event := event as InputEventKey

		if k_event.pressed and k_event.control and k_event.scancode == KEY_O:
			root_viewport.toggle_settings()
