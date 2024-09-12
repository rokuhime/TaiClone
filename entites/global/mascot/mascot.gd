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

var beatsync: BeatSyncronizer

var toast_framerate := 0.2
var toast_lock := false
var next_change_time := 0.0

# -------- system --------

func _ready() -> void:
	beatsync = Global.get_root().timing_clock.make_beat_syncronizer()
	beatsync.beat.connect(update_frame)
	add_child(beatsync)

# -------- animation --------

# restart the current animation cycle and update sprite to match the given state
func start_animation(state: SPRITETYPES) -> void:
	# update and reset sprite
	current_state = state
	current_frame = 0
	
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
	if toast_lock:
		return
	
	var total_frames: int = sprites[int(current_state)].size()
	current_frame = (current_frame + 1) % total_frames
	texture = sprites[int(current_state)][current_frame]

func apply_skin(skin: SkinManager):
	if skin.resource_exists("texture/mascot_idle"):
		sprites[0] = skin.resources["texture"]["mascot_idle"]
	if skin.resource_exists("texture/mascot_kiai"):
		sprites[1] = skin.resources["texture"]["mascot_kiai"]
	if skin.resource_exists("texture/mascot_fail"):
		sprites[2] = skin.resources["texture"]["mascot_fail"]
	if skin.resource_exists("texture/mascot_toast"):
		toast_sprites = skin.resources["texture"]["mascot_toast"]
	
	update_frame()
