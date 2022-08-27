class_name Gameplay
extends Node

## Comment
signal load_chart(file_path)

## Comment
signal new_marker(type, timing, skin)

## Comment
enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

## Comment
var _accurate_count := 0

## Comment
var _auto := false

## Comment
var _combo := 0

## Comment
var _cur_time := 0.0

## Comment
var _drum_animation_tweens := [SceneTreeTween.new(), SceneTreeTween.new(), SceneTreeTween.new(), SceneTreeTween.new()]

## Comment
var _f := File.new()

## Comment
var _fus := "user://debug.fus"

## Comment
var _inaccurate_count := 0

## Comment
var _judgement_tween := SceneTreeTween.new()

## Comment
var _miss_count := 0

## Comment
var _score := 0

## Comment
var _score_multiplier := 1.0

## Comment
var _timing_indicator_tween := SceneTreeTween.new()

onready var combo := $BarLeft/DrumVisual/Combo as Label
onready var debug_text := $debug/debugtext as Label
onready var fpstext := $debug/fpstext as Label
onready var hit_error := $UI/HitError
onready var judgement := $BarLeft/Judgement as TextureRect
onready var line_edit := $debug/temploadchart/LineEdit as LineEdit
onready var music := $BarLeft/Music as AudioStreamPlayer
onready var obj_container := $BarLeft/ObjectContainer as Control
onready var taiclone := $"/root" as Root
onready var timing_indicator := $BarLeft/TimingIndicator as Label
onready var ui_accuracy := $UI/Accuracy as Label
onready var ui_score := $UI/Score as Label


func _ready() -> void:
	if taiclone.connect("hit_error_toggled", hit_error, "hit_error_toggled"):
		push_warning("Attempted to connect Root hit_error_toggled.")

	late_early_changed()

	if taiclone.connect("late_early_changed", self, "late_early_changed"):
		push_warning("Attempted to connect Root late_early_changed.")

	offset_changed()

	if taiclone.connect("offset_changed", self, "offset_changed"):
		push_warning("Attempted to connect Root offset_changed.")

	_reset()
	if _f.file_exists(_fus):
		load_func(_fus)


func _input(event: InputEvent) -> void:
	## Comment
	var inputs := []

	if event.is_action_pressed("LeftDon"):
		inputs.append("LeftDon")

	if event.is_action_pressed("LeftKat"):
		inputs.append("LeftKat")

	if event.is_action_pressed("RightDon"):
		inputs.append("RightDon")

	if event.is_action_pressed("RightKat"):
		inputs.append("RightKat")

	if inputs.empty():
		return

	for input_action in inputs:
		(get_node("DrumInteraction/%sAudio" % str(input_action)) as AudioStreamPlayer).play()

		## Comment
		var i := 0 if str(input_action) == "LeftDon" else 1 if str(input_action) == "LeftKat" else 2 if str(input_action) == "RightDon" else 3

		## Comment
		var tween: SceneTreeTween = Root.new_tween(_drum_animation_tweens[i], self).set_ease(Tween.EASE_OUT) # UNSAFE Variant

		## Comment
		var _tween := tween.tween_property(get_node("BarLeft/DrumVisual/" + str(input_action)), "self_modulate:a", 0.0, 0.2).from(1.0)

		_drum_animation_tweens[i] = tween # UNSAFE ArrayItem

	for i in range(obj_container.get_child_count()):
		## Comment
		var note = obj_container.get_child(i)

		if note is BarLine:
			continue

		## Comment
		var new_inputs: Array = note.hit(inputs.duplicate(), _cur_time + (taiclone.inacc_timing if note is Note else 0.0)) # UNSAFE Variant

		if inputs == new_inputs:
			break

		## Comment
		var scores: Array = new_inputs.pop_back() # UNSAFE Variant

		if scores == [HitObject.Score.FINISHED]:
			break

		for score in scores:
			_add_score(score) # UNSAFE Parameter
			if int(score) == int(HitObject.Score.MISS):
				return

		inputs = new_inputs
		if inputs.empty():
			break


func _process(delta: float) -> void:
	fpstext.text = "FPS: %s" % Engine.get_frames_per_second()
	if not music.playing:
		return

	_cur_time += delta
	for i in range(obj_container.get_child_count()):
		## Comment
		var note = obj_container.get_child(i)

		## Comment
		var score: int = note.miss_check(_cur_time - (taiclone.inacc_timing if note is BarLine or note is Note else 0.0)) # UNSAFE Variant

		if note is BarLine or note is SpinnerWarn or note is Tick or score == int(HitObject.Score.FINISHED):
			continue

		if not score:
			break

		_add_score(score)
		if score == int(HitObject.Score.MISS):
			emit_signal("new_marker", score, taiclone.inacc_timing, taiclone.skin)


