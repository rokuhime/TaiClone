class_name TaiClone
extends SceneTree

## The [Root] [Script] that's used in initialization.
const ROOT := preload("res://scenes/root.gd")

## Comment
var cur_clickable: Clickable

## Comment
var cur_hoverable: Hoverable


func _init() -> void:
	root.set_script(ROOT)
	GlobalTools.send_signal(root, "screen_resized", self, "save_settings")


func _input_event(event: InputEvent) -> void:
	set_input_as_handled()

	if not is_instance_valid(cur_clickable):
		cur_clickable = null

	if not is_instance_valid(cur_hoverable):
		cur_hoverable = null

	## The [member ROOT] instance that's used when requiring [Root]-specific functions.
	var root_viewport := root as Root

	if event is InputEventJoypadButton:
		pass

	if event is InputEventKey:
		## [member event] as an [InputEventKey].
		var k_event := event as InputEventKey

		if k_event.pressed and k_event.control and k_event.scancode == KEY_O:
			root_viewport.toggle_settings()

	if event is InputEventMouseButton:
		## [member event] as an [InputEventMouseButton].
		var mb_event := event as InputEventMouseButton

		match mb_event.button_index:
			BUTTON_LEFT:
				if mb_event.pressed and cur_hoverable is Clickable:
					cur_clickable = cur_hoverable as Clickable
					cur_clickable.click_start()

				else:
					if cur_clickable != null:
						cur_clickable.click_end()

					cur_clickable = null

	if event is InputEventMouseMotion:
		for node_object in get_nodes_in_group("Hoverables"):
			## Comment
			var hoverable: Hoverable = node_object

			if hoverable.get_global_rect().has_point(hoverable.get_global_mouse_position()):
				if hoverable != cur_clickable:
					if cur_hoverable != null:
						cur_hoverable.hover_end()

					hoverable.hover_start()
					cur_hoverable = hoverable

				break

			elif hoverable == cur_hoverable:
				hoverable.hover_end()
				cur_hoverable = null
				if hoverable == cur_clickable:
					cur_clickable = null
