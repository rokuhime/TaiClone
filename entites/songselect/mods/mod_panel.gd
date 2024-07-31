class_name ModPanel
extends Panel

enum MOD_TYPES { AUTO }
@onready var mod_container := $VBoxContainer/ModContainer as GridContainer

static var mod_icon_scene = preload("res://entites/songselect/mods/mod_icon.tscn")
var visual_tween: Tween
var enabled := false

func _ready() -> void:
	toggle_visual(false)
	create_mod_icons()

func _process(delta) -> void:
	if modulate.a == 0 and visible:
		visible = false
	elif modulate.a > 0 and !visible:
		visible = true

func create_mod_icons() -> void:
	for mod in MOD_TYPES:
		var new_mod_icon := mod_icon_scene.instantiate() as ModIcon
		mod_container.add_child(new_mod_icon)
		new_mod_icon.mod_id = mod
		new_mod_icon.update_visual()

func get_selected_mods() -> Array:
	var selected_mods := []
	# go through mod icons, if theyre enabled append their id
	for mod_icon in mod_container.get_children():
		if mod_icon.enabled:
			selected_mods.append(mod_icon.mod_id)
	return selected_mods

func toggle_visual(new_enabled = null) -> void:
	if new_enabled != null:
		enabled = new_enabled
	else:
		enabled = !enabled
	
	if visual_tween:
		visual_tween.kill()
	visual_tween = Global.create_smooth_tween()
	visual_tween.tween_property(self, "modulate:a", 1.0 if enabled else 0.0, 0.5)
