#TODO: separate this up, this is getting pretty bloated
class_name ScoreInstance

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

signal combo_break
signal score_updated

func _init() -> void:
	pass

# -------- score management --------

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
				combo_break.emit()
			
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
		
		# if inaccurate, count late/early
		if score_type == 1:
			if hit_time_difference > 0:
				late_hits += 1
			else:
				early_hits += 1

# add second hit to a finisher's score
func add_finisher_score(hit_time_difference: float) -> void:
	var accurate := false
	if abs(hit_time_difference) <= Global.ACC_TIMING:
		accurate = true
		f_accurate_hits += 1
	else:
		f_inaccurate_hits += 1

	score += 300 if accurate else 150
	score_updated.emit()

# TODO: turn from int into enum, too lazy rn
func add_manual_score(score_type: int):
	match score_type:
		0:  # miss
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
	
	score_updated.emit()
	#update_judgement(score_type)
	#update_visuals()

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
