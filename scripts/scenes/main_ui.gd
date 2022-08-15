extends Node

onready var resultsObj = preload("res://game/scenes/results.tscn")
onready var testObj = preload("res://game/scenes/test.tscn")

var currentUI:String = "results"
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
			"test":
				newUI = testObj.instance()
				newUI.get_node("AudioStreamPlayer").play(32.092)
		$CurrentUI.add_child(newUI)

func backButtonPressed():
	#figure out where we need to go
	match(currentUI):
		_:
			print("back button pressed when unapplicable!")
