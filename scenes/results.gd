extends Scene

## Comment
var _animation_tween := SceneTreeTween.new()

onready var accuracy_label := $Main/H/Accuracy/Label as Label
onready var accurate_amount := $RightBar/HitCount/GridContainer/AccurateAmount as Label
onready var accurate_texture := $RightBar/HitCount/GridContainer/AccurateTexture as TextureRect
onready var combo_label := $Main/H/Combo/H/Label as Label
onready var early_error_bar := $RightBar/ErrorBar/Early as CanvasItem
onready var early_hit_count := $RightBar/HitCount/GridContainer/Early as CanvasItem
onready var early_hit_count_amount := $RightBar/HitCount/GridContainer/Early/Amount as Label
onready var f_accurate_amount := $RightBar/HitCount/GridContainer/FAccurateAmount as Label
onready var f_accurate_texture := $RightBar/HitCount/GridContainer/FAccurateTexture as TextureRect
onready var f_inaccurate_amount := $RightBar/HitCount/GridContainer/FInaccurateAmount as Label
onready var f_inaccurate_texture := $RightBar/HitCount/GridContainer/FInaccurateTexture as TextureRect
onready var inaccurate_amount := $RightBar/HitCount/GridContainer/InaccurateAmount as Label
onready var inaccurate_texture := $RightBar/HitCount/GridContainer/InaccurateTexture as TextureRect
onready var late_error_bar := $RightBar/ErrorBar/Late as CanvasItem
onready var late_hit_count := $RightBar/HitCount/GridContainer/Late as CanvasItem
onready var late_hit_count_amount := $RightBar/HitCount/GridContainer/Late/Amount as Label
onready var max_combo_label := $Main/H/Combo/H/Max as Label
onready var miss_amount := $RightBar/HitCount/GridContainer/MissAmount as Label
onready var miss_texture := $RightBar/HitCount/GridContainer/MissTexture as TextureRect
onready var right_bar := $RightBar
onready var root_viewport := $"/root" as Root
onready var score_label := $Main/Score/Label as Label
onready var scoreboard := $Scoreboard


func _ready() -> void:
	accuracy_label.text = root_viewport.accuracy + "%"
	accurate_amount.text = str(root_viewport.accurate_count - root_viewport.f_accurate_count)
	accurate_texture.texture = root_viewport.skin.accurate_judgement
	combo_label.text = str(root_viewport.combo)
	early_error_bar.modulate = root_viewport.skin.early_color
	early_hit_count.modulate = root_viewport.skin.early_color
	early_hit_count_amount.text = str(root_viewport.early_count)
	f_accurate_amount.text = str(root_viewport.f_accurate_count)
	f_accurate_texture.texture = root_viewport.skin.accurate_judgement
	f_inaccurate_amount.text = str(root_viewport.f_inaccurate_count)
	f_inaccurate_texture.texture = root_viewport.skin.inaccurate_judgement
	inaccurate_amount.text = str(root_viewport.inaccurate_count - root_viewport.f_inaccurate_count)
	inaccurate_texture.texture = root_viewport.skin.inaccurate_judgement
	late_error_bar.modulate = root_viewport.skin.late_color
	late_hit_count.modulate = root_viewport.skin.late_color
	late_hit_count_amount.text = str(root_viewport.late_count)
	max_combo_label.text = "/" + str(root_viewport.max_combo)
	miss_amount.text = str(root_viewport.miss_count)
	miss_texture.texture = root_viewport.skin.miss_judgement
	_animation_tween = root_viewport.new_tween(_animation_tween).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()

	## Comment
	var _score_tween := _animation_tween.tween_method(self, "score_text", 0, root_viewport.score, 1.75)

	## Comment
	var _left_tween := _animation_tween.tween_property(scoreboard, "rect_position:x", -417.0, 1).from(87.0)

	## Comment
	var _right_tween := _animation_tween.tween_property(right_bar, "rect_position:x", 591.0, 1).from(87.0)

	## Comment
	var _settings_removed := root_viewport.remove_scene("SettingsPanel")

	root_viewport.add_scene(root_viewport.bars.instance())


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


## Comment
func score_text(score: int) -> void:
	score_label.text = str(score)
