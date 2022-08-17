extends Node

onready var scoreText = $Main/Organizer/Stats/Score as RichTextLabel
onready var comboText = $Main/Organizer/Stats/HBoxContainer/Combo as RichTextLabel
onready var accuracyText = $Main/Organizer/Stats/HBoxContainer/Accuracy as RichTextLabel

onready var scoreTween = $Main/Organizer/Stats/Score/Tween as Tween
onready var leftMenuTween = $Scoreboard/Tween as Tween
onready var rightMenuTween = $RightBar/Tween as Tween

var displayedScore: int = 0
var maxCombo: int = 1024

func _process(_a):
	if(scoreTween.is_active()):
		changeText("Score")

func changeText(type):
	var target
	var text: String = "[center][b]" + type + "[/b]\n"
	var val: String
	match type:
		"Score":
			target = scoreText
			var scoreDigits = str(displayedScore).length()
			#if score is more than 6 digits...
			if scoreDigits > 6:
				for i in range(len(str(displayedScore)) - 1, -1, -1):
					val += str(displayedScore)[(len(str(displayedScore)) - (i + 1))]
					if i % 3 == 0 and i != 0:
						val += ","
			#if score is equal to/under 6 digits...
			else:
				val = "%6d" % displayedScore
				val = val.substr(0,3) + "," + val.substr(3,6)

		"Combo":
			target = comboText

			#val = str(displayedCombo) + "[color=#737373][i]/" + str(maxCombo) + "[/i][/color]"
		"Accuracy":
			target = accuracyText
			#val = "%.2f%%" % displayedAccuracy
	text += val
	target.bbcode_text = text

func animateMenu(score):
	var target
	
	#looks butt ugly, but itll be changed with tools update
	target = scoreText
	if not scoreTween.remove(self, "displayedScore"):
		push_warning("Attempted to remove score change animation tween.")
	if not scoreTween.interpolate_property(self, "displayedScore", 0, score, 1.75, Tween.TRANS_QUINT, Tween.EASE_OUT):
		push_warning("Attempted to tween score change animation.")
	if not scoreTween.start():
		push_warning("Attempted to start score change animation tween.")

	if not leftMenuTween.remove($Scoreboard, "rect_position"):
		push_warning("Attempted to remove left menu animation tween.")
	if not leftMenuTween.interpolate_property($Scoreboard, "rect_position", Vector2(520,215), Vector2(16,215), 1, Tween.TRANS_QUINT, Tween.EASE_OUT):
		push_warning("Attempted to tween left menu animation.")
	if not leftMenuTween.start():
		push_warning("Attempted to start left menu animation tween.")

	if not rightMenuTween.remove($RightBar, "rect_position"):
		push_warning("Attempted to remove right menu animation tween.")
	if not rightMenuTween.interpolate_property($RightBar, "rect_position", Vector2(520,215), Vector2(1024,215), 1, Tween.TRANS_QUINT, Tween.EASE_OUT):
		push_warning("Attempted to tween right menu animation.")
	if not rightMenuTween.start():
		push_warning("Attempted to start right menu animation tween.")
