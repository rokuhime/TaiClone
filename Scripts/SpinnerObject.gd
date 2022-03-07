extends KinematicBody2D

onready var spinnerText = get_node("./TransOffset/Label")
onready var tween = get_node("Tween")
onready var songManager

var endTime = 0
var length = 0

var hitGoal = 10
var hitCount = 0

var lastHitType = true # false = d, true = k

func initialize(songManNode):
	songManager = songManNode
func _ready():
	spinnerText.text = str(hitGoal - hitCount)
	
	#make approach circle shrink
	tween.interpolate_property(get_node("TransOffset/Spinner-circle/Spinner-approachcircle"), "scale",
		Vector2(1.8,1.8), Vector2(0.1,0.1), 2,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	pass # Replace with function body.

func _input(_ev) -> void:
	if (Input.is_action_just_pressed("leftDon") || Input.is_action_just_pressed("rightDon")) && (lastHitType == true): 
		hitCount += 1
		lastHitType = false
	elif (Input.is_action_just_pressed("leftKat") || Input.is_action_just_pressed("rightKat")) && (lastHitType == false): 
		hitCount += 1
		lastHitType = true
	
	spinnerText.text = str(hitGoal - hitCount)
	
	if hitCount >= hitGoal:
		self.queue_free()

func _process(_delta) -> void:
	if (songManager.getSongPos() > endTime) && songManager != null: # spinner not finished
		if (hitCount / hitGoal) >= 0.75: #if youve hit at least 3/4ths of the hits
			pass #give 100
		else: #miss
			pass
			
		self.queue_free()
