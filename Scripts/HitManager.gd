extends Node

onready var drumInteraction = get_node("../DrumInteraction")
onready var songManager = get_node("../SongManager")
onready var chartHolder = get_node("../ChartHolder")
onready var scoreManager = get_node("../ScoreManager")

var hitWindow = 0.147
var accurateWindow = 0.063

func _input(_ev) -> void:
	if Input.is_action_just_pressed("leftDon") || Input.is_action_just_pressed("rightDon"): checkInput(0)
	if Input.is_action_just_pressed("leftKat") || Input.is_action_just_pressed("rightKat"): checkInput(1)

func checkInput(inputType) -> void:
	if (chartHolder.get_child(0) != null):
		var nextNote = chartHolder.get_child(0)
		var songTime = songManager.getSongPos();
		
		#if note type is slider or spinner...
		if (nextNote.name.find("NoteObject") != -1):
			#don or kat, also checks if next note is right type
			if (nextNote.noteType == inputType):
				#if in hit window
				if (abs(songTime - nextNote.time) <= hitWindow):
					var multiplier = 1
					if nextNote.finisher == true: multiplier += 0.5
					#if kiai, add 0.25
					nextNote.noteHit()
					get_node("../urbar").doTheThing(songTime - nextNote.time)
					#if in accurate window
					if (abs(songTime - nextNote.time) <= accurateWindow):
						drumInteraction.hitNotifyAnimation("accurate")
						scoreManager.addScore("accurate", multiplier)
						#add score/acc/whatever
						pass
					else: #not hit accurately, but still hit
						drumInteraction.hitNotifyAnimation("inaccurate")
						scoreManager.addScore("inaccurate", multiplier)
						pass
