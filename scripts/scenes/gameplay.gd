class_name Gameplay
extends Node

signal load_chart(file_path)

var acc_timing := 0.06
var inacc_timing := 0.145

var skin := SkinManager.new()

onready var accurate_obj := $"BarRight/HitPointOffset/Judgements/JudgeAccurate" as CanvasItem
onready var inaccurate_obj := $"BarRight/HitPointOffset/Judgements/JudgeInaccurate" as CanvasItem
onready var miss_obj := $"BarRight/HitPointOffset/Judgements/JudgeMiss" as CanvasItem

onready var l_don_obj := $"BarLeft/DrumVisual/LeftDon" as CanvasItem
onready var l_kat_obj := $"BarLeft/DrumVisual/LeftKat" as CanvasItem
onready var r_don_obj := $"BarLeft/DrumVisual/RightDon" as CanvasItem
onready var r_kat_obj := $"BarLeft/DrumVisual/RightKat" as CanvasItem

onready var settings := $"debug/SettingsPanel" as SettingsPanel

onready var hit_manager := $"HitManager" as HitManager
onready var music := $"Music" as AudioStreamPlayer

onready var _object_container := $"BarRight/HitPointOffset/ObjectContainers" as Control

onready var _debug_text := $"debug/debugtext" as Label
onready var _file_input := $"debug/temploadchart/LineEdit" as LineEdit
onready var _fps_text := $"debug/fpstext" as Label


func _process(_delta: float) -> void:
	_fps_text.text = "FPS: %s" % Engine.get_frames_per_second()


func load_func() -> void:
	_debug_text.text = "Loading... [Checking File]"
	var file_path := _file_input.text.replace("\\", "/")
	if File.new().file_exists(file_path):
		_debug_text.text = "Loading... [Reading File]"
		emit_signal("load_chart", file_path)
		_debug_text.text = "Done!"
	else:
		_debug_text.text = "Invalid file!"


func offset_changed() -> void:
	# this is fundamentally flawed due to everything being scaled by 1.9
	# it's a close approximation but should be fixed once scaling is removed
	_object_container.rect_position = Vector2(settings.global_offset * -775, 0)
