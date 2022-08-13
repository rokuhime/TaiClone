extends CanvasItem

var _cur_changing := 0

onready var timer := get_tree().create_timer(0)
onready var tween := $VolumeIncreaseTween as Tween


func _input(event: InputEvent) -> void:
	if not (event is InputEventWithModifiers and event.is_pressed()):
		return
	var m_event := event as InputEventWithModifiers
	if not m_event.alt:
		return

	if modulate.a == 0:
		_cur_changing = 0

	var vol_difference := 0.01 if m_event.control else 0.05

	if event.is_action("VolumeUp"):
		_change_volume(vol_difference)

	if event.is_action("VolumeDown"):
		_change_volume(-vol_difference)

	if event.is_action("VolumeNext"):
		change_channel(_cur_changing + 1, false)

	if event.is_action("VolumePrevious"):
		change_channel(_cur_changing + 2, false)


func change_channel(channel: int, needs_visible := true) -> void:
	if needs_visible and modulate.a == 0:
		return
	_cur_changing = channel % 3

	for i in range(3):
		var colour := Color.white if i == _cur_changing else Color(1, 1, 1, 0.5)
		var vol := _vol_view(i)

		if vol.modulate == colour:
			continue
		if not tween.remove(vol, "modulate"):
			push_warning("Attempted to remove volume fade tween.")
		if modulate.a == 0:
			vol.modulate = colour
			continue
		if not tween.interpolate_property(vol, "modulate", null, colour, 0.2, Tween.TRANS_QUART, Tween.EASE_OUT):
			push_warning("Attempted to tween volume fade.")
		if not tween.start():
			push_warning("Attempted to start volume fade tween.")

	# appearance_timeout function
	if modulate.a < 1:
		if not tween.remove(self, "modulate"):
			push_warning("Attempted to remove volume control fade tween.")
		if not tween.interpolate_property(self, "modulate", null, Color.white, 0.25, Tween.TRANS_QUART, Tween.EASE_OUT):
			push_warning("Attempted to tween volume control fade in.")
		if not tween.start():
			push_warning("Attempted to start volume control fade in tween.")

	timer = get_tree().create_timer(2)
	if timer.connect("timeout", self, "timeout"):
		push_warning("Attempted to connect timer timeout.")


func set_volume(channel: int, amount: float, needs_tween := false) -> void:
	AudioServer.set_bus_volume_db(channel, linear2db(amount))

	amount = round(amount * 100)
	var vol := _vol_view(channel)
	(vol.get_node("Percentage") as Label).text = str(amount)

	var progress := vol.get_node("TextureProgress") as TextureProgress
	if not needs_tween:
		progress.value = amount
		return

	if not tween.remove(progress, "value"):
		push_warning("Attempted to remove volume progress tween.")
	if not tween.interpolate_property(progress, "value", null, amount, 0.2, Tween.TRANS_QUART, Tween.EASE_OUT):
		push_warning("Attempted to tween volume progress.")
	if not tween.start():
		push_warning("Attempted to start volume progress tween.")


func timeout() -> void:
	if timer.time_left > 0:
		return
	if not tween.remove(self, "modulate"):
		push_warning("Attempted to remove volume control fade out tween.")
	if not tween.interpolate_property(self, "modulate", Color.white, Color.transparent, 1, Tween.TRANS_QUART, Tween.EASE_OUT):
		push_warning("Attempted to tween volume control fade out.")
	if not tween.start():
		push_warning("Attempted to start volume control fade out tween.")


func _change_volume(amount: float) -> void:
	change_channel(_cur_changing, false)

	var channel_volume := clamp(db2linear(AudioServer.get_bus_volume_db(_cur_changing)) + amount, 0, 1)

	set_volume(_cur_changing, channel_volume, true)

	var change_sound := $ChangeSound as AudioStreamPlayer
	change_sound.pitch_scale = channel_volume / 2 + 1
	change_sound.play()


func _vol_view(channel: int) -> CanvasItem:
	match channel:
		1:
			return $Bars/Specifics/Music as CanvasItem
		2:
			return $Bars/Specifics/SFX as CanvasItem
		_:
			return $Bars/Master as CanvasItem
