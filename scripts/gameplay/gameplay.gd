class_name Gameplay
extends Node

## Comment
signal load_chart(file_path)

## Comment
enum NoteType {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

## Comment
var _auto := false

## Comment
var _timing_indicator_tween := SceneTreeTween.new()

onready var bar_left := $BarLeft as BarLeft
onready var debug_text := $Debug/DebugText as Label
onready var fpstext := $Debug/TempLoadChart/Text/FPS as Label
onready var hit_error := $HitError
onready var line_edit := $Debug/TempLoadChart/LineEdit as LineEdit
onready var music := $BarLeft/Music as AudioStreamPlayer
onready var obj_container := $BarLeft/ObjectContainer as Control
onready var taiclone := $"/root" as Root
onready var timing_indicator := $BarLeft/TimingIndicator as Label
onready var ui_accuracy := $UI/Accuracy/Label as Label
onready var ui_score := $UI/Score as Label


func _ready() -> void:
	Root.send_signal(hit_error, "hit_error_toggled", taiclone, "hit_error_toggled")
	Root.send_signal(self, "late_early_changed", taiclone, "late_early_changed")
	Root.send_signal(self, "offset_changed", taiclone, "offset_changed")
	late_early_changed()
	offset_changed()
	bar_left._reset()
	if bar_left._f.file_exists(bar_left._fus):
		load_func(bar_left._fus)


func _process(_delta: float) -> void:
	fpstext.text = "FPS: %s" % Engine.get_frames_per_second()


## Comment
func add_score(score: int, accuracy: float) -> void:
	ui_score.text = "%010d" % score
	ui_accuracy.text = "%2.2f" % accuracy


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

	_timing_indicator_tween = taiclone.new_tween(_timing_indicator_tween).set_trans(Tween.TRANS_QUART)

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
	bar_left._reset(music.playing)
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
