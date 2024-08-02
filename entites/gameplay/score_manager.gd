#TODO: separate this up, this is getting pretty bloated
class_name ScoreManager
extends Control

var score := 0
var accurate_hits := 0
var f_accurate_hits := 0
var inaccurate_hits := 0
var f_inaccurate_hits := 0
var miss_count := 0

var early_hits := 0
var late_hits := 0

var top_combo := 0
var current_combo := 0

@onready var raw_info : Label = $RawInfo

@onready var score_label: Label = $Score
@onready var accuracy_label: Label = $Accuracy
@onready var combo_label: Label = $Combo

@onready var song_progress_bar: TextureProgressBar = $SongProgressMeter
@onready var health_bar: TextureProgressBar = $Health
@onready var combo_break_player: AudioStreamPlayer = $ComboBreak

@onready var judgement_indicators: Node = $Judgements
var judgement_indicator_tweens: Array = [null, null, null]
@onready var inaccurate_indicator: Label = $InaccurateIndicator
var inaccurate_indicator_tween: Tween

@onready var hit_error_bar: HitErrorBar = $HitErrorBar

signal toast()
var toast_values := [50,100,150,200,250,500,1000]

# temp, move to skin manager
var progress_dark := Color("333333")
var progress_light := Color("ffffff")
var progress_pre := Color("8bff85")

# TODO: move this out and make a ui manager
func update_progress(cur_time: float, first_hobj_time: float, last_hobj_time: float):
	# before 1st note
	if cur_time < first_hobj_time:
		# tint to show remaining time before starting
		if song_progress_bar.tint_under != progress_pre:
			song_progress_bar.tint_under = progress_pre
			song_progress_bar.tint_progress = progress_dark
		
		song_progress_bar.value = cur_time / first_hobj_time
		return
	
	# change color incase not changed
	if song_progress_bar.tint_under != progress_dark:
		song_progress_bar.tint_under = progress_dark
		song_progress_bar.tint_progress = progress_light
	
	song_progress_bar.value = (cur_time - first_hobj_time) / (last_hobj_time - first_hobj_time)

func update_visuals() -> void:
	score_label.text = "%07d" % score
	combo_label.text = str(current_combo)
	
	var accuracy := Global.get_accuracy(accurate_hits, inaccurate_hits, miss_count)
	
	# tint accuracy golden for ss
	if accuracy != 100 and accuracy_label.self_modulate != Color.WHITE:
		accuracy_label.self_modulate = Color.WHITE
	elif accuracy == 100 and accuracy_label.self_modulate == Color.WHITE:
		accuracy_label.self_modulate = Color("fff096")
	
	accuracy_label.text = "%2.2f%%" % accuracy
	
	raw_info.text = "accurate: " + str(accurate_hits) + "\ninaccurate: " + str(inaccurate_hits) + "\nmiss: " + str(miss_count) + "\ntop combo: " + str(top_combo)

# add score data (hits, misses)
func add_score(hit_time_difference: float, hit_result: HitObject.HIT_RESULT) -> void:
	var score_type := 0
	if abs(hit_time_difference) <= Global.INACC_TIMING and hit_result != HitObject.HIT_RESULT.MISS:
		if abs(hit_time_difference) <= Global.ACC_TIMING:
			score_type += 1
		score_type += 1
	
	match score_type:
		0:  # miss
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
		# combo handling
		current_combo += 1
		if current_combo > top_combo:
			top_combo = current_combo
		if toast_values.has(current_combo):
			toast.emit()
		
		# if inaccurate, count late/early
		if score_type == 1:
			if hit_time_difference > 0:
				late_hits += 1
			else:
				early_hits += 1
	
	hit_error_bar.add_point(hit_time_difference)
	if score_type == 1:
		update_inacc_indicator(hit_time_difference)
	update_judgement(score_type)
	update_visuals()

# add second hit to a finisher's score
func add_finisher_score(hit_time_difference: float) -> void:
	var accurate := false
	if abs(hit_time_difference) <= Global.ACC_TIMING:
		accurate = true
		f_accurate_hits += 1
	else:
		f_inaccurate_hits += 1

	score += 300 if accurate else 150
	update_visuals()

# 2024-07-02
# TODO: turn from int into enum, too lazy rn
func add_manual_score(score_type: int):
	match score_type:
		0:  # miss
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
		# combo handling
		current_combo += 1
		if current_combo > top_combo:
			top_combo = current_combo
	
	update_judgement(score_type)
	update_visuals()

# reset score variables
func reset() -> void:
	score = 0
	accurate_hits = 0
	f_accurate_hits = 0
	inaccurate_hits = 0
	f_inaccurate_hits = 0
	miss_count = 0
	early_hits = 0
	late_hits = 0
	top_combo = 0
	current_combo = 0

# updates visual for hits (acc, inacc, miss)
func update_judgement(type: int):
	var target_judgement = judgement_indicators.get_child(2 - type)
	
	if judgement_indicator_tweens[type]:
		judgement_indicator_tweens[type].kill()
	
	judgement_indicator_tweens[type] = create_tween()
	judgement_indicator_tweens[type].tween_property(target_judgement, "modulate:a", 0.0, 0.4).from(1.0)

# condences current score for result screen
func get_packaged_score() -> Dictionary:
	var score_dict := {}
	score_dict["Score"] = score
	score_dict["TopCombo"] = top_combo
	
	score_dict["AccurateHits"] = accurate_hits
	score_dict["FAccurateHits"] = f_accurate_hits
	score_dict["InaccurateHits"] = inaccurate_hits
	score_dict["FInaccurateHits"] = f_inaccurate_hits
	score_dict["MissCount"] = miss_count
	
	score_dict["EarlyHits"] = early_hits
	score_dict["LateHits"] = late_hits
	
	return score_dict

func update_inacc_indicator(hit_time_difference: float) -> void:
	inaccurate_indicator.text = "EARLY" if hit_time_difference > 0 else "LATE"
	inaccurate_indicator.modulate = Color("8aa7ff") if hit_time_difference > 0 else Color("ff8a8a")
	
	if inaccurate_indicator_tween:
		inaccurate_indicator_tween.kill()
	inaccurate_indicator_tween = Global.create_smooth_tween()
	inaccurate_indicator_tween.tween_property(inaccurate_indicator, "modulate:a", 0.0, 0.5).from(1.0)
