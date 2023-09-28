class_name Roll
extends HitObject

@export var finisher := false

@export var length := 0.0
var ticks := []
var cur_tick := 0

func change_properties(new_timing : float, new_speed : float, new_length : float, new_finisher := false, beat_length := 0.0) -> void:
	time = new_timing
	speed = new_speed
	length = new_length
	finisher = new_finisher
	
	# this is so cringe. move on and come back later
	# tends to be too big as is
	$Middle.size.x = length * speed
	
	$Sprite.self_modulate = SkinManager.colour_roll
	$Middle.self_modulate = SkinManager.colour_roll
	$Middle/End.self_modulate = SkinManager.colour_roll
	
	var tick_count = floor((length / beat_length) * 4) + 1 if beat_length > 0 else 1

func hit(inputs, cur_time : float) -> int:
	# ensure its in hit window
	if cur_time < time + length + Global.INACC_TIMING:
		# cycle through given inputs
		for key in inputs:
			# make sure its the needed input for hitting
			var target_tick_idx
			for tick in ticks:
				if ticks.find(tick) < cur_tick:
					continue
				if tick.timing < cur_time:
					target_tick_idx = ticks.find(tick)
			cur_tick = target_tick_idx
			
			ticks.pop_at(cur_tick).queue_free()
			return 1 # inaccurate hit
	return 0 # miss

func miss() -> void:
	# change colour to translucent and set state
	modulate = Color(Color.WHITE, 0.4)
	state = -1
