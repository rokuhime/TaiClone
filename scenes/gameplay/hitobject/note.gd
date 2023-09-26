class_name Note
extends HitObject

@export var finisher := false

@export var is_kat := false

func change_properties(new_timing : float, new_speed : float, new_kat : bool, new_finisher := false) -> void:
	time = new_timing
	speed = new_speed
	is_kat = new_kat
	finisher = new_finisher
	$Sprite.self_modulate = SkinManager.colour_kat if is_kat else SkinManager.colour_don

func hit(inputs, cur_time : float) -> int:
	# ensure its in hit window
	if cur_time < time + Global.INACC_TIMING and cur_time > time - Global.INACC_TIMING:
		# cycle through given inputs
		for key in inputs:
			# make sure its the needed input for hitting
			if key.contains("Don") and is_kat:
				continue
			elif key.contains("Kat") and !is_kat:
				continue
			
			# object has been hit, hide to minimize lag and set state
			hide()
			state = -1
		
			if cur_time < time + Global.ACC_TIMING and cur_time > time - Global.ACC_TIMING:
				return 2 # accurate hit
			return 1 # inaccurate hit
	return 0 # miss

func miss() -> void:
	# change colour to translucent and set state
	modulate = Color(Color.WHITE, 0.4)
	state = -1
