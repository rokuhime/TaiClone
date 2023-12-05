class_name Roll
extends HitObject

var length: float
@onready var middle_node := $Middle as Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self_modulate = Color("FCB806")
	middle_node.modulate = Color("FCB806") # will make end node coloured too
	
	var body_length : float = length * speed * Global.resolution_multiplier
	
	if is_finisher:
		scale = Vector2.ONE * FINISHER_SCALE
		body_length /= FINISHER_SCALE
	
	middle_node.size.x = body_length
