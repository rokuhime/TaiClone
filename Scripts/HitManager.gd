extends Node

onready var music = get_node("../Music")
onready var drumInteraction = get_node("../DrumInteraction")
onready var noteContainer = get_node("../BarRight/HitPointOffset/ObjectContainers/NoteContainer")

var auto = false;

var accurateCount = 0;
var inaccurateCount = 0;
var missCount = 0;

var inaccTiming = 0.145
var accTiming = 0.06

var nextHittableNote = 0;

func _input(_ev) -> void:
	if !auto:
		if Input.is_action_just_pressed("LeftDon") || Input.is_action_just_pressed("RightDon"): checkInput(false)
		if Input.is_action_just_pressed("LeftKat") || Input.is_action_just_pressed("RightKat"): checkInput(true)
	
func _process(_delta) -> void:
	# UGLY!!!!!!!!!!!!! FIX ME HOOKHAT
	if (nextNoteExists()):
		#temp auto
		if (auto && (music.get_playback_position() - noteContainer.get_child(noteContainer.get_child_count() - nextHittableNote - 1).timing) > 0):
			checkInput(noteContainer.get_child(noteContainer.get_child_count() - nextHittableNote - 1).isKat)
		
		if (!auto && (music.get_playback_position() - noteContainer.get_child(noteContainer.get_child_count() - nextHittableNote - 1).timing) > inaccTiming):
			drumInteraction.hitNotifyAnimation("miss");
			nextHittableNote += 1;

func checkInput(type) -> void:
	# make sure theres a note in the chart first so no errors are thrown
	# might be able to trash if theres a check while loading the chart if theres at least 1 note
	if (nextNoteExists()):
		#get next hittable note and current playback position
		var nextNote = noteContainer.get_child(noteContainer.get_child_count() - nextHittableNote - 1);
		var curTime = music.get_playback_position();
		
		#if the next note is in time to hit and right key pressed
		if (abs(curTime - nextNote.timing) <= inaccTiming && nextNote.isKat == type):
			#check if accurate
			if (abs(curTime - nextNote.timing) <= accTiming):
				drumInteraction.hitNotifyAnimation("accurate");
				nextHittableNote += 1;
				nextNote.deactivate()
			else: 
				drumInteraction.hitNotifyAnimation("inaccurate");
				nextHittableNote += 1;
				nextNote.deactivate()

func nextNoteExists() -> bool:
		if (noteContainer.get_child_count() - 1 >= nextHittableNote) && (noteContainer.get_child(nextHittableNote) != null):
			return true;
		else: return false;

func reset() -> void:
	accurateCount = 0
	inaccurateCount = 0
	missCount = 0
	nextHittableNote = 0
