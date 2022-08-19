class_name ResultsScreen
extends Node

onready var scoreText = $Main/Organizer/Stats/Score as RichTextLabel
onready var comboText = $Main/Organizer/Stats/HBoxContainer/Combo as RichTextLabel
onready var accuracyText = $Main/Organizer/Stats/HBoxContainer/Accuracy as RichTextLabel

onready var judgementDisplay = $RightBar/Organizer/HitCount/GridContainer as GridContainer

onready var rankDisplay = $Main/Organizer/Rank as TextureRect

onready var scoreTween = $Main/Organizer/Stats/Score/Tween as Tween
onready var leftMenuTween = $Scoreboard/Tween as Tween
onready var rightMenuTween = $RightBar/Tween as Tween

var displayedScore: int = 0
var maxCombo: int = 1024

func _process(_a):
	#change score text
	if(scoreTween.is_active()):
		var text: String = "[center][b]Score[/b]\n"
		var val: String
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
		text += val
		scoreText.bbcode_text = text

# initialize ResultsScreen variables
func change_properties(texts: Dictionary, judgements: Dictionary, mods: Array):
	#texts
	comboText.text = texts["combo"]
	accuracyText.text = texts["accuracy"]
	
	#judgements
	judgementDisplay.get_node("Accurate/Amount").text = judgements["accurate"]
	judgementDisplay.get_node("FAccurate/Amount").text = judgements["faccurate"]
	judgementDisplay.get_node("Inaccurate/Amount").text = judgements["inaccurate"]
	judgementDisplay.get_node("FInaccurate/Amount").text = judgements["finaccurate"]
	judgementDisplay.get_node("Miss/Amount").text = judgements["miss"]
	
	judgementDisplay.get_node("LateEarly/Organizer/Late/Amount").text = judgements["late"]
	judgementDisplay.get_node("LateEarly/Organizer/Early/Amount").text = judgements["early"]
	
	#mods
	if mods.size() > 0:
		#instance mod object to show the amount of mods
		#rate changing/forced judgement/sv multiplier will show number, havent really figured out the design yet
		pass
	
	#rank
	var rank: String = get_rank(100, 0, [1,1], true)
	match rank:
		_:
			#change texture of rankDisplay
			pass

#doesnt belong here but for now /shrug
func get_rank(accuracy: float, missCount: int, finishes: Array, rollsHit: bool) -> String:
	#pretty much just pseudocode, just leaving it like this for now
	#finishes[0] = hit finishers, finishes[1] = chart's finisher amount
	
	#if 100% acc and all finishers hit and rolls fc'd
	if accuracy == 100 and finishes[0] == finishes[1] and rollsHit:
		return "P"
	#if 100% acc
	elif accuracy == 100:
		return "SS"
	#if fc
	elif accuracy >= 95 and missCount == 0:
	
	#generic accuracy based ranks
		return "S"
	elif accuracy > 95:
		return "A"
	elif accuracy > 80:
		return "B"
	elif accuracy > 65:
		return "C"
	
	return "F"

func animate_menu(score):
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
