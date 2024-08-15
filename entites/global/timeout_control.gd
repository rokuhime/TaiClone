# class for control nodes that will fade out upon inaction
class_name TimeoutControl
extends Control

@export var timeout_timer: Timer
@export var timeout_bar: TextureProgressBar
var visibility_tween: Tween

var is_active := false
var is_mouse_inside := false

var fade_out_delay := 1.5
const FADE_IN_TIME := 0.2
const FADE_OUT_TIME := 1

signal on_active_changed(active_state: bool)

func _ready():
	mouse_entered.connect(change_mouse_inside.bind(true))
	mouse_exited.connect(change_mouse_inside.bind(false))
	
	timeout_timer.one_shot = true
	timeout_timer.wait_time = fade_out_delay
	timeout_timer.timeout.connect(change_active.bind(false))

func _process(delta):
	# ensure control's visual is correct so no weird mouse inputs happen
	if modulate.a == 0 and visible:
		visible = false
	elif modulate.a > 0 and not visible:
		visible = true
	
	# ensure timeout bar is visually correct
	if not is_mouse_inside and visible:
		timeout_bar.value = timeout_timer.time_left / timeout_timer.wait_time
	elif is_mouse_inside and timeout_bar.value != 1:
		timeout_bar.value = 1

# toggles is_mouse_inside for pausing the timeout timer
func change_mouse_inside(new_mouse_inside: bool) -> void:
	is_mouse_inside = new_mouse_inside
	if is_mouse_inside:
		change_active(true)
	
	timeout_timer.start()
	timeout_timer.paused = new_mouse_inside

# handles visibility, fades out if not active
func change_active(new_active: bool) -> void:
	is_active = new_active
	if is_active and not is_mouse_inside and is_node_ready():
		timeout_timer.start()
	
	if visibility_tween:
		visibility_tween.kill()
	
	visibility_tween = Global.create_smooth_tween()
	visibility_tween.tween_property(
		self, 
		"modulate:a", 
		1.0 if new_active else 0.0, 
		FADE_IN_TIME if new_active else FADE_OUT_TIME
	)
	
	on_active_changed.emit(new_active)
