extends Control

@onready var pointer := $Pointer
@onready var index_label := $Pointer/Index
@onready var top := $Top
@onready var bottom := $Bottom

var visibility_tween: Tween
var index_movement_tween: Tween
const GAP_SIZE := 5

func _ready() -> void:
	modulate.a = 0.5

func update_visual(current_index: int, total_count: int) -> void:
	# ensure top/bottom correct
	top.position = Vector2(-(top.size.x + GAP_SIZE), 0)
	bottom.position = Vector2(-(bottom.size.x + GAP_SIZE), size.y - bottom.size.y)
	
	# pointer
	index_label.position.x = (index_label.size.x + GAP_SIZE) * -1
	
	# index text
	index_label.text = "%s/%s" % [current_index + 1, total_count]
	
	# pointer pos
	var pointer_bounds := Vector2(top.size.y + GAP_SIZE, # top position
		size.y - (bottom.size.y + top.size.y + GAP_SIZE)) # bottom position
	
	if index_movement_tween:
		index_movement_tween.kill()
	index_movement_tween = Global.create_smooth_tween()
	index_movement_tween.tween_property(pointer, "position:y", 
		remap(current_index, 0, total_count - 1, pointer_bounds.x, pointer_bounds.y), 0.5
	)
	
	# visibility
	if visibility_tween:
		visibility_tween.kill()
	visibility_tween = get_tree().create_tween()
	visibility_tween.tween_property(self, "modulate:a", 0.5, 1).from(1.0)
