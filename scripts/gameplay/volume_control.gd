extends CanvasItem

## Comment
signal volume_changed

## Comment
const PROGRESS_TWEENS := []

## Comment
const VOL_TWEENS := []

## Comment
var _cur_changing := 0

## Comment
var _self_tween := SceneTreeTween.new()

onready var change_sound := $ChangeSound as AudioStreamPlayer
onready var timer := get_tree().create_timer(0)
onready var vols := [$Bars/Master, $Bars/Specifics/Music, $Bars/Specifics/SFX]


func _ready() -> void:
	for _i in range(vols.size()):
		PROGRESS_TWEENS.append(SceneTreeTween.new())
		VOL_TWEENS.append(SceneTreeTween.new())


func _input(event: InputEvent) -> void:
	if not (event is InputEventWithModifiers and event.is_pressed()):
		return

	## Comment
	var m_event := event as InputEventWithModifiers

	if not m_event.alt:
		return

	if not modulate.a:
		_cur_changing = 0

	## Comment
	var vol_difference := 0.01 if m_event.control else 0.05

	if event.is_action("VolumeUp"):
		_change_volume(vol_difference)

	if event.is_action("VolumeDown"):
		_change_volume(-vol_difference)

	if event.is_action("VolumeNext"):
		change_channel(_cur_changing + 1, false)

	if event.is_action("VolumePrevious"):
		change_channel(_cur_changing + 2, false)


## Comment
func change_channel(channel: int, needs_visible := true) -> void:
	if needs_visible and not modulate.a:
		return

	_cur_changing = channel % vols.size()
	for i in range(vols.size()):
		## Comment
		var colour := 1.0 if i == _cur_changing else 0.5

		## Comment
		var vol: CanvasItem = vols[i] # UNSAFE Variant

		if vol.modulate.a == colour or not modulate.a:
			vol.modulate.a = colour
			continue

		## Comment
		var tween: SceneTreeTween = Root.new_tween(VOL_TWEENS[i], self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT) # UNSAFE Variant

		## Comment
		var _tween = tween.tween_property(vol, "modulate:a", colour, 0.2)

		VOL_TWEENS[i] = tween # UNSAFE ArrayItem

	if modulate.a < 1:
		_self_tween = Root.new_tween(_self_tween, self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

		## Comment
		var _tween := _self_tween.tween_property(self, "modulate:a", 1.0, 0.25)

	timer = get_tree().create_timer(2)
	if timer.connect("timeout", self, "timeout"):
		push_warning("Attempted to connect Timer timeout.")


## Comment
func set_volume(channel: int, amount: float, needs_tween := false) -> void:
	AudioServer.set_bus_volume_db(channel, linear2db(amount))
	amount = round(amount * 100)

	## Comment
	var vol: CanvasItem = vols[channel] # UNSAFE Variant

	(vol.get_node("Percentage") as Label).text = str(amount)

	## Comment
	var progress := vol.get_node("TextureProgress") as TextureProgress

	if not needs_tween:
		progress.value = amount
		return

	## Comment
	var tween: SceneTreeTween = Root.new_tween(PROGRESS_TWEENS[channel], self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT) # UNSAFE Variant

	## Comment
	var _tween = tween.tween_property(progress, "value", amount, 0.2)

	PROGRESS_TWEENS[channel] = tween # UNSAFE ArrayItem


## Comment
func timeout() -> void:
	if timer.time_left <= 0:
		_self_tween = Root.new_tween(_self_tween, self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

		## Comment
		var _tween := _self_tween.tween_property(self, "modulate:a", 0.0, 1)


## Comment
func _change_volume(amount: float) -> void:
	change_channel(_cur_changing, false)

	## Comment
	var channel_volume := clamp(db2linear(AudioServer.get_bus_volume_db(_cur_changing)) + amount, 0, 1)

	set_volume(_cur_changing, channel_volume, true)
	change_sound.pitch_scale = channel_volume / 2 + 1
	change_sound.play()
	emit_signal("volume_changed")
