extends VBoxContainer

onready var fpsLabel := $Container/RightText/FPS as Label
onready var console := $Console as Label

func changeConsoleText(newText := ""):
	console.text = newText

func _process(delta):
	fpsLabel.text = "FPS: " + str(Engine.get_frames_per_second())
