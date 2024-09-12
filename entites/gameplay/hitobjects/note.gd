class_name Note
extends HitObject

var is_kat := false
var last_side_hit := Gameplay.SIDE.NONE

var don_colour := Color("EB452B")
var kat_colour := Color("438EAD")

func _ready() -> void:
	update_visual()

# applies any skin stuff
func update_visual() -> void:
	self_modulate = kat_colour if is_kat else don_colour
	scale = Vector2.ONE * FINISHER_SCALE if is_finisher else Vector2.ONE

func hit_check(current_time: float, input_side: Gameplay.SIDE, is_input_kat: bool) -> HIT_RESULT:
	var result := HIT_RESULT.INVALID
	
	# if active and within early miss window
	if active and current_time >= timing - Global.MISS_TIMING and current_time <= timing - Global.INACC_TIMING:
		result = HIT_RESULT.MISS
	
	if active and abs(timing - current_time) <= Global.INACC_TIMING:
		# default to being hit, 
		result = HIT_RESULT.ACC if abs(timing - current_time) <= Global.ACC_TIMING else HIT_RESULT.INACC
		
		# wrong input type miss
		if is_kat != is_input_kat:
			result = HIT_RESULT.MISS
		
		# new finisher hit
		elif is_finisher:
			last_side_hit = input_side as Gameplay.SIDE
			@warning_ignore("int_as_enum_without_cast")
			result += 2 # change to finisher hit
	
	if result != HIT_RESULT.INVALID:
		visible = false
		active = false
	return result

func miss_check(current_time: float) -> bool:
	if active and timing + Global.INACC_TIMING < current_time:
		active = false
		return true
	return false
	
func apply_skin(skin: SkinManager) -> void:
	don_colour = skin.resources["colour"]["don"]
	kat_colour = skin.resources["colour"]["kat"]
	# textures go here!
	if skin.resource_exists("texture/note"):
		texture = skin.resources["texture"]["note"]
	if skin.resource_exists("texture/note_overlay"):
		$Overlay.texture = skin.resources["texture"]["note_overlay"]
	update_visual()
