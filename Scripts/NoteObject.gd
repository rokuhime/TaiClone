extends KinematicBody2D

onready var spinnerObj = preload("res://Objects/SpinnerObject.tscn")

onready var drumInteraction = get_node("../../DrumInteraction")
onready var songManager = get_node("../../SongManager")
onready var hitManager = get_node("../../HitManager")
onready var scoreManager = get_node("../../ScoreManager")
export var noteType = 1
#0 = d, 1 = k, 2 = slider, 3 = spinner

export var finisher = false
var passedHitPoint = false

export var time = 4.655
var endTime = 0
export var scrollVelocity = 1000

func initialize() -> void:
	#change look based off of note type
	match noteType:
		1: get_child(0).get_child(2).self_modulate = Color("438EAC") # kat
		
		2: #slider
			get_child(0).get_child(2).self_modulate = Color("FCB806") 
			#extra parts
			get_child(0).get_child(0).self_modulate = Color("FCB806") 
			get_child(0).get_child(1).self_modulate = Color("FCB806") 
		
		3: get_child(0).get_child(2).self_modulate = Color("B8B8B8") #spinner
	
	if finisher:
		#fix for skins. maybe make skin manager but that sounds kinda goofy at this point but well see idk
		get_node("TransOffset/BaseSprite").texture = preload("res://Skins/Default/taikobigcircle.png")
		get_node("TransOffset/BaseSprite").scale = Vector2(0.95,0.95)
	
	#set position in chart
	self.set_position(Vector2((time + SongSettings.offset) * scrollVelocity, 244.75))
	
#func _physics_process(_delta) -> void:
#	move_and_slide(Vector2((scrollVelocity * -1), 0), Vector2.UP)
	
func makeSpecial(type, time, ex): #fix me hookhat!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	match type:
		"slider":
			var pixelLength = time * ex # slider length * repeats
			endTime = pixelLength / (100 * SongSettings.baseVelocity);
			get_child(0).get_child(0).scale = Vector2(endTime * 100,0.55)
			get_child(0).get_child(1).position = Vector2(time + endTime, 0)
			pass
		"spinner":
			endTime = float(time) / 1000
			pass

func noteHit() -> void:
	if (noteType < 2) : # if d/k
		var new_parent = get_node("../../HitNotes")
		get_parent().remove_child(self)
		new_parent.add_child(self)

func _process(_delta) -> void:
	self.position = Vector2((time - songManager.getSongPos()) * scrollVelocity, 0)
	
	#missing notes
	if (songManager.getSongPos() - hitManager.hitWindow + SongSettings.offset > time) && self.get_parent() == get_node("../../ChartHolder") && noteType < 2:
		print("note missed")
		var new_parent = get_node("../../MissedNotes")
		get_parent().remove_child(self)
		new_parent.add_child(self)
		get_node("../../DrumInteraction/leftDonAudio").play()
		drumInteraction.hitNotifyAnimation("miss")
		scoreManager.addScore("miss", 0)
	
	#spinner spawning
	if ((songManager.getSongPos() - SongSettings.offset > time) && self.get_parent() == get_node("../../ChartHolder") && noteType == 3) && passedHitPoint == false:
		passedHitPoint = true
		print("spinner spawn called")
		var spinner = spinnerObj.instance()
		spinner.endTime = endTime
		spinner.hitGoal = round(((endTime - time) / songManager.bpm) * 4)
		spinner.length = (endTime - time)
		spinner.initialize(songManager)
		self.get_parent().add_child(spinner)
		self.queue_free()
