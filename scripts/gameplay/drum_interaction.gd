class_name DrumInteraction
extends Node

onready var f_don_aud := $"FinisherDonAudio" as AudioStreamPlayer
onready var f_kat_aud := $"FinisherKatAudio" as AudioStreamPlayer
onready var l_don_aud := $"LeftDonAudio" as AudioStreamPlayer
onready var l_kat_aud := $"LeftKatAudio" as AudioStreamPlayer
onready var r_don_aud := $"RightDonAudio" as AudioStreamPlayer
onready var r_kat_aud := $"RightKatAudio" as AudioStreamPlayer

onready var _l_don_obj := $"../BarLeft/DrumVisual/LeftDon" as CanvasItem
onready var _l_kat_obj := $"../BarLeft/DrumVisual/LeftKat" as CanvasItem
onready var _r_don_obj := $"../BarLeft/DrumVisual/RightDon" as CanvasItem
onready var _r_kat_obj := $"../BarLeft/DrumVisual/RightKat" as CanvasItem

onready var _accurate_obj := $"../BarRight/HitPointOffset/Judgements/JudgeAccurate" as CanvasItem
onready var _inaccurate_obj := $"../BarRight/HitPointOffset/Judgements/JudgeInccurate" as CanvasItem
onready var _miss_obj := $"../BarRight/HitPointOffset/Judgements/JudgeMiss" as CanvasItem

onready var _tween := $"DrumAnimationTween" as Tween


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("LeftDon"):
		keypress_animation(1)
	if event.is_action_pressed("RightDon"):
		keypress_animation(2)
	if event.is_action_pressed("LeftKat"):
		keypress_animation(3)
	if event.is_action_pressed("RightKat"):
		keypress_animation(4)


func hit_notify_animation(type: String) -> void:
	var obj: CanvasItem
	match type:
		"accurate":
			obj = _accurate_obj
		"innacurate":
			obj = _inaccurate_obj
		"miss":
			obj = _miss_obj
		_:
			push_warning("Unknown hit animation")
			return

	if not _tween.interpolate_property(obj, "self_modulate", Color.white, Color.transparent, 0.4, Tween.TRANS_LINEAR, Tween.EASE_OUT):
		push_warning("Attempted to tween hit animation.")
	if not _tween.start():
		push_warning("Attempted to start hit animation tween.")


func keypress_animation(key: int) -> void:
	var obj: CanvasItem
	match key:
		1:
			obj = _l_don_obj
			l_don_aud.play()
		2:
			obj = _r_don_obj
			r_don_aud.play()
		3:
			obj = _l_kat_obj
			l_kat_aud.play()
		4:
			obj = _r_kat_obj
			r_kat_aud.play()
		_:
			push_warning("Unknown keypress animation.")
			return

	if not _tween.interpolate_property(obj, "self_modulate", Color.white, Color.transparent, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT):
		push_warning("Attempted to tween keypress animation.")
	if not _tween.start():
		push_warning("Attempted to start keypress animation tween.")
