class_name Note
extends HitObject

var is_kat := false
enum SIDE {NONE, LEFT, RIGHT}
var last_side_hit := SIDE.NONE

func _ready() -> void:
	self_modulate = Color("438EAD") if is_kat else Color("EB452B")
	
	if is_finisher:
		scale = Vector2.ONE * FINISHER_SCALE

func hit_check(current_time: float, input_side: SIDE, is_input_kat: bool) -> HIT_RESULT:
	# if not hittable yet
	if abs(timing - current_time) > Global.INACC_TIMING:
		return HIT_RESULT.INVALID
	
	# wrong input type miss
	elif is_kat != is_input_kat:
		#apply_score(target_note.timing - current_time, target_note, true)
		return HIT_RESULT.MISS
	
	# new finisher hit
	if is_finisher:
		last_side_hit = input_side as SIDE
		return HIT_RESULT.HIT_FINISHER
	
	return HIT_RESULT.HIT