## Comment
func auto_toggled(new_auto: bool) -> void:
	_auto = new_auto


## Comment
func change_indicator(timing: float) -> void:
	## Comment
	var num := str(int(timing * 1000))

	## Comment
	var late_early_simple_display := taiclone.late_early_simple_display < 2

	if timing > 0:
		timing_indicator.text = "LATE" if late_early_simple_display else "+" + num
		timing_indicator.modulate = taiclone.skin.late_color

	else:
		timing_indicator.text = "EARLY" if late_early_simple_display else num
		timing_indicator.modulate = taiclone.skin.early_color

	_timing_indicator_tween = Root.new_tween(_timing_indicator_tween, self).set_trans(Tween.TRANS_QUART)

	## Comment
	var _tween := _timing_indicator_tween.tween_property(timing_indicator, "self_modulate:a", 0.0, 0.5).from(1.0)


## Comment
func late_early_changed() -> void:
	timing_indicator.visible = taiclone.late_early_simple_display > 0


## Comment
func load_func(file_path := "") -> void:
	if file_path == "":
		file_path = line_edit.text.replace("\\", "/")

	emit_signal("load_chart", file_path)


## Comment
func offset_changed() -> void:
	# TODO: Remove 1.9 scaling
	obj_container.rect_position.x = taiclone.global_offset * -0.775


## Comment
func play_chart() -> void:
	_reset(music.playing)
	if music.playing:
		music.stop()

	else:
		music.play()


## Comment
func text_debug(text: String) -> void:
	debug_text.text = text


## Comment
func toggle_settings() -> void:
	if not taiclone.remove_scene("SettingsPanel"):
		taiclone.add_scene(preload("res://scenes/root/settings_panel.tscn").instance(), name)


## Comment
func _add_score(type) -> void:
	if type is float:
		## Comment
		var timing := float(type) - taiclone.inacc_timing

		type = HitObject.Score.ACCURATE if timing < taiclone.acc_timing else HitObject.Score.INACCURATE if timing < taiclone.inacc_timing else HitObject.Score.MISS
		emit_signal("new_marker", type, timing, taiclone.skin)

	_score += int((150 if int(type) == int(HitObject.Score.INACCURATE) else 300 if [HitObject.Score.ACCURATE, HitObject.Score.FINISHER, HitObject.Score.ROLL].has(int(type)) else 600 if int(type) == int(HitObject.Score.SPINNER) else 0) * _score_multiplier)
	match int(type):
		HitObject.Score.ACCURATE:
			_accurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = taiclone.skin.accurate_judgement

		HitObject.Score.INACCURATE:
			_inaccurate_count += 1
			_combo += 1
			_hit_notify_animation()
			judgement.texture = taiclone.skin.inaccurate_judgement

		HitObject.Score.MISS:
			_miss_count += 1
			_combo = 0
			_hit_notify_animation()
			judgement.texture = taiclone.skin.miss_judgement

	## Comment
	var hit_count := _accurate_count + _inaccurate_count / 2.0

	combo.text = str(_combo)
	ui_score.text = "%010d" % _score
	ui_accuracy.text = "%2.2f" % (0.0 if hit_count == 0 else (hit_count * 100 / (_accurate_count + _inaccurate_count + _miss_count)))


## Comment
func _barline(total_cur_sv: float, time: float, next_barline: float, cur_bpm: float, equal := false) -> float:
	while true:
		## Comment
		var barline := int(next_barline * 1000) / 1000.0

		if barline < time or (equal and barline == time):
			_f.store_csv_line([str(barline), str(total_cur_sv), str(NoteType.BARLINE)])
			next_barline += 240 / cur_bpm

		else:
			break

	return next_barline


## Comment
func _find_value(section: String, key: String, current_chart_data: Dictionary) -> String:
	for line in current_chart_data[section]: # UNSAFE DictionaryItem
		if str(line).begins_with(key):
			return str(line).substr(key.length())

	return ""


## Comment
func _hit_notify_animation() -> void:
	_judgement_tween = Root.new_tween(_judgement_tween, self).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := _judgement_tween.tween_property(judgement, "self_modulate:a", 0.0, 0.4).from(1.0)


## Comment
func _load_finish(new_text: String) -> void:
	_f.close()
	debug_text.text = new_text


## Comment
func _reset(dispose := true) -> void:
	_accurate_count = 0
	_inaccurate_count = 0
	_miss_count = 0
	_combo = 0
	_score = 0
	_score_multiplier = 1
	_add_score(0)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "HitObjects", "queue_free" if dispose else "activate")
	_cur_time = taiclone.global_offset / 1000.0
