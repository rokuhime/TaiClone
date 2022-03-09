extends KinematicBody2D

onready var spinnerText = get_node("./TransOffset/Label")
onready var tween = get_node("Tween")
onready var scoreManager = get_node("../../ScoreManager")
onready var drumInteraction = get_node("../../DrumInteraction")
onready var songManager

var rotSpeed = 0
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
		Vector2(1.8,1.8), Vector2(0.3,0.3), length,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()

func _input(_ev) -> void:
	if (Input.is_action_just_pressed("leftDon") || Input.is_action_just_pressed("rightDon")) && (lastHitType == true): 
		lastHitType = false
		spinnerHit()
	elif (Input.is_action_just_pressed("leftKat") || Input.is_action_just_pressed("rightKat")) && (lastHitType == false): 
		lastHitType = true
		spinnerHit()
	spinnerText.text = str(hitGoal - hitCount)
	
	if hitCount >= hitGoal:
		scoreManager.addScore("spinnerFinish", 1)
		self.queue_free()

func _process(_delta) -> void:
	get_node("TransOffset/Spinner-circle").rotation_degrees += rotSpeed
	
	#miss detection
	if (songManager.getSongPos() > endTime) && songManager != null: # spinner not finished
		if (hitCount / hitGoal) >= 0.75: #if youve hit at least 3/4ths of the hits
			pass #give 100
			drumInteraction.hitNotifyAnimation("inaccurate")
		else: 
			drumInteraction.hitNotifyAnimation("miss")
			scoreManager.addScore("miss", 0)
			pass #miss
		self.queue_free()

func spinnerHit() -> void:
	hitCount += 1
	scoreManager.addScore("spinnerHit", 1)
	tween.interpolate_property(self, "rotSpeed",
		25, 0, 0.75,
		Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
