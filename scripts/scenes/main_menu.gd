extends Node

onready var taiclone := $"/root" as Root


func _ready() -> void:
	taiclone.bg_changed(preload("res://temporary/menubg.png"))
