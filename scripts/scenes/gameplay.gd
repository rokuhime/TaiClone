class_name Gameplay
extends Node

var acc_timing := 0.06
var inacc_timing := 0.145
var miss_timing := 0.2

var skin := SkinManager.new()

onready var _hit_point_offset := $"BarRight/HitPointOffset"

onready var _object_container := _hit_point_offset.get_node("ObjectContainers") as Control

onready var _judgements := _hit_point_offset.get_node("Judgements")

onready var accurate_obj := _judgements.get_node("JudgeAccurate") as CanvasItem
onready var inaccurate_obj := _judgements.get_node("JudgeInaccurate") as CanvasItem
onready var miss_obj := _judgements.get_node("JudgeMiss") as CanvasItem

onready var _drum_visual := $"BarLeft/DrumVisual"

onready var l_don_obj := _drum_visual.get_node("LeftDon") as CanvasItem
onready var l_kat_obj := _drum_visual.get_node("LeftKat") as CanvasItem
onready var r_don_obj := _drum_visual.get_node("RightDon") as CanvasItem
onready var r_kat_obj := _drum_visual.get_node("RightKat") as CanvasItem

onready var settings := $"debug/SettingsPanel" as SettingsPanel

onready var hit_manager := $"HitManager" as HitManager
onready var music := $"Music" as AudioStreamPlayer


func offset_changed() -> void:
	# this is fundamentally flawed due to everything being scaled by 1.9
	# it's a close approximation but should be fixed once scaling is removed
	_object_container.rect_position = Vector2(settings.global_offset * -775, 0)
