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

func _ready() -> void:
	# set navbar info
	get_parent().set_navbar_buttons([])
	# wait a frame to ensure it will update properly
	await get_tree().process_frame
	
	var chart := Global.get_root().current_chart
	get_parent().set_navbar_text([
					chart.chart_info["Song_Title"] + " - " + chart.chart_info["Song_Artist"],
					chart.chart_info["Chart_Title"] + " - " + chart.chart_info["Chart_Artist"],
					"Played by %s" % Global.player_name,
					Time.get_datetime_string_from_system(false, true)
					])
	
	var skin := Global.get_root().current_skin
	early_label.modulate = skin.early_colour
	late_label.modulate = skin.late_colour

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		Global.get_root().back_button_pressed()

func set_score(score: Dictionary) -> void:
	score_data = score
	
	var accuracy := Global.get_accuracy(score_data["AccurateHits"], score_data["InaccurateHits"], score_data["MissCount"])
	accuracy_label.text = "%0.2f%%" % accuracy
	# tint accuracy golden for ss
	if accuracy == 100:
		accuracy_label.self_modulate = Color("fff096")
	
	score_label.text = "%07d" % score_data["Score"]
	combo_label.text = str(score_data["TopCombo"])
	max_combo_label.text = "/" + str(score_data["AccurateHits"] + score_data["InaccurateHits"] + score_data["MissCount"])
	
	accurate_label.text = str(score_data["AccurateHits"])
	f_accurate_label.text = str(score_data["FAccurateHits"])
	inaccurate_label.text = str(score_data["InaccurateHits"])
	f_inaccurate_label.text = str(score_data["FInaccurateHits"])
	miss_label.text = str(score_data["MissCount"])
	
	early_label.text = str(score_data["EarlyHits"]) + " Early"
	late_label.text = str(score_data["LateHits"]) + " Late"
