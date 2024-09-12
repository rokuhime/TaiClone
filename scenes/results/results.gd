extends Control

var score: ScoreData

@onready var score_label: Label = $MainPanel/VBoxContainer/Score/Value
@onready var accuracy_label: Label = $MainPanel/VBoxContainer/HBoxContainer/Accuracy/Value
@onready var combo_label: Label = $MainPanel/VBoxContainer/HBoxContainer/Combo/HBoxContainer/Value
@onready var max_combo_label: Label = $MainPanel/VBoxContainer/HBoxContainer/Combo/HBoxContainer/MaxValue

@onready var accurate_visual: Control = $RightSide/JudgementPanel/GridContainer/AccurateCount
@onready var f_accurate_visual: Control = $RightSide/JudgementPanel/GridContainer/AccFinishCount
@onready var inaccurate_visual: Control = $RightSide/JudgementPanel/GridContainer/InaccCount
@onready var f_inaccurate_visual: Control = $RightSide/JudgementPanel/GridContainer/InaccFinishCount
@onready var miss_visual: Control = $RightSide/JudgementPanel/GridContainer/MissCount

@onready var early_label: Label = $RightSide/JudgementPanel/GridContainer/LateEarlyCount/Early
@onready var late_label: Label = $RightSide/JudgementPanel/GridContainer/LateEarlyCount/Late

@onready var judgement_timeline: Control = $RightSide/JudgeTimeline/JudgementContainer

func _ready() -> void:
	var skin := Global.current_skin
	apply_skin(skin)
	
	# set navbar info
	Global.get_root().navigation_bars.set_navbar_buttons([])
	# wait a frame to ensure it will update properly
	await get_tree().process_frame
	
	var chart := Global.get_root().current_chart
	Global.get_root().navigation_bars.set_navbar_text([
					chart.chart_info["song_title"] + " - " + chart.chart_info["song_artist"],
					chart.chart_info["chart_title"] + " - " + chart.chart_info["chart_artist"],
					"Played by %s" % Global.player_name,
					Time.get_datetime_string_from_system(false, true)
					])
	
	early_label.modulate = skin.resources["colour"]["early"]
	late_label.modulate = skin.resources["colour"]["late"]

func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("Back"):
		Global.get_root().back_button_pressed()

func set_score(new_score: ScoreData) -> void:
	score = new_score
	
	var accuracy := Global.get_accuracy(score.accurate_hits, score.inaccurate_hits, score.miss_count)
	accuracy_label.text = "%0.2f%%" % accuracy
	# tint accuracy golden for ss
	if accuracy == 100:
		accuracy_label.self_modulate = Color("fff096")
	
	score_label.text = "%07d" % score.score
	combo_label.text = str(score.top_combo)
	max_combo_label.text = "/" + str(score.accurate_hits + score.inaccurate_hits + score.miss_count)
	
	accurate_visual.get_node("Label").text = str(score.accurate_hits)
	f_accurate_visual.get_node("Label").text = str(score.f_accurate_hits)
	inaccurate_visual.get_node("Label").text = str(score.inaccurate_hits)
	f_inaccurate_visual.get_node("Label").text = str(score.f_inaccurate_hits)
	miss_visual.get_node("Label").text = str(score.miss_count)
	
	early_label.text = str(score.early_hits) + " Early"
	late_label.text = str(score.late_hits) + " Late"

func apply_skin(skin: SkinManager) -> void:
	var judge_texture_names := ["judgement_accurate", "judgement_accurate_f", "judgement_inaccurate", "judgement_inaccurate_f", "judgement_miss"]
	var judge_rects := [
		accurate_visual.get_node("TextureRect"), 
		f_accurate_visual.get_node("TextureRect"), 
		inaccurate_visual.get_node("TextureRect"), 
		f_inaccurate_visual.get_node("TextureRect"), 
		miss_visual.get_node("TextureRect")
	]
	
	for i in judge_texture_names.size():
		if skin.resource_exists("texture/" + judge_texture_names[i]):
			judge_rects[i].texture = skin.resources["texture"][judge_texture_names[i]]
