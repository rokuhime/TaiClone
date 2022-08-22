class_name MainUI
extends Node

onready var blackout = $Blackout as Control
onready var blackoutTween = $Blackout/Tween as Tween

onready var barTop = $Bars/Top as Control
onready var barBottom = $Bars/Bottom as Control
onready var barTween = $Bars/Tween as Tween

onready var mainmenuObj = preload("res://scenes/main_menu.tscn")
onready var songselectObj = preload("res://scenes/song_select.tscn")
onready var resultsObj = preload("res://scenes/results.tscn")
onready var testObj = preload("res://scenes/test.tscn")

var currentUI:String = "gameplay"
var optionsOpened:bool = false

func changeUI(menuID):
	print("changeUI from ", currentUI, " to ", menuID)
	
	#if just an options thing, toggle it
	if menuID == "options":
		optionsOpened = !optionsOpened

	#if its a main ui object, and new isnt the same...
	elif menuID != currentUI:
		currentUI = menuID

		#remove old ui
		if $CurrentUI.get_child_count() != 0:
			$CurrentUI.get_child(0).queue_free()

		#get new ui
		var newUI
		match menuID:
			"results":
				newUI = resultsObj.instance()
			"songselect":
				newUI = songselectObj.instance()
			"mainmenu":
				newUI = mainmenuObj.instance()
			"test":
				newUI = testObj.instance()
				newUI.get_node("AudioStreamPlayer").play(32.092)
		$CurrentUI.add_child(newUI)

func backButtonPressed():
	toggleBlackout()
	#figure out where we need to go
	match(currentUI):
		"gameplay":
			changeUI("songselect")
		"songselect":
			changeUI("mainmenu")
		"results":
			changeUI("songselect")
		_:
			print("back button pressed when unapplicable!")

func toggleBlackout():
	if not blackoutTween.remove(blackout, "self_modulate"):
		push_warning("Attempted to remove blackout animation tween.")

	#if blackout is invis...
	if(blackout.modulate.a > 0):
		if not blackoutTween.interpolate_property(blackout, "modulate", Color.white, Color.transparent, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT):
			push_warning("Attempted to tween blackout animation.")
	#if blackout is opaque...
	else:
		if not blackoutTween.interpolate_property(blackout, "modulate", Color.transparent, Color.white, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT):
			push_warning("Attempted to tween blackout animation.")

	if not blackoutTween.start():
		push_warning("Attempted to start blackout animation tween.")
