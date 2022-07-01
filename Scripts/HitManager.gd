extends Node

onready var music = get_node("../Music")
onready var drumInteraction = get_node("../DrumInteraction")
onready var objContainer = get_node("../BarRight/HitPointOffset/ObjectContainers")

var auto = false;

var accurateCount = 0;
var inaccurateCount = 0;
var missCount = 0;

var inaccTiming = 0.145
var accTiming = 0.06

var nextHittableNote = 0;

var lastSideUsedIsRight;
var lastNoteWasFinisher = false;

func _input(_ev) -> void:
	if !auto:
		if Input.is_action_just_pressed("LeftDon"): checkInput(false, false)
		if Input.is_action_just_pressed("RightDon"): checkInput(false, true)
		if Input.is_action_just_pressed("LeftKat"): checkInput(true, false)
		if Input.is_action_just_pressed("RightKat"): checkInput(true, true)
	
func _process(_delta) -> void:
	if (nextNoteExists()):
		#temp auto
		#doesnt support special note types currently
		if (auto && (music.get_playback_position() - objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1).timing) > 0):
			var nextNoteIsKat = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1).isKat
			
			if lastSideUsedIsRight == null: lastSideUsedIsRight = true
			checkInput(nextNoteIsKat, lastSideUsedIsRight)
			
			if !nextNoteIsKat:
				if lastSideUsedIsRight: #kDdk
					drumInteraction.keypressAnimation(1)
				else: #kdDk
					drumInteraction.keypressAnimation(2)
			else:
				if lastSideUsedIsRight: #Kddk
					drumInteraction.keypressAnimation(3)
				else: #kddK
					drumInteraction.keypressAnimation(4)
			lastSideUsedIsRight = !lastSideUsedIsRight
		
		#miss check
		if (!auto && (music.get_playback_position() - objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1).timing) > inaccTiming):
			drumInteraction.hitNotifyAnimation("miss");
			nextHittableNote += 1;

func checkInput(isKat, isRight) -> void:
	#finisher check
	if (lastNoteWasFinisher):
		var curTime = music.get_playback_position();
		var lastNote = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote);
		if (abs(curTime - lastNote.timing) <= accTiming && lastNote.isKat == isKat) && (lastSideUsedIsRight != isRight):
			#swallow input, give more points
			lastNoteWasFinisher = false

	# make sure theres a note in the chart first so no errors are thrown
	if (nextNoteExists()):
		#get next hittable note and current playback position
		var nextNote = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1);
		var curTime = music.get_playback_position();
		
		#if the next note is in time to hit and right key pressed
		if (abs(curTime - nextNote.timing) <= inaccTiming && nextNote.isKat == isKat):
			#check if accurate
			if (abs(curTime - nextNote.timing) <= accTiming):
				drumInteraction.hitNotifyAnimation("accurate");
				nextHittableNote += 1;
				nextNote.deactivate()
			else: 
				drumInteraction.hitNotifyAnimation("inaccurate");
				nextHittableNote += 1;
				nextNote.deactivate()
			
			if nextNote.finisher == true: lastNoteWasFinisher = true
		
		lastSideUsedIsRight = isRight

func nextNoteExists() -> bool:
		for subContainer in objContainer.get_children():
			if (subContainer.get_child_count() > 1):
				if (subContainer.get_child_count() - 1 >= nextHittableNote) && (objContainer.get_node("NoteContainer").get_child(nextHittableNote) != null):
					return true;
		return false;

func reset() -> void:
	accurateCount = 0
	inaccurateCount = 0
	missCount = 0
	nextHittableNote = 0
