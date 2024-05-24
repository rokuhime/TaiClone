class_name Note
extends HitObject

var is_kat := false
var last_side_hit := Gameplay.SIDE.NONE

func _ready() -> void:
	self_modulate = Color("438EAD") if is_kat else Color("EB452B")
	
	if is_finisher:
		scale = Vector2.ONE * FINISHER_SCALE

func hit_check(current_time: float, input_side: Gameplay.SIDE, is_input_kat: bool) -> HIT_RESULT:
	var result := HIT_RESULT.INVALID
	
	# if hittable
	if active and abs(timing - current_time) <= Global.INACC_TIMING:
		# default to being hit, 
		result = HIT_RESULT.HIT
		active = false
		
		# wrong input type miss
		if is_kat != is_input_kat:
			result = HIT_RESULT.MISS
		
		# new finisher hit
		elif is_finisher:
			last_side_hit = input_side as Gameplay.SIDE
			result = HIT_RESULT.HIT_FINISHER
	
	return result

func miss_check(current_time: float) -> bool:
	if active and timing + Global.INACC_TIMING < current_time:
		active = false
		return true
	return false
