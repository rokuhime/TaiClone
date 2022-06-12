extends Node

onready var music = get_node("../Music")
onready var drumInteraction = get_node("../DrumInteraction")
onready var noteContainer = get_node("../BarRight/ObjectContainers/NoteContainer")

var accurateCount = 0;
var inaccurateCount = 0;
var missCount = 0;

var inaccTiming = 0.145
var accTiming = 0.06

var nextHittableNote = 0;

func _input(_ev) -> void:
	if Input.is_action_just_pressed("LeftDon") || Input.is_action_just_pressed("RightDon"): checkInput(false)
	if Input.is_action_just_pressed("LeftKat") || Input.is_action_just_pressed("RightKat"): checkInput(true)
	
func _process(delta) -> void:
	# UGLY!!!!!!!!!!!!! FIX ME HOOKHAT
	if (nextNoteExists()):
		if (music.get_playback_position() - noteContainer.get_child(nextHittableNote).timing) > inaccTiming:
			drumInteraction.hitNotifyAnimation("miss");
			nextHittableNote += 1;

func checkInput(type) -> void:
	# make sure theres a note in the chart first so no errors are thrown
	# might be able to trash if theres a check while loading the chart if theres at least 1 note
	if (nextNoteExists()):
		#get next hittable note and current playback position
		var nextNote = get_node("../BarRight/ObjectContainers/NoteContainer").get_child(nextHittableNote);
		var curTime = music.get_playback_position();
		
		#if the next note is in time to hit and right key pressed
		if (abs(curTime - nextNote.timing) <= inaccTiming && nextNote.isKat == type):
			#check if accurate
			if (abs(curTime - nextNote.timing) <= accTiming):
				drumInteraction.hitNotifyAnimation("accurate");
				nextHittableNote += 1;
				print("accurate hit")
				nextNote.deactivate()
			else: 
				drumInteraction.hitNotifyAnimation("inaccurate");
				nextHittableNote += 1;
				print("inaccurate hit")
				nextNote.deactivate()

func nextNoteExists() -> bool:
		if (noteContainer.get_child_count() - 1 >= nextHittableNote) && (noteContainer.get_child(nextHittableNote) != null):
			return true;
		else: return false;
