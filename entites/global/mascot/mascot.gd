extends TextureRect

# 0 = idle, 1 = kiai, 2 = clear, 3 = fail
@onready var sprites := [ 
	[load("res://assets/default_skin/pippidonidle0.png"), load("res://assets/default_skin/pippidonidle1.png")], 
	[load("res://assets/default_skin/pippidonkiai0.png"), load("res://assets/default_skin/pippidonkiai1.png")], 
	[load("res://assets/default_skin/pippidonclear0.png"), load("res://assets/default_skin/pippidonclear1.png"), load("res://assets/default_skin/pippidonclear2.png"),
	load("res://assets/default_skin/pippidonclear3.png"), load("res://assets/default_skin/pippidonclear4.png"), load("res://assets/default_skin/pippidonclear5.png"),
	load("res://assets/default_skin/pippidonclear6.png")], 
	[load("res://assets/default_skin/pippidonfail0.png"), load("res://assets/default_skin/pippidonfail1.png")] 
	]
@onready var test_player := $"../AudioStreamPlayer" as AudioStreamPlayer
@onready var test2_player := $"../wawo" as AudioStreamPlayer
enum SPRITETYPES {IDLE, KIAI, CLEAR, FAIL}
var current_state := SPRITETYPES.IDLE

# for animations that dont follow bps (clear)
var default_framerate := 1.5
var bps := 3.0

var anim_start_time := 0.0
var current_frame := 0

# restart the current animation cycle and update sprite to match the given state
func start_animation(state: SPRITETYPES, new_bps := bps):
	# update the anim_start_time to ensure it syncs properly
	anim_start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	# update and reset sprite
	current_state = state
	current_frame = 0
	bps = new_bps
	
	test2_player.play()
	update_frame()

func toast():
	# update the anim_start_time to ensure it syncs properly
	anim_start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	# update and reset sprite
	current_state = SPRITETYPES.CLEAR
	current_frame = 0
	# await toast to end, then go back to appropriate sprite
	await get_tree().create_timer(default_framerate).timeout
	while current_frame != 0:
		await get_tree().process_frame
	print("awawawa!")
	start_animation(SPRITETYPES.IDLE)

func _process(delta):
	var time = (Time.get_ticks_msec() / 1000.0) - Global.global_offset - anim_start_time
	var anim_position := wrapf(time / (bps * 2), 0, 1)
	
	if current_state == SPRITETYPES.CLEAR:
		anim_position = wrapf(time / (default_framerate), 0, 1)
		print("anim_pos = ", anim_position)
	
	var total_frames: int = sprites[int(current_state)].size()
	var new_frame = floor(anim_position * (total_frames))
	
	if new_frame != current_frame:
		current_frame = new_frame
		update_frame()

func update_frame():
	texture = sprites[int(current_state)][current_frame]
	if current_frame == 0:
		test_player.play()
