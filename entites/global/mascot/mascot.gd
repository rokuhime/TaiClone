extends TextureRect

# 0 = idle, 1 = kiai, 2 = clear, 3 = fail
@onready var sprites := [ 
	[load("res://assets/default_skin/pippidonidle0.png"), load("res://assets/default_skin/pippidonidle1.png")], 
	[load("res://assets/default_skin/pippidonkiai0.png"), load("res://assets/default_skin/pippidonkiai1.png")], 
	[], 
	[] 
	]
enum SPRITETYPES {IDLE, KIAI, CLEAR, FAIL}
var current_state := SPRITETYPES.IDLE
@onready var test_player := $"../AudioStreamPlayer" as AudioStreamPlayer
@onready var test2_player := $"../wawo" as AudioStreamPlayer
var default_framerate := 5.0
var bps := 5.0
var anim_start_time := 0.0
var current_frame := 0


func start_animation(state: SPRITETYPES, new_bps := bps):
	anim_start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	current_frame = 0
	current_state = state
	bps = new_bps
	test2_player.play()
	update_frame()

func _process(delta):
	var time = (Time.get_ticks_msec() / 1000.0) - Global.global_offset - anim_start_time
	var measure_position := wrapf(time / (bps * 2), 0, 1)
	print("total_frames = ", measure_position)
	
	var total_frames: int = sprites[int(current_state)].size()
	var new_frame = floor(measure_position * (total_frames))
	
	if new_frame != current_frame:
		current_frame = new_frame
		update_frame()

func update_frame():
	texture = sprites[int(current_state)][current_frame]
	if current_frame == 0:
		test_player.play()
