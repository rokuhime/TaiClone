extends TextureRect

@export var timing := 0.0
@export var speed := 0.0
@export var finisher := false

@export var is_kat := false
var state := 1

func change_properties(new_timing : float, new_speed : float, new_kat : bool, new_finisher := false) -> void:
	timing = new_timing
	speed = new_speed
	is_kat = new_kat
	finisher = new_finisher
	self_modulate = SkinManager.colour_kat if is_kat else SkinManager.colour_don

func move(cur_time : float) -> void:
	position.x = speed * (timing - cur_time)

func hit(inputs, cur_time : float) -> bool:
	# ensure its in hit window
	if cur_time < timing + Global.INACC_TIMING and cur_time > timing - Global.INACC_TIMING:
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
			return true
	return false

func miss() -> void:
	# change colour to translucent and set state
	modulate = Color(Color.WHITE, 0.4)
	state = -1
