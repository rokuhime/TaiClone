class_name CardContainer
extends Container

static var mod_icon_scene = preload("res://entites/songselect/mods/mod_icon.tscn")
@export var selected_idx := 0
var child_count := 0
var distance := 40.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_count = get_child_count()
	update_visual()
	sort_children.connect(on_sort_children)

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if get_child_count() != child_count:
		update_visual()

func update_visual() -> void:
	var disabled_buffer := 0
	for card in get_children():
		if card.enabled == false:
			disabled_buffer += 1
			continue
		if card.position.x == 0.0 and card.get_index() != 0:
			card.position.x = (card.get_index() - disabled_buffer) * distance
		elif card.position.x != (card.get_index() - disabled_buffer) * distance:
			Global.create_smooth_tween(card, "position:x", (card.get_index() - disabled_buffer) * distance, 0.3)

func on_sort_children() -> void:
	var sorted := false
	while not sorted:
		sorted = true
		for i in get_child_count():
			if i != get_child_count() - 1:
				var mod := get_child(i)
				var next_mod := get_child(i + 1) 
				if mod.mod_id > next_mod.mod_id:
					sorted = false
					move_child(mod, i + 1)

# roku note 2024-09-29
# separate these functions up a bit more 
# idea is the ModIcons will do a signal any time theyre selected to change the SelectedMods visual for options n such
func on_mod_toggled(mod_id: int, is_enabled: bool) -> void:
	# make sure a card doesnt exist already for the mod
	var existing_mod: ModIcon
	for mod_card in get_children():
		# if card exists...
		if mod_card.mod_id == mod_id:
			if not is_enabled:
				mod_card.disable_as_card()
				return
			
			# if theres 2 instances of the same card, delete the newer instance
			if existing_mod:
				mod_card.queue_free()
			else:
				existing_mod = mod_card
			continue
	
	# enable/create mod icon
	var mod_icon := existing_mod if existing_mod else mod_icon_scene.instantiate()
	mod_icon.mod_id = mod_id
	add_child(mod_icon)
	mod_icon.enable_as_card()
	return	
