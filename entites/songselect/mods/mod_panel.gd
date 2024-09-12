class_name ModPanel
extends Panel

enum MOD_TYPES { AUTO, BARLINE_AUDIO}
@onready var mod_container := $VBoxContainer/ModContainer as GridContainer
static var mod_icon_scene = preload("res://entites/songselect/mods/mod_icon.tscn")

var visual_tween: Tween
var enabled := false

func _ready() -> void:
	toggle_visual(false)
	create_mod_icons()

func _process(_delta) -> void:
	# ensure theres no accidental input
	if modulate.a == 0 and visible:
		visible = false
	elif modulate.a > 0 and !visible:
		visible = true

# goes through the MOD_TYPES enum to instance mod icons
func create_mod_icons() -> void:
	# for some reason mod in MOD_TYPES is not giving the actual values, hence mod_idx
	var mod_idx := 0
	for mod in MOD_TYPES:
		var new_mod_icon := mod_icon_scene.instantiate() as ModIcon
		mod_container.add_child(new_mod_icon)
		new_mod_icon.mod_id = mod_idx
		new_mod_icon.update_visual()
		mod_idx += 1

# returns the ids of any selected mods
func get_selected_mods() -> Array:
	var selected_mods := []
	# go through mod icons, if theyre enabled append their id
	for mod_icon in mod_container.get_children():
		if mod_icon.enabled:
			selected_mods.append(mod_icon.mod_id)
	return selected_mods

func toggle_visual(new_enabled = null) -> void:
	# if specified, apply new_enabled. else, toggle
	if new_enabled != null:
		enabled = new_enabled
	else:
		enabled = !enabled
	
	if visual_tween:
		visual_tween.kill()
	visual_tween = Global.create_smooth_tween(
		self,
		"modulate:a", 
		1.0 if enabled else 0.0, 
		0.5
	)
