class_name TaiClone
extends SceneTree

## The [Root] [Script] that's used in initialization.
const ROOT := preload("res://scenes/root.gd")

## Comment
const VOLUME_CONTROL := preload("res://scenes/volume_control.tscn")

## Comment
var cur_clickable: Clickable

## Comment
var cur_scrollable: Control

## Comment
var cur_hoverable: Hoverable

## Comment
var volume_changing := 0


func _init() -> void:
	root.set_script(ROOT)
	GlobalTools.send_signal(root, "screen_resized", self, "save_settings")


func _input_event(event: InputEvent) -> void:
	set_input_as_handled()

	## The [member ROOT] instance that's used when requiring [Root]-specific functions.
	var root_viewport := root as Root

	if not event is InputEventWithModifiers:
		if root_viewport.has_node("Gameplay"):
			(root_viewport.get_node("Gameplay") as Gameplay).handle_input(event)

		return

	## [member event] as an [InputEventWithModifiers].
	var w_event := event as InputEventWithModifiers

	## Comment
	var vol_difference := 0.01 if w_event.control else 0.05

	if event is InputEventKey:
		## [member event] as an [InputEventKey].
		var k_event := event as InputEventKey

		if k_event.pressed:
			## Comment
			var other_input := true

			match k_event.scancode:
				KEY_O:
					if w_event.control:
						root_viewport.toggle_settings()
						other_input = false

				KEY_LEFT:
					if w_event.alt:
						volume_changing = (volume_changing + 2) % AudioServer.bus_count
						_volume_control(root_viewport).change_channel(volume_changing, false)
						other_input = false

				KEY_UP:
					if w_event.alt:
						_volume_control(root_viewport).change_volume(volume_changing, vol_difference)
						other_input = false

				KEY_RIGHT:
					if w_event.alt:
						volume_changing = (volume_changing + 1) % AudioServer.bus_count
						_volume_control(root_viewport).change_channel(volume_changing, false)
						other_input = false

				KEY_DOWN:
					if w_event.alt:
						_volume_control(root_viewport).change_volume(volume_changing, -vol_difference)
						other_input = false

			if other_input and root_viewport.has_node("Gameplay"):
				(root_viewport.get_node("Gameplay") as Gameplay).handle_input(event)

	if not event is InputEventMouse:
		return

	if not is_instance_valid(cur_scrollable):
		cur_scrollable = null

	for node_object in get_nodes_in_group("Scrollables"):
		## Comment
		var scrollable_object: Control = node_object # UNSAFE

		if scrollable_object.get_global_rect().has_point(scrollable_object.get_global_mouse_position()):
			cur_scrollable = scrollable_object

		elif scrollable_object == cur_scrollable:
			cur_scrollable = null

	if not is_instance_valid(cur_clickable):
		cur_clickable = null

	if not is_instance_valid(cur_hoverable):
		cur_hoverable = null

	for node_object in get_nodes_in_group("Hoverables"):
		## Comment
		var hoverable: Hoverable = node_object # UNSAFE

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

	if not event is InputEventMouseButton:
		return

	## [member event] as an [InputEventMouseButton].
	var mb_event := event as InputEventMouseButton

	match mb_event.button_index:
		BUTTON_LEFT:
			if mb_event.pressed and cur_hoverable is Clickable:
				cur_clickable = cur_hoverable as Clickable
				cur_clickable.click_start()

			elif cur_clickable != null:
				cur_clickable.click_end()
				cur_clickable = null

		BUTTON_WHEEL_UP:
			if mb_event.pressed:
				if w_event.alt:
					_volume_control(root_viewport).change_volume(volume_changing, vol_difference)

				elif cur_scrollable != null:
					cur_scrollable.rect_position.y = min(0, cur_scrollable.rect_position.y + 135)

		BUTTON_WHEEL_DOWN:
			if mb_event.pressed:
				if w_event.alt:
					_volume_control(root_viewport).change_volume(volume_changing, -vol_difference)

				elif cur_scrollable != null:
					cur_scrollable.rect_position.y = max(cur_scrollable.get_parent_control().rect_size.y - cur_scrollable.rect_size.y, cur_scrollable.rect_position.y - 135)


## Comment
func _volume_control(root_viewport: Root) -> VolumeControl:
	## Comment
	var volume_control := root_viewport.add_scene(VOLUME_CONTROL.instance(), ["VolumeControl", "SettingsPanel", "Bars", root_viewport.get_child(1).name]) as VolumeControl

	if not volume_control.modulate.a:
		volume_changing = 0

	## Comment
	var _tween := volume_control.tween_self(1, 0.25)

	return volume_control
