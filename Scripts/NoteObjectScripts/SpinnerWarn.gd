extends KinematicBody2D

onready var spinnerObj = preload("res://Game/Objects/SpinnerObject.tscn")

export var timing = 0
export var speed = 1
export var length = 1

export var active = false

func _process(_delta) -> void:
	# move note if not hit yet
	if(active == true): 
		move_and_slide(Vector2((speed * -1), 0))
		if (get_node("../../../../../Music").get_playback_position() >= timing):
			deactivate()

func changeProperties(newTiming, newSpeed):
	timing = newTiming
	speed = newSpeed

func activate() -> void:
	modulate = Color(1,1,1,1)
	position = Vector2(timing * speed, 0)
	active = true

func deactivate() -> void:
	#make spinner obj first
	var spinner = spinnerObj.instance()
	spinner.changeProperties(timing, length)
	get_parent().add_child(spinner)
	get_parent().move_child(spinner, 0)
	
	#make self deactive (duh!)
	modulate = Color(0,0,0,0)
	active = false
