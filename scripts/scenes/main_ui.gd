class_name MainUI
extends Node

onready var blackout = $Blackout as Control

onready var barTop = $Bars/Top as Control
onready var barBottom = $Bars/Bottom as Control
onready var barTween = $Bars/Tween as Tween

onready var mainmenuObj = preload("res://game/scenes/main_menu.tscn")
onready var songselectObj = preload("res://game/scenes/song_select.tscn")
onready var resultsObj = preload("res://game/scenes/results.tscn")
onready var testObj = preload("res://game/scenes/test.tscn")

var currentUI:String = "gameplay"
var optionsOpened:bool = false
var barsOpened:bool = true

func changeUI(menuID):
	print("changeUI from ", currentUI, " to ", menuID)
	
	#if just an options thing, toggle it
	if menuID == "options":
		optionsOpened = !optionsOpened

	#if its a main ui object, and new isnt the same...
	elif menuID != currentUI:
		#fade out of current ui
		toggleBlackout(true)
		yield($Blackout/Tween, "tween_completed")
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
				if !barsOpened: 
					toggleBars(true, "slow")
				newUI = songselectObj.instance()
			"mainmenu":
				toggleBars(false, "fast")
				newUI = mainmenuObj.instance()
			"test":
				newUI = testObj.instance()
				newUI.get_node("AudioStreamPlayer").play(32.092)
		$CurrentUI.add_child(newUI)
		
		#fade back into ui
		toggleBlackout(false)

func changeBars(menuID):
	print("changeBars to ", menuID)
	match menuID:
		
		_:
			pass

func backButtonPressed():
	#just incase things go horribly wrong and we arent even in a ui
	if $CurrentUI.get_child_count() <= 0:
		return
	
	#figure out where we need to go
	match($CurrentUI.get_child(0).name):
		"Gameplay":
			changeUI("songselect")
		"SongSelect":
			changeUI("mainmenu")
		"Results":
			changeUI("songselect")
		_:
			print("back button pressed when unapplicable!")
	playMenuSound("Back")

func toggleBlackout(enabled):
	var blackoutTween := $Blackout/Tween as Tween

	var from: Color
	var to: Color
	
	#if blackout is opaque...
	if enabled:
		from = Color.transparent
		to = Color.white
	#if blackout is invis...
	else:
		from = Color.white
		to = Color.transparent
	
	if not blackoutTween.remove(self, "self_modulate"):
		push_warning("Attempted to remove score change animation tween.")
	if not blackoutTween.interpolate_property(blackout, "self_modulate", from, to, 0.5, Tween.TRANS_QUINT, Tween.EASE_OUT):
		push_warning("Attempted to tween score change animation.")
	if not blackoutTween.start():
		push_warning("Attempted to start score change animation tween.")

func toggleBars(enabled, type):
	match type:
		"fast":
			if enabled:
				barsOpened = true
				
				print($Bars/Bottom.rect_scale.y)
				$Bars/Top.set_global_position(Vector2(0,0))
				$Bars/Bottom.set_global_position(Vector2(0,1080 - $Bars/Bottom.rect_size.y))
			else:
				barsOpened = false
				$Bars/Top.set_global_position(Vector2(0,0 - $Bars/Top.rect_size.y))
				$Bars/Bottom.set_global_position(Vector2(0,1080))
		"slow":
			var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			if enabled:
				barsOpened = true
				if not tween.tween_property($Bars/Top, "rect_global_position", Vector2(0,0), 1):
					pass
				if not tween.parallel().tween_property($Bars/Bottom, "rect_global_position", Vector2(0,980), 1):
					pass
			else:
				barsOpened = false
				if not tween.tween_property($Bars/Top, "rect_global_position", Vector2(0,-100), 1):
					pass
				if not tween.parallel().tween_property($Bars/Bottom, "rect_global_position", Vector2(0,1080), 1):
					pass

func playMenuSound(type):
	(get_node("Sounds/%s" % type) as AudioStreamPlayer).play()
