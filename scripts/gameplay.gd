class_name Gameplay
extends Node

var skin := SkinManager.new()

onready var _drum_visual := $"BarLeft/DrumVisual" as Node
onready var l_don_obj := _drum_visual.get_node("LeftDon") as CanvasItem
onready var l_kat_obj := _drum_visual.get_node("LeftKat") as CanvasItem
onready var r_don_obj := _drum_visual.get_node("RightDon") as CanvasItem
onready var r_kat_obj := _drum_visual.get_node("RightKat") as CanvasItem

onready var _judgements := $"BarRight/HitPointOffset/Judgements" as Node
onready var accurate_obj := _judgements.get_node("JudgeAccurate") as CanvasItem
onready var inaccurate_obj := _judgements.get_node("JudgeInaccurate") as CanvasItem
onready var miss_obj := _judgements.get_node("JudgeMiss") as CanvasItem

onready var hit_manager := $"HitManager" as HitManager
onready var music := $"Music" as AudioStreamPlayer
