extends Node

onready var music = get_node("../Music")
onready var drumInteraction = get_node("../DrumInteraction")
onready var objContainer = get_node("../BarRight/HitPointOffset/ObjectContainers")

onready var comboLabel = get_node("../BarLeft/DrumVisual/Combo")
onready var scoreLabel = get_node("../UI/Score")
onready var accuracyLabel = get_node("../UI/Accuracy")

var auto = false;

var accurateCount = 0;
var inaccurateCount = 0;
var missCount = 0;
var combo = 0;
var bestCombo = 0;
var score = 0;
var scoreMultiplier = 1;

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
			addScore("miss")
			nextHittableNote += 1;

func checkInput(isKat, isRight) -> void:
	#finisher check
	if (lastNoteWasFinisher):
		var curTime = music.get_playback_position();
		var lastNote = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote);
		if (abs(curTime - lastNote.timing) <= accTiming && lastNote.isKat == isKat) && (lastSideUsedIsRight != isRight):
			#swallow input, give more points
			addScore("finisher")
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
				addScore("accurate")
				nextHittableNote += 1;
				nextNote.deactivate()
			else: 
				addScore("inaccurate")
				nextHittableNote += 1;
				nextNote.deactivate()
			
			if nextNote.finisher == true: lastNoteWasFinisher = true
		
		lastSideUsedIsRight = isRight

func addScore(type) -> void:
	match type:
		"accurate":
			score += 300 * scoreMultiplier
			accurateCount += 1
			combo += 1
			drumInteraction.hitNotifyAnimation("accurate");
		"inaccurate":
			score += 150 * scoreMultiplier
			inaccurateCount += 1
			combo += 1
			drumInteraction.hitNotifyAnimation("inaccurate");
		"miss":
			missCount += 1
			combo = 0
			drumInteraction.hitNotifyAnimation("miss");
		"finisher":
			score += 300 * scoreMultiplier
		"spinner":
			score += 600 * scoreMultiplier
		"roll":
			score += 300 * scoreMultiplier
		_:
			pass;
	
	var accuracy: float = 0;
	if accurateCount + (inaccurateCount / 2) != 0:
		var hitCount = accurateCount + (float(inaccurateCount) / 2)
		var totalCount = accurateCount + inaccurateCount + missCount
		accuracy = float(hitCount / totalCount) * 100
		
	comboLabel.text = str(combo)
	scoreLabel.text = "%010d" % score
	accuracyLabel.text = "%2.2f" % accuracy

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
	combo = 0;
	bestCombo = 0;
	score = 0;
	scoreMultiplier = 1;
	addScore("")
