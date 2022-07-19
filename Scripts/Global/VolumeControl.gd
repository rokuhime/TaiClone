extends Panel

onready var masterVolView = get_node("Bars/Master/TextureProgress")
#onready var musicVolView = get_node()
#onready var noteVolView = get_node()

onready var changeSound = get_node("ChangeSound")

onready var tween = get_node("VolumeIncreaseTween")
onready var timer = get_node("Timer")
onready var music = get_node("../../Music")

var masterVol: float = 1
var musicVol: float = 1
var sfxVol: float = 1

var precise = false

func _input(ev):
	var changed = false

	if ev is InputEventKey:
		if ev.pressed and ev.scancode == 16777238:
			precise = true
		elif !ev.pressed and ev.scancode == 16777238:
			precise = false

	if Input.is_action_just_pressed("VolumeUp"):
		var volDifference = 0.05
		if precise: volDifference = 0.01

		if masterVol + volDifference > 1:
			masterVol = 1
			changed = true
		else: 
			masterVol += volDifference
			changed = true

	if Input.is_action_just_pressed("VolumeDown"):
		var volDifference = 0.05
		if precise: volDifference = 0.01
		
		if masterVol - volDifference < 0:
			masterVol = 0
			changed = true
		else: 
			masterVol -= volDifference
			changed = true

	if changed:
		get_node("Bars/Master/Percentage").text = str(masterVol * 100)
		
		tween.interpolate_property(masterVolView, "value",
			masterVolView.value, masterVol, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.start()
		
		changeVolume("master")
		

func changeVolume(type):
	changeSound.pitch_scale = masterVol / 2 + 1
	changeSound.play()
	var masterdb = linear2db(masterVol)
	var musicdb = linear2db((musicVol * masterVol) / 2)
	var sfxdb = linear2db((sfxVol * masterVol) / 2)
	
	appearanceTimeout()
	
	match(type):
		"master":
			music.volume_db = musicdb

func appearanceTimeout():
	if self.modulate == Color(1,1,1,0):
		tween.interpolate_property(self, "modulate",
			Color(1,1,1,0), Color(1,1,1,1), 0.25,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.start()
	
	timer.start()
	yield(timer, "timeout")

	tween.interpolate_property(self, "modulate",
			Color(1,1,1,1), Color(1,1,1,0), 1,
			Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
