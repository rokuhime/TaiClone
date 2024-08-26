class_name GameOverlay
extends Control

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

@onready var mascot: TextureRect = $Mascot

var song_progress_back := Color("333333")
var song_progress_front := Color("ffffff")
var song_progress_skippable := Color("8bff85")
var late_colour := Color("ff8a8a")
var early_colour := Color("8aa7ff")

var toast_values := [50,100,150,200,250,500,1000]
var in_kiai := false

# -------- visual updates --------

func update_mascot(animation: Mascot.SPRITETYPES, new_bps: float, update_time := 0.0) -> void:
	match animation:
		Mascot.SPRITETYPES.FAIL:
			mascot.start_animation(mascot.SPRITETYPES.FAIL, new_bps)
		
		Mascot.SPRITETYPES.IDLE:
			mascot.start_animation(mascot.SPRITETYPES.IDLE, 
				new_bps, 
				update_time)
		
		Mascot.SPRITETYPES.KIAI:
			mascot.start_animation(mascot.SPRITETYPES.KIAI, 
				new_bps, 
				update_time)

# updates progress bar, done every _process() call under gameplay
func update_progress(cur_time: float, first_hobj_time: float, last_hobj_time: float) -> void:
	# before 1st note
	if cur_time < first_hobj_time:
		# tint to show remaining time before starting
		if song_progress_bar.tint_under != song_progress_skippable:
			song_progress_bar.tint_under = song_progress_skippable
			song_progress_bar.tint_progress = song_progress_back
		
		song_progress_bar.value = cur_time / first_hobj_time
		return
	
	# change color incase not changed
	if song_progress_bar.tint_under != song_progress_back:
		song_progress_bar.tint_under = song_progress_back
		song_progress_bar.tint_progress = song_progress_front
	
	song_progress_bar.value = (cur_time - first_hobj_time) / (last_hobj_time - first_hobj_time)

# updates labels for counts of things
func update_visuals(score: ScoreData) -> void:
	score_label.text = "%07d" % score.score
	combo_label.text = str(score.current_combo)
	
	var accuracy := Global.get_accuracy(score.accurate_hits, score.inaccurate_hits, score.miss_count)
	
	# tint accuracy golden for ss
	if accuracy != 100 and accuracy_label.self_modulate != Color.WHITE:
		accuracy_label.self_modulate = Color.WHITE
	elif accuracy == 100 and accuracy_label.self_modulate == Color.WHITE:
		accuracy_label.self_modulate = Color("fff096")
	
	accuracy_label.text = "%2.2f%%" % accuracy
	
	raw_info.text = "accurate: " + str(score.accurate_hits) + "\ninaccurate: " + str(score.inaccurate_hits) + "\nmiss: " + str(score.miss_count) + "\ntop combo: " + str(score.top_combo)

# updates hit point judgement visual (acc, inacc, miss)
func update_judgement(hit_result: HitObject.HIT_RESULT) -> void:
	if hit_result >= HitObject.HIT_RESULT.TICK_HIT:
		return
	
	var score_type := 0
	if hit_result == HitObject.HIT_RESULT.INACC or hit_result == HitObject.HIT_RESULT.F_INACC:
		score_type = 1
	if hit_result == HitObject.HIT_RESULT.ACC or hit_result == HitObject.HIT_RESULT.F_ACC:
		score_type = 2

	var target_judgement = judgement_indicators.get_child(2 - score_type)
	
	if judgement_indicator_tweens[score_type]:
		judgement_indicator_tweens[score_type].kill()
	
	judgement_indicator_tweens[score_type] = create_tween()
	judgement_indicator_tweens[score_type].tween_property(target_judgement, "modulate:a", 0.0, 0.4).from(1.0)

# shows little late/early visual for inaccurate hits
func update_inacc_indicator(hit_time_difference: float) -> void:
	inaccurate_indicator.text = "EARLY" if hit_time_difference > 0 else "LATE"
	inaccurate_indicator.modulate = early_colour if hit_time_difference > 0 else late_colour
	
	if inaccurate_indicator_tween:
		inaccurate_indicator_tween.kill()
	
	inaccurate_indicator_tween = Global.create_smooth_tween(inaccurate_indicator, "modulate:a", 0.0, 0.5, 1.0)

# -------- on event --------

func on_combo_break() -> void:
	combo_break_player.play()

func on_score_update(score: ScoreData, target_hit_obj: HitObject, hit_result: HitObject.HIT_RESULT, hit_time_difference = null) -> void:
	if typeof(hit_time_difference) == TYPE_FLOAT:
		hit_error_bar.add_point(hit_time_difference)
	update_judgement(hit_result)
	update_visuals(score)
	
	# mascot handling
	if hit_result == HitObject.HIT_RESULT.MISS:
		if mascot.current_state != mascot.SPRITETYPES.FAIL:
			update_mascot(Mascot.SPRITETYPES.FAIL, get_parent().current_bps)
		return
	
	elif typeof(hit_time_difference) == TYPE_FLOAT and (hit_result == HitObject.HIT_RESULT.INACC or hit_result == HitObject.HIT_RESULT.F_INACC):
		update_inacc_indicator(hit_time_difference)
	
	if get_parent().in_kiai:
		if mascot.current_state != mascot.SPRITETYPES.KIAI:
			update_mascot(Mascot.SPRITETYPES.KIAI, get_parent().current_bps, target_hit_obj.timing)
	else:
		if mascot.current_state != mascot.SPRITETYPES.IDLE:
			update_mascot(Mascot.SPRITETYPES.IDLE, get_parent().current_bps, target_hit_obj.timing)
	
	if toast_values.has(score.current_combo):
		mascot.toast()

# -------- etc --------

func apply_skin(skin: SkinManager) -> void:
	song_progress_back = skin.resources["colour"]["song_progress_back"]
	song_progress_front = skin.resources["colour"]["song_progress_front"]
	song_progress_skippable = skin.resources["colour"]["song_progress_skippable"]
	late_colour = skin.resources["colour"]["late"]
	early_colour = skin.resources["colour"]["early"]
	
	var judgements := judgement_indicators.get_children()
	
	var judge_texture_names := ["judgement_accurate", "judgement_inaccurate", "judgement_miss"]
	for i in judge_texture_names.size():
		if skin.resources["texture"].keys().has(judge_texture_names[i]):
			judgements[i].texture = skin.resources["texture"][judge_texture_names[i]]
	
	mascot.apply_skin(skin)
	
	if skin.resources["audio"].keys().has("combo_break"):
		combo_break_player.stream = skin.resources["audio"]["combo_break"]
