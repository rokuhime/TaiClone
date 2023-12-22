class_name ScoreManager
extends Control

var score := 0
var accurate_hits := 0
var inaccurate_hits := 0
var miss_count := 0

var early_hits := 0
var late_hits := 0

var top_combo := 0
var current_combo := 0

@onready var raw_info : Label = $RawInfo

@onready var score_label : Label = $Score
@onready var accuracy_label : Label = $Accuracy
@onready var combo_label : Label = $Combo

@onready var song_progress_bar : TextureProgressBar = $SongProgressMeter
@onready var health_bar : TextureProgressBar = $Health
@onready var combo_break_player : AudioStreamPlayer = $ComboBreak

@onready var judgement_indicators : Node = $Judgements
var judgement_indicator_tweens : Array = [null, null, null]

#@onready var hit_error_bar: HitErrorBar = $HitErrorBar

func update_visuals() -> void:
	score_label.text = "%07d" % score
	combo_label.text = str(current_combo)
	
	var accuracy_text : String = "%0.2f%%" % get_accuracy()
	if accuracy_text.length() < 6:
		for i in 6 - accuracy_text.length():
			accuracy_text = "0" + accuracy_text
	accuracy_label.text = accuracy_text
	
	raw_info.text = "accurate: " + str(accurate_hits) + "\ninaccurate: " + str(inaccurate_hits) + "\nmiss: " + str(miss_count)

func get_accuracy() -> float:
	var acc_hit_count : float = (accurate_hits + float(inaccurate_hits / 2.0))
	if acc_hit_count == 0:
		return 0.0
	return (acc_hit_count / float(accurate_hits + inaccurate_hits + miss_count)) * 100.0

func add_score(hit_time_difference: float, missed := false) -> void:
	var score_type := 0
	if abs(hit_time_difference) <= Global.INACC_TIMING and missed == false:
		if abs(hit_time_difference) <= Global.ACC_TIMING:
			score_type += 1
		score_type += 1 
	
	match score_type:
		0:  # miss
			if current_combo > top_combo:
				top_combo = current_combo
			
			if current_combo > 10:
				combo_break_player.play()
			
			current_combo = 0
			miss_count += 1
		
		1:  # inaccurate
			inaccurate_hits += 1
			score += 150
		
		2:  # accurate
			accurate_hits += 1
			score += 300
	
	if score_type > 0:
		current_combo += 1
	
	#hit_error_bar.add_point(hit_time_difference)
	update_judgement(score_type)
	update_visuals()

func add_finisher_score(hit_time_difference: float) -> void:
	var accurate := false
	if abs(hit_time_difference) <= Global.ACC_TIMING:
		accurate = true

	score += 300 if accurate else 150
	update_visuals()

func reset() -> void:
	score = 0
	accurate_hits = 0
	inaccurate_hits = 0
	miss_count = 0
	early_hits = 0
	late_hits = 0
	top_combo = 0
	current_combo = 0

func update_judgement(type: int):
	var target_judgement = judgement_indicators.get_child(2 - type)
	
	if judgement_indicator_tweens[type]:
		judgement_indicator_tweens[type].kill()
	
	judgement_indicator_tweens[type] = create_tween()
	judgement_indicator_tweens[type].tween_property(target_judgement, "modulate:a", 0.0, 0.4).from(1.0)

func get_packaged_score() -> Dictionary:
	var score_dict := {}
	score_dict["Score"] = score
	score_dict["TopCombo"] = top_combo
	
	score_dict["AccurateHits"] = accurate_hits
	score_dict["InaccurateHits"] = inaccurate_hits
	score_dict["MissCount"] = miss_count
	
	return score_dict
