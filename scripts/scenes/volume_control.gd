extends CanvasItem

signal volume_changed

const PROGRESS_TWEENS := []
const VOL_TWEENS := []

var _cur_changing := 0
var _self_tween := SceneTreeTween.new()

onready var timer := get_tree().create_timer(0)
onready var vols := [$Bars/Master, $Bars/Specifics/Music, $Bars/Specifics/SFX]


func _ready() -> void:
	for _i in range(vols.size()):
		PROGRESS_TWEENS.append(SceneTreeTween.new())
		VOL_TWEENS.append(SceneTreeTween.new())


func _input(event: InputEvent) -> void:
	if not (event is InputEventWithModifiers and event.is_pressed()):
		return
	var m_event := event as InputEventWithModifiers
	if not m_event.alt:
		return

	if not modulate.a:
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
	if needs_visible and not modulate.a:
		return
	_cur_changing = channel % vols.size()

	for i in range(vols.size()):
		var colour := Color.white if i == _cur_changing else Color(1, 1, 1, 0.5)
		var vol: CanvasItem = vols[i] # UNSAFE Variant

		if vol.modulate == colour or not modulate.a:
			vol.modulate = colour
			continue
		var tween := Root.new_tween(VOL_TWEENS[i], self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		var _tween = tween.tween_property(vol, "modulate", colour, 0.2)
		VOL_TWEENS[i] = tween # UNSAFE ArrayItem

	# appearance_timeout function
	if modulate.a < 1:
		_self_tween = Root.new_tween(_self_tween, self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		var _tween := _self_tween.tween_property(self, "modulate", Color.white, 0.25)

	timer = get_tree().create_timer(2)
	if timer.connect("timeout", self, "timeout"):
		push_warning("Attempted to connect Timer timeout.")


func set_volume(channel: int, amount: float, needs_tween := false) -> void:
	AudioServer.set_bus_volume_db(channel, linear2db(amount))

	amount = round(amount * 100)
	var vol: CanvasItem = vols[channel] # UNSAFE Variant
	(vol.get_node("Percentage") as Label).text = str(amount)

	var progress := vol.get_node("TextureProgress") as TextureProgress
	if not needs_tween:
		progress.value = amount
		return

	var tween: SceneTreeTween = Root.new_tween(PROGRESS_TWEENS[channel], self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT) # UNSAFE Variant
	var _tween = tween.tween_property(progress, "value", amount, 0.2)
	PROGRESS_TWEENS[channel] = tween # UNSAFE ArrayItem


func timeout() -> void:
	if timer.time_left <= 0:
		_self_tween = Root.new_tween(_self_tween, self).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		if _self_tween.tween_property(self, "modulate", Color.transparent, 1).connect("finished", self, "hide"):
			push_warning("Attempted to connect PropertyTweener finish.")


func _change_volume(amount: float) -> void:
	change_channel(_cur_changing, false)

	var channel_volume := clamp(db2linear(AudioServer.get_bus_volume_db(_cur_changing)) + amount, 0, 1)

	set_volume(_cur_changing, channel_volume, true)

	var change_sound := $ChangeSound as AudioStreamPlayer
	change_sound.pitch_scale = channel_volume / 2 + 1
	change_sound.play()
	emit_signal("volume_changed")
