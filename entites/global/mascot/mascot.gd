class_name Mascot
extends TextureRect

# 0 = idle, 1 = kiai, 2 = clear, 3 = fail
@onready var sprites := [ 
	[load("res://assets/default_skin/pippidonidle0.png"), load("res://assets/default_skin/pippidonidle1.png")], 
	[load("res://assets/default_skin/pippidonkiai0.png"), load("res://assets/default_skin/pippidonkiai1.png")], 
	[load("res://assets/default_skin/pippidonfail0.png"), load("res://assets/default_skin/pippidonfail1.png")] 
	]
@onready var toast_sprites := [load("res://assets/default_skin/pippidonclear0.png"), load("res://assets/default_skin/pippidonclear1.png"), load("res://assets/default_skin/pippidonclear2.png"),
	load("res://assets/default_skin/pippidonclear3.png"), load("res://assets/default_skin/pippidonclear4.png"), load("res://assets/default_skin/pippidonclear5.png"),
	load("res://assets/default_skin/pippidonclear6.png")]
	
enum SPRITETYPES {IDLE, KIAI, FAIL}
var current_state: SPRITETYPES

var anim_start_time := 0.0
var current_frame := 0
var bps := 2.0 # beats per second

var toast_framerate := 0.2
var toast_lock := false

# -------- system --------

func _process(delta) -> void:
	# if we are mid toast, ignore texture updates
	if toast_lock:
		return
	
	var time = (Time.get_ticks_msec() / 1000.0) - Global.global_offset - anim_start_time
	var anim_position := wrapf(time / (bps * 2), 0, 1)
	
	var total_frames: int = sprites[int(current_state)].size()
	var new_frame = floor(anim_position * (total_frames))
	
	if new_frame != current_frame:
		current_frame = new_frame
		update_frame()

# -------- animation --------

# restart the current animation cycle and update sprite to match the given state
func start_animation(state: SPRITETYPES, new_bps := bps, delay := 0) -> void:
	# update the anim_start_time to ensure it syncs properly
	anim_start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency() - delay
	# update and reset sprite
	current_state = state
	current_frame = 0
	bps = new_bps
	
	update_frame()

func toast() -> void:
	toast_lock = true
	# await toast to end, then go back to appropriate sprite
	for i in toast_sprites.size():
		texture = toast_sprites[i]
		await get_tree().create_timer(toast_framerate).timeout
	
	toast_lock = false
	update_frame()

# updates texture of TextureRect
func update_frame() -> void:
	texture = sprites[int(current_state)][current_frame]

func apply_skin(skin_manager: SkinManager):
	sprites[0] = skin_manager.resources["texture"]["mascot_idle"]
	sprites[1] = skin_manager.resources["texture"]["mascot_kiai"]
	sprites[2] = skin_manager.resources["texture"]["mascot_fail"]
	toast_sprites = skin_manager.resources["texture"]["mascot_toast"]
