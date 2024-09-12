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
var judgement_indicator_tweens: Array = [null, null, null, null, null]
@onready var inaccurate_indicator: Label = $InaccurateIndicator
var inaccurate_indicator_tween: Tween

@onready var hit_error_bar: HitErrorBar = $HitErrorBar

@onready var mascot: Mascot = $Mascot

var song_progress_back := Color("333333")
var song_progress_front := Color("ffffff")
var song_progress_skippable := Color("8bff85")
var late_colour := Color("ff8a8a")
var early_colour := Color("8aa7ff")

var toast_values := [50,100,150,200,250,500,1000]

# -------- visual updates --------

func update_mascot(animation: Mascot.SPRITETYPES) -> void:
	match animation:
		Mascot.SPRITETYPES.FAIL:
			mascot.start_animation(mascot.SPRITETYPES.FAIL)
		
		Mascot.SPRITETYPES.IDLE:
			mascot.start_animation(mascot.SPRITETYPES.IDLE)
		
		Mascot.SPRITETYPES.KIAI:
			mascot.start_animation(mascot.SPRITETYPES.KIAI)

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
	if hit_result >= HitObject.HIT_RESULT.TICK_HIT or hit_result == HitObject.HIT_RESULT.INVALID:
		return

	var target_judgement = judgement_indicators.get_child(hit_result)
	
	if judgement_indicator_tweens[hit_result]:
		judgement_indicator_tweens[hit_result].kill()
	
	judgement_indicator_tweens[hit_result] = create_tween()
	judgement_indicator_tweens[hit_result].tween_property(target_judgement, "modulate:a", 0.0, 0.4).from(1.0)

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

func on_score_update(score: ScoreData, target_hit_obj: HitObject, hit_result: HitObject.HIT_RESULT, current_time = null) -> void:
	if typeof(current_time) == TYPE_FLOAT:
		hit_error_bar.add_point(target_hit_obj.timing - current_time)
	update_judgement(hit_result)
	update_visuals(score)
	
	# mascot handling
	if hit_result == HitObject.HIT_RESULT.MISS:
		if mascot.current_state != mascot.SPRITETYPES.FAIL:
			update_mascot(Mascot.SPRITETYPES.FAIL)
		return
	
	elif typeof(current_time) == TYPE_FLOAT and (hit_result == HitObject.HIT_RESULT.INACC or hit_result == HitObject.HIT_RESULT.F_INACC):
		update_inacc_indicator(target_hit_obj.timing - current_time)
	
	if Global.get_root().timing_clock.in_kiai:
		if mascot.current_state != mascot.SPRITETYPES.KIAI:
			update_mascot(Mascot.SPRITETYPES.KIAI)
	else:
		if mascot.current_state != mascot.SPRITETYPES.IDLE:
			update_mascot(Mascot.SPRITETYPES.IDLE)
	
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
	
	var judge_texture_names := ["judgement_miss", "judgement_inaccurate", "judgement_accurate", "judgement_inaccurate_f",  "judgement_accurate_f"]
	for i in judge_texture_names.size():
		if skin.resource_exists("texture/" + judge_texture_names[i]):
			judgements[i].texture = skin.resources["texture"][judge_texture_names[i]]
		# if the finisher judgement texture isnt found but the normal judgement is found, set it to that
		elif i >= HitObject.HIT_RESULT.F_INACC and skin.resource_exists("texture/" + judge_texture_names[i - 2]):
			judgements[i].texture = skin.resources["texture"][judge_texture_names[i - 2]]
	
	mascot.apply_skin(skin)
	
	if skin.resource_exists("audio/combo_break"):
		combo_break_player.stream = skin.resources["audio"]["combo_break"]
