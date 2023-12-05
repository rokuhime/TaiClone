class_name Note
extends HitObject

var is_kat := false
enum SIDE {NONE, LEFT, RIGHT}
var last_side_hit := SIDE.NONE

func _ready() -> void:
	self_modulate = Color("438EAD") if is_kat else Color("EB452B")
	
	if is_finisher:
		scale = Vector2.ONE * FINISHER_SCALE
