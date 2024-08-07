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

@onready var mascot := $Mascot as TextureRect

var song_progress_back := Color("333333")
var song_progress_front := Color("ffffff")
var song_progress_skippable := Color("8bff85")
var late_colour := Color("ff8a8a")
var early_colour := Color("8aa7ff")

var toast_values := [50,100,150,200,250,500,1000]
var in_kiai := false

func on_combo_break() -> void:
	combo_break_player.play()

func on_score_update(score: ScoreInstance, target_hit_obj: HitObject, hit_result: HitObject.HIT_RESULT, current_time: float) -> void:
	var score_type := 0
	var hit_time_difference = target_hit_obj.timing - current_time
	if abs(hit_time_difference) <= Global.INACC_TIMING and hit_result != HitObject.HIT_RESULT.MISS:
		if abs(hit_time_difference) <= Global.ACC_TIMING:
			score_type += 1
		score_type += 1
	
	hit_error_bar.add_point(hit_time_difference)
	update_judgement(score_type)
	update_visuals(score)
	
	match score_type:
		0: # miss
			update_mascot(Mascot.SPRITETYPES.FAIL, get_parent().current_bps)
			return
		1:
			update_inacc_indicator(hit_time_difference)
	if get_parent().in_kiai:
		update_mascot(Mascot.SPRITETYPES.KIAI, get_parent().current_bps, target_hit_obj.timing)
	else:
		update_mascot(Mascot.SPRITETYPES.IDLE, get_parent().current_bps, target_hit_obj.timing)
	
	if toast_values.has(score.current_combo):
		mascot.toast()

func update_mascot(animation: Mascot.SPRITETYPES, new_bps: float, update_time := 0.0) -> void:
	match animation:
		Mascot.SPRITETYPES.FAIL:
			if mascot.current_state != mascot.SPRITETYPES.FAIL:
				mascot.start_animation(mascot.SPRITETYPES.FAIL, new_bps)
		
		Mascot.SPRITETYPES.IDLE:
			if mascot.current_state != mascot.SPRITETYPES.IDLE:
				mascot.start_animation(mascot.SPRITETYPES.IDLE, 
					new_bps, 
					update_time)
		Mascot.SPRITETYPES.KIAI:
			if mascot.current_state != mascot.SPRITETYPES.KIAI:
				mascot.start_animation(mascot.SPRITETYPES.KIAI, 
					new_bps, 
					update_time)

# updates progress bar, done every _process() call under gameplay
func update_progress(cur_time: float, first_hobj_time: float, last_hobj_time: float):
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
func update_visuals(score: ScoreInstance) -> void:
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
func update_judgement(type: int):
	var target_judgement = judgement_indicators.get_child(2 - type)
	
	if judgement_indicator_tweens[type]:
		judgement_indicator_tweens[type].kill()
	
	judgement_indicator_tweens[type] = create_tween()
	judgement_indicator_tweens[type].tween_property(target_judgement, "modulate:a", 0.0, 0.4).from(1.0)

# shows little late/early visual for inaccurate hits
func update_inacc_indicator(hit_time_difference: float) -> void:
	inaccurate_indicator.text = "EARLY" if hit_time_difference > 0 else "LATE"
	inaccurate_indicator.modulate = early_colour if hit_time_difference > 0 else late_colour
	
	if inaccurate_indicator_tween:
		inaccurate_indicator_tween.kill()
	inaccurate_indicator_tween = Global.create_smooth_tween()
	inaccurate_indicator_tween.tween_property(inaccurate_indicator, "modulate:a", 0.0, 0.5).from(1.0)

func apply_skin(skin: SkinManager) -> void:
	song_progress_back = skin.song_progress_back
	song_progress_front = skin.song_progress_front
	song_progress_skippable = skin.song_progress_skippable
	late_colour = skin.late_colour
	early_colour = skin.early_colour