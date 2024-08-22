class_name ScoreData

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

# -------- score management --------

# add score data (hits, misses)
func add_score(hit_result: HitObject.HIT_RESULT, hit_time_difference = null) -> void:
	match hit_result:
		HitObject.HIT_RESULT.MISS:
			if current_combo > 10:
				combo_break.emit()
			
			current_combo = 0
			miss_count += 1
		
		HitObject.HIT_RESULT.INACC, HitObject.HIT_RESULT.F_INACC:  # inaccurate
			inaccurate_hits += 1
			score += 150
		
		HitObject.HIT_RESULT.ACC, HitObject.HIT_RESULT.F_ACC:  # accurate
			accurate_hits += 1
			score += 300
		
		HitObject.HIT_RESULT.TICK_HIT:
			score += 10
		
	if hit_result >= HitObject.HIT_RESULT.INACC and hit_result < HitObject.HIT_RESULT.TICK_HIT:
		# combo handling
		current_combo += 1
		if current_combo > top_combo:
			top_combo = current_combo
		
		# if inaccurate and hit time diff included, count late/early
		if typeof(hit_time_difference) == TYPE_FLOAT and (hit_result == HitObject.HIT_RESULT.INACC or hit_result == HitObject.HIT_RESULT.F_INACC):
			if hit_time_difference < 0: # early
				early_hits += 1
				return
			late_hits += 1

# add second hit to a finisher's score
func add_finisher_score(hit_time_difference: float) -> void:
	var accurate := false
	if abs(hit_time_difference) <= Global.ACC_TIMING:
		accurate = true
		f_accurate_hits += 1
	else:
		f_inaccurate_hits += 1

	score += 300 if accurate else 150

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
