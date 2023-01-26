class_name HitObjectScenes
extends Node

#var timing_point_object = load("res://scenes/playfield/hitobjects/timing_point.tscn") as PackedScene
var barline_object := preload("res://scenes/playfield/hitobjects/barline.tscn") as PackedScene
var note_object := preload("res://scenes/playfield/hitobjects/note.tscn") as PackedScene
var roll_object := preload("res://scenes/playfield/hitobjects/roll.tscn") as PackedScene
#var tick_object = load("res://scenes/playfield/hitobjects/tick.tscn") as PackedScene
var spinner_warn_object := preload("res://scenes/playfield/hitobjects/spinner_warn.tscn") as PackedScene
var spinner_object := preload("res://scenes/playfield/hitobjects/spinner.tscn") as PackedScene

func _init() -> void:
	#barline_object = load("res://scenes/playfield/hitobjects/barline.tscn") as PackedScene
	#note_object = load("res://scenes/playfield/hitobjects/note.tscn") as PackedScene
	#roll_object = load("res://scenes/playfield/hitobjects/roll.tscn") as PackedScene
	#spinner_warn_object = load("res://scenes/playfield/hitobjects/spinner_warn.tscn") as PackedScene
	#spinner_object = load("res://scenes/playfield/hitobjects/spinner.tscn") as PackedScene
	print("instance: ", spinner_warn_object)
