extends Control

var score: ScoreInstance

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
					chart.chart_info["song_title"] + " - " + chart.chart_info["song_artist"],
					chart.chart_info["chart_title"] + " - " + chart.chart_info["chart_artist"],
					"Played by %s" % Global.player_name,
					Time.get_datetime_string_from_system(false, true)
					])
	
	var skin := Global.get_root().current_skin
	early_label.modulate = skin.early_colour
	late_label.modulate = skin.late_colour

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		Global.get_root().back_button_pressed()

func set_score(new_score: ScoreInstance) -> void:
	score = new_score
	
	var accuracy := Global.get_accuracy(score.accurate_hits, score.inaccurate_hits, score.miss_count)
	accuracy_label.text = "%0.2f%%" % accuracy
	# tint accuracy golden for ss
	if accuracy == 100:
		accuracy_label.self_modulate = Color("fff096")
	
	score_label.text = "%07d" % score.score
	combo_label.text = str(score.top_combo)
	max_combo_label.text = "/" + str(score.accurate_hits + score.inaccurate_hits + score.miss_count)
	
	accurate_label.text = str(score.accurate_hits)
	f_accurate_label.text = str(score.f_accurate_hits)
	inaccurate_label.text = str(score.inaccurate_hits)
	f_inaccurate_label.text = str(score.f_inaccurate_hits)
	miss_label.text = str(score.miss_count)
	
	early_label.text = str(score.early_hits) + " Early"
	late_label.text = str(score.late_hits) + " Late"
