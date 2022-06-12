extends KinematicBody2D

export var timing = 0
export var speed = 1
export var bpm = 238

export var finisher = true
export var isKat = false
export var active = false

func _ready() -> void:
	# note colour
	
	
	if(finisher): get_child(0).rect_scale = Vector2(0.9,0.9)
	
	activate()

func _process(delta) -> void:
	# move note if not hit yet
	if(active == true): move_and_slide(Vector2((speed * -1 * bpm), 0))

func activate() -> void:
	if(isKat): get_child(0).self_modulate = skin.KatColour
	else:      get_child(0).self_modulate = skin.DonColour
	active = true
	position = Vector2(timing * speed * bpm, 0)

func deactivate() -> void:
	modulate = Color(0,0,0,0)
	active = false
