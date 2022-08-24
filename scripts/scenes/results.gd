extends Node

#Comment
var _animation_tween := SceneTreeTween.new()

onready var taiclone := $"/root" as Root


func _ready() -> void:
	($RightBar/HitCount/GridContainer/AccurateTexture as TextureRect).texture = taiclone.skin.accurate_judgement
	($RightBar/HitCount/GridContainer/FAccurateTexture as TextureRect).texture = taiclone.skin.accurate_judgement
	($RightBar/HitCount/GridContainer/InaccurateTexture as TextureRect).texture = taiclone.skin.inaccurate_judgement
	($RightBar/HitCount/GridContainer/FInaccurateTexture as TextureRect).texture = taiclone.skin.inaccurate_judgement
	($RightBar/HitCount/GridContainer/MissTexture as TextureRect).texture = taiclone.skin.miss_judgement
	($RightBar/HitCount/GridContainer/Late as CanvasItem).self_modulate = taiclone.skin.late_color
	($RightBar/HitCount/GridContainer/Early as CanvasItem).self_modulate = taiclone.skin.early_color
	($RightBar/ErrorBar/Late as CanvasItem).self_modulate = taiclone.skin.late_color
	($RightBar/ErrorBar/Early as CanvasItem).self_modulate = taiclone.skin.early_color

	_animation_tween = Root.new_tween(_animation_tween, self).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()

	# Comment
	var _score_tween := _animation_tween.tween_method(self, "score_text", 0, 1000000, 1.75)

	# Comment
	var _left_tween := _animation_tween.tween_property($Scoreboard, "rect_position:x", -417.0, 1).from(87.0)

	# Comment
	var _right_tween := _animation_tween.tween_property($RightBar, "rect_position:x", 591.0, 1).from(87.0)


## initialize ResultsScreen variables
#func change_properties(texts: Dictionary, judgements: Dictionary, mods: Array):
#	#texts
#	comboText.text = texts["combo"]
#	accuracyText.text = texts["accuracy"]

#	#judgements
#	judgementDisplay.get_node("Accurate/Amount").text = judgements["accurate"]
#	judgementDisplay.get_node("FAccurate/Amount").text = judgements["faccurate"]
#	judgementDisplay.get_node("Inaccurate/Amount").text = judgements["inaccurate"]
#	judgementDisplay.get_node("FInaccurate/Amount").text = judgements["finaccurate"]
#	judgementDisplay.get_node("Miss/Amount").text = judgements["miss"]

#	judgementDisplay.get_node("LateEarly/Organizer/Late/Amount").text = judgements["late"]
#	judgementDisplay.get_node("LateEarly/Organizer/Early/Amount").text = judgements["early"]

#	#mods
#	if mods.size() > 0:
#		#instance mod object to show the amount of mods
#		#rate changing/forced judgement/sv multiplier will show number, havent really figured out the design yet
#		pass

#	#rank
#	#get accuracy
#	var acc: float
#	acc = judgements["accurate"] + (judgements["inaccurate"] / 2)
#	acc = acc / (judgements["accurate"] + judgements["inaccurate"] + judgements["miss"]) * 100

#	var rank: String = get_rank(acc, judgements["miss"], [0,0], true)
#	match rank:
#		_:
#			#change texture of rankDisplay
#			pass

##doesnt belong here but for now /shrug
#func get_rank(accuracy: float, missCount: int, finishes: Array, rollsHit: bool) -> String:
#	#pretty much just pseudocode, just leaving it like this for now
#	#finishes[0] = hit finishers, finishes[1] = chart's finisher amount

#	#if 100% acc and all finishers hit and rolls fc'd
#	if accuracy == 100 and finishes[0] == finishes[1] and rollsHit:
#		return "P"
#	#if 100% acc
#	elif accuracy == 100:
#		return "SS"
#	#if fc
#	elif accuracy >= 95 and missCount == 0:

#	#generic accuracy based ranks
#		return "S"
#	elif accuracy > 95:
#		return "A"
#	elif accuracy > 80:
#		return "B"
#	elif accuracy > 65:
#		return "C"

#	return "F"


# Comment
func score_text(score: int) -> void:
	($Main/Score/Label as Label).text = str(score)
