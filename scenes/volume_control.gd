class_name VolumeControl
extends Scene

## Comment
signal volume_changed

## Comment
var _master_modulate_tween := SceneTreeTween.new()

## Comment
var _master_progress_tween := SceneTreeTween.new()

## Comment
var _music_modulate_tween := SceneTreeTween.new()

## Comment
var _music_progress_tween := SceneTreeTween.new()

## Comment
var _self_tween := SceneTreeTween.new()

## Comment
var _sfx_modulate_tween := SceneTreeTween.new()

## Comment
var _sfx_progress_tween := SceneTreeTween.new()

onready var timer := get_tree().create_timer(0)
onready var root_viewport := $"/root" as Root
onready var change_sound := $ChangeSound as AudioStreamPlayer
onready var music_vol := $Bars/Specifics/Music as CanvasItem
onready var sfx_vol := $Bars/Specifics/SFX as CanvasItem
onready var master_vol := $Bars/Master as CanvasItem


func _ready() -> void:
	GlobalTools.send_signal(root_viewport, "volume_changed", self, "save_settings")
	modulate.a = 0
	for i in range(AudioServer.bus_count):
		change_volume(i, 0, false)


## Comment
func change_channel(channel: int, needs_visible := true) -> void:
	if needs_visible and not modulate.a:
		return

	for i in range(AudioServer.bus_count):
		## Comment
		var new_color := 1.0 if i == channel else 0.5

		## Comment
		var vol := _vol_view(i)

		if vol.modulate.a == new_color or not modulate.a:
			vol.modulate.a = new_color
			continue

		match vol:
			master_vol:
				_master_modulate_tween = _modulate_vol_tween(vol, _master_modulate_tween, new_color)

			music_vol:
				_music_modulate_tween = _modulate_vol_tween(vol, _music_modulate_tween, new_color)

			sfx_vol:
				_sfx_modulate_tween = _modulate_vol_tween(vol, _sfx_modulate_tween, new_color)


## Comment
func change_volume(channel: int, amount: float, needs_tween := true) -> void:
	## Comment
	var channel_volume := clamp(db2linear(AudioServer.get_bus_volume_db(channel)) + amount, 0, 1)

	AudioServer.set_bus_volume_db(channel, linear2db(channel_volume))
	amount = round(channel_volume * 100)

	## Comment
	var vol := _vol_view(channel)

	(vol.get_node("Percentage") as Label).text = str(amount)

	## Comment
	var progress := vol.get_node("TextureProgress") as TextureProgress

	if not needs_tween:
		progress.value = amount
		return

	change_channel(channel, false)
	change_sound.pitch_scale = channel_volume / 2 + 1
	change_sound.play()
	emit_signal("volume_changed")
	match vol:
		master_vol:
			_master_progress_tween = _progress_tween(_master_progress_tween, progress, amount)

		music_vol:
			_music_progress_tween = _progress_tween(_music_progress_tween, progress, amount)

		sfx_vol:
			_sfx_progress_tween = _progress_tween(_sfx_progress_tween, progress, amount)


## See [Sceme].
func scene_removed() -> void:
	if timer.time_left <= 0:
		GlobalTools.send_signal(self, "finished", tween_self(0, 1), "queue_free")


## Comment
func tween_self(final_val: float, duration: float) -> PropertyTweener:
	if final_val:
		timer = get_tree().create_timer(2)
		GlobalTools.send_signal(self, "timeout", timer, "scene_removed")

	_self_tween = root_viewport.new_tween(_self_tween).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return _self_tween.tween_property(self, "modulate:a", final_val, duration)


## Comment
func _modulate_vol_tween(vol: CanvasItem, scene_tween: SceneTreeTween, new_color: float) -> SceneTreeTween:
	scene_tween = root_viewport.new_tween(scene_tween).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween = scene_tween.tween_property(vol, "modulate:a", new_color, 0.2)

	return scene_tween


## Comment
func _progress_tween(scene_tween: SceneTreeTween, progress: TextureProgress, amount: float) -> SceneTreeTween:
	scene_tween = root_viewport.new_tween(scene_tween).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween = scene_tween.tween_property(progress, "value", amount, 0.2)

	return scene_tween


## Comment
func _vol_view(channel: int) -> CanvasItem:
	match channel:
		1:
			return music_vol

		2:
			return sfx_vol

		_:
			return master_vol
