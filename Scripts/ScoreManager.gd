extends Node

var score = 0
var combo = 0

var accurateCount = 0
var inaccurateCount = 0
var missCount = 0
var currentUR = 0

onready var textDisplay = get_node("Label")

func addScore(type, multiplier):
	match type:
		"accurate":
			score += 300 * multiplier
			combo += 1
			accurateCount += 1
		"inaccurate":
			score += 150 * multiplier
			combo += 1
			inaccurateCount += 1
		"miss":
			combo = 0
			missCount += 1
		"spinnerHit":
			score += 50
		"spinnerFinish":
			score += 600
			combo += 1
		"sliderHit":
			score += 50 * multiplier
	updateText()

func reset():
	score = 0
	combo = 0
	
	accurateCount = 0
	inaccurateCount = 0
	missCount = 0

func updateText():
	var txt = ""
	txt += "score: " + str(score) + "\n"
	txt += "accurate: " + str(accurateCount) + "\n"
	txt += "inaccurate: " + str(inaccurateCount) + "\n"
	txt += "miss: " + str(missCount) + "\n"
	txt += "combo: " + str(combo) + "\n"
	textDisplay.text = txt;
