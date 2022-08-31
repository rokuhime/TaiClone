extends Node

onready var root_viewport := $"/root" as Root


func _ready() -> void:
	root_viewport.bg_changed(root_viewport.menu_bg)
