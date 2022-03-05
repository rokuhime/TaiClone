extends Node

onready var drumInteraction = get_node("../DrumInteraction")
onready var songManager = get_node("../SongManager")
onready var chartHolder = get_node("../ChartHolder")

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
		if (nextNote.noteType >= 2): pass 
		
		#don or kat, also checks if next note is right type
		elif (nextNote.noteType == inputType):
			#if in hit window
			if (abs(songTime - nextNote.time) <= hitWindow):
				nextNote.noteHit()
				get_node("../urbar").doTheThing(songTime - nextNote.time)
				#if in accurate window
				if (abs(songTime - nextNote.time) <= accurateWindow):
					drumInteraction.hitNotifyAnimation("hit300")
					#add score/acc/whatever
					pass
				else: #not hit accurately, but still hit
					drumInteraction.hitNotifyAnimation("hit100")
					pass
