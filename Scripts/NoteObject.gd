extends KinematicBody2D

onready var drumInteraction = get_node("../../DrumInteraction")
onready var songManager = get_node("../../SongManager")
onready var hitManager = get_node("../../HitManager")
export var noteType = 1
#0 = d, 1 = k, 2 = slider, 3 = spinner

export var finisher = false

export var time = 4.655
export var endTime = 0
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
	
	#set position in chart
	self.set_position(Vector2((time + SongSettings.offset) * scrollVelocity, 244.75))
	
#func _physics_process(_delta) -> void:
#	move_and_slide(Vector2((scrollVelocity * -1), 0), Vector2.UP)
	
func makeSpecial(type, time, ex): #fix me hookhat!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	match type:
		"slider":
			var distance = 2 * ex
			pass
		"spinner":
			pass

func noteHit() -> void:
	var new_parent = get_node("../../HitNotes")
	get_parent().remove_child(self)
	new_parent.add_child(self)

func _process(_delta) -> void:
	self.position = Vector2((time - songManager.getSongPos()) * scrollVelocity, 0)
	
	if (songManager.getSongPos() - hitManager.hitWindow + SongSettings.offset > time) && self.get_parent() == get_node("../../ChartHolder"):
		print("note missed")
		var new_parent = get_node("../../MissedNotes")
		get_parent().remove_child(self)
		new_parent.add_child(self)
		get_node("../../DrumInteraction/leftDonAudio").play()
		drumInteraction.hitNotifyAnimation("miss")
