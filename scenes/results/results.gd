extends Control

var score_data: Dictionary

@onready var score_label: Label = $MainPanel/VBoxContainer/Score/Value
@onready var accuracy_label: Label = $MainPanel/VBoxContainer/HBoxContainer/Accuracy/Value
@onready var combo_label: Label = $MainPanel/VBoxContainer/HBoxContainer/Combo/HBoxContainer/Value
@onready var max_combo_label: Label = $MainPanel/VBoxContainer/HBoxContainer/Combo/HBoxContainer/MaxValue
@onready var accurate_label: Label = $RightSide/JudgementPanel/GridContainer/AccurateCount/Label
@onready var f_accurate_label: Label = $RightSide/JudgementPanel/GridContainer/AccFinishCount/Label
@onready var inaccurate_label: Label = $RightSide/JudgementPanel/GridContainer/InaccCount/Label
@onready var f_inaccurate_label: Label = $RightSide/JudgementPanel/GridContainer/InaccFinishCount/Label
@onready var miss_label: Label = $RightSide/JudgementPanel/GridContainer/MissCount/Label
@onready var early_label: Label = $RightSide/JudgementPanel/GridContainer/LateEarlyCount/Early
@onready var late_label: Label = $RightSide/JudgementPanel/GridContainer/LateEarlyCount/Late

@onready var judgement_timeline: Control = $RightSide/JudgeTimeline/JudgementContainer

func _unhandled_key_input(event):
	# back to song select
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		get_tree().get_first_node_in_group("Root").change_state(1)

func get_accuracy() -> float:
	var total = score_data["AccurateHits"] + score_data["InaccurateHits"] + score_data["MissCount"]
	return total / (score_data["AccurateHits"] + (score_data["InaccurateHits"] / 2)) * 100

func set_score(score: Dictionary):
	score_data = score
	
	score_label.text = str(score_data["Score"])
	accuracy_label.text = "%0.2f%%" % Global.get_accuracy(score_data["AccurateHits"], score_data["InaccurateHits"], score_data["MissCount"])
	combo_label.text = str(score_data["TopCombo"])
	max_combo_label.text = "/" + str(score_data["AccurateHits"] + score_data["InaccurateHits"] + score_data["MissCount"])
	
	accurate_label.text = str(score_data["AccurateHits"])
	inaccurate_label.text = str(score_data["InaccurateHits"])
	miss_label.text = str(score_data["MissCount"])
