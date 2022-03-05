extends Node

onready var lKatObj = get_node("../Taiko-bar-left/leftKat")
onready var rKatObj = get_node("../Taiko-bar-left/rightKat")
onready var lDonObj = get_node("../Taiko-bar-left/leftDon")
onready var rDonObj = get_node("../Taiko-bar-left/rightDon")

onready var lDonAud = get_node("leftDonAudio")
onready var rDonAud = get_node("rightDonAudio")
onready var lKatAud = get_node("leftKatAudio")
onready var rKatAud = get_node("rightKatAudio")

onready var hit300Obj = get_node("../Taiko-bar-right/Approachcircle/AccurateNotif")
onready var hit100Obj = get_node("../Taiko-bar-right/Approachcircle/InnaccurateNotif")
onready var missObj = get_node("../Taiko-bar-right/Approachcircle/MissNotif")

onready var tween = get_node("DrumAnimationTween")

func _input(_ev) -> void:
	if Input.is_action_just_pressed("leftDon"): 
		keypressAnimation("leftDon")
		lDonAud.play()
	if Input.is_action_just_pressed("rightDon"): 
		keypressAnimation("rightDon")
		rDonAud.play()
	if Input.is_action_just_pressed("leftKat"): 
		keypressAnimation("leftKat")
		lKatAud.play()
	if Input.is_action_just_pressed("rightKat"): 
		keypressAnimation("rightKat")
		rKatAud.play()

func keypressAnimation(key) -> void:
	var obj
	match key:
		"leftDon": obj = lDonObj
		"rightDon": obj = rDonObj 
		"leftKat": obj = lKatObj
		"rightKat": obj = rKatObj
	
	tween.interpolate_property(obj, "self_modulate",
		Color(1,1,1,1), Color(1,1,1,0), 0.2,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()

func hitNotifyAnimation(type) -> void:
	var obj
	match type:
		"hit300": obj = hit300Obj
		"hit100": obj = hit100Obj
		"miss":   obj = missObj
	
	tween.interpolate_property(obj, "self_modulate",
		Color(1,1,1,1), Color(1,1,1,0), 0.2,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()


