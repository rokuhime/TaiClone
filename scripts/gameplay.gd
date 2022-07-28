class_name Gameplay
extends Node

var skin := SkinManager.new()

onready var _judgements := $"BarRight/HitPointOffset/Judgements" as Node

onready var accurate_obj := _judgements.get_node("JudgeAccurate") as CanvasItem
onready var inaccurate_obj := _judgements.get_node("JudgeInaccurate") as CanvasItem
onready var miss_obj := _judgements.get_node("JudgeMiss") as CanvasItem

onready var _bar_left := $"BarLeft"

onready var _drum_visual := _bar_left.get_node("DrumVisual")

onready var l_don_obj := _drum_visual.get_node("LeftDon") as CanvasItem
onready var l_kat_obj := _drum_visual.get_node("LeftKat") as CanvasItem
onready var r_don_obj := _drum_visual.get_node("RightDon") as CanvasItem
onready var r_kat_obj := _drum_visual.get_node("RightKat") as CanvasItem

onready var _timing_indicator := _bar_left.get_node("TimingIndicator") as CanvasItem

onready var _hit_error := $"UI/HitError" as HitError

onready var hit_manager := $"HitManager" as HitManager
onready var music := $"Music" as AudioStreamPlayer


func hit_error_toggled(new_visible: bool) -> void:
	_hit_error.visible = new_visible


func late_early_changed(new_value: int) -> void:
	_hit_error.lateearlySimpleDisplay = new_value < 2
	_timing_indicator.visible = new_value > 0
