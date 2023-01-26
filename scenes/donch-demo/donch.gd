extends Node

onready var donch := $donch as AnimatedSprite
onready var rim := $donch/rim as AnimatedSprite
onready var face := $donch/face as AnimatedSprite
onready var side := $donch/side as AnimatedSprite

var currentState := 0
func changeColor(color: Color, layer: int) -> void:
	match layer:
		0:
			donch.self_modulate = color
		1:
			rim.self_modulate = color
		2:
			face.self_modulate = color
		3:
			side.self_modulate = color

func changeSpeedFromBPM(bpm : float) -> void:
	donch.speed_scale = bpm / 60.0
	for child in donch.get_children():
		if child.type == AnimatedSprite:
			child.speed_scale = bpm / 60.0

func changeState(state) -> void:
	var stateName := ""
	state = int(state)
	match state:
		0:
			stateName = "idle"
		1:
			stateName = "kiai"
		2:
			stateName = "miss"
	donch.animation = stateName
	for child in donch.get_children():
		if child.type == AnimatedSprite:
			child.animation = stateName
