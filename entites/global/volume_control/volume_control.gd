class_name VolumeControl
extends ColorRect

var bus_sections := []
var bus_bar_size_tweens := [null, null, null]
var bus_bar_alpha_tweens := [null, null, null]

@onready var change_sound_player: AudioStreamPlayer = $Audio
@onready var timeout_timer: Timer = $Timeout
@onready var timeout_bar: TextureProgressBar = $TimeoutBar
var visibility_tween: Tween
var volume_keys := ["VolumeUp", "VolumeDown", "VolumeBusNext", "VolumeBusPrevious"]

var is_active := false
var is_mouse_inside := false
var is_mouse_pressed := false

const CHANGE_AMOUNT := 0.1
const CHANGE_AMOUNT_PRECISE := 0.01

var current_bus_index := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	bus_sections.append(get_node("Bars/Master"))
	update_bar(0)
	
	for bar_idx in get_node("Bars/Specifics").get_child_count():
		var target_bus: Control = get_node("Bars/Specifics").get_child(bar_idx)
		bus_sections.append(target_bus)
		update_bar(bar_idx + 1)
	
	# ensure it starts invisible
	modulate = Color(1,1,1,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
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

func _unhandled_input(event):
	# parse for wanted inputs
	var pressed_input := ""
	
	for volume_key in volume_keys:
		if Input.is_action_pressed(volume_key):
			pressed_input = volume_key
			break
	
	if pressed_input == "":
		return
	
	if not is_mouse_inside:
		if pressed_input == "VolumeBusNext" or pressed_input == "VolumeBusPrevious":
			if !is_active:
				return
		
		change_active(true)
		timeout_timer.start()
	
	var is_precise = Input.is_action_pressed("VolumePrecise")
	
	match pressed_input:
		"VolumeUp":
			change_volume(CHANGE_AMOUNT_PRECISE if is_precise else CHANGE_AMOUNT)
		"VolumeDown":
			change_volume(-CHANGE_AMOUNT_PRECISE if is_precise else -CHANGE_AMOUNT)
		
		"VolumeBusNext":
			change_current_bus((current_bus_index + 1) % bus_sections.size())
		"VolumeBusPrevious":
			# make sure index loops back to top
			var intended_index = bus_sections.size() - 1 if current_bus_index - 1 < 0 else current_bus_index - 1
			change_current_bus(intended_index % bus_sections.size())

func mouse_volume_input(event: InputEventMouse, bus_index: int):
	if event is InputEventMouseButton:
		# ignore any other inputs but left/right clicks
		if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
			return
		is_mouse_pressed = event.pressed
	
	if is_mouse_pressed:
		var bus_size = bus_sections[bus_index].get_child(0).size.y
		change_volume(clampf((bus_size - event.position.y) / bus_size, 0, 1), true)

func change_volume(change_amount: float, change_exact := false):
	var new_volume := change_amount if change_exact else clampf(db_to_linear(AudioServer.get_bus_volume_db(current_bus_index)) + change_amount, 0, 1)
	
	# set value and change display
	AudioServer.set_bus_volume_db(current_bus_index, linear_to_db(new_volume))
	update_bar(current_bus_index)
	
	# play sound
	change_sound_player.pitch_scale = new_volume + 0.5
	change_sound_player.play()
	
	# save new volume
	get_tree().get_first_node_in_group("SettingsPanel").save_settings()

func update_bar(bus_index: int):
	var volume_slider: TextureProgressBar = bus_sections[bus_index].get_node("TextureProgressBar")
	
	# stop any current tweens happening to bar visual
	if bus_bar_size_tweens[bus_index]:
		bus_bar_size_tweens[bus_index].kill()
	
	# update bar visual
	bus_bar_size_tweens[bus_index] = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	bus_bar_size_tweens[bus_index].tween_property(volume_slider, "value", db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.2)
	
	# set percentage text
	bus_sections[bus_index].get_node("Percentage").text = str( roundi( db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100 ))

func change_current_bus(wanted_bus_index: int):
	if is_mouse_pressed:
		return
	
	current_bus_index = wanted_bus_index
	
	# change transparency
	for bus_index in bus_sections.size():
		# stop any tweens happening to bar visual
		if bus_bar_alpha_tweens[bus_index]:
			bus_bar_alpha_tweens[bus_index]
		
		# update bus section alpha
		bus_bar_alpha_tweens[bus_index] = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		bus_bar_alpha_tweens[bus_index].tween_property(
			bus_sections[bus_index], 
			"modulate:a", 
			1.0 if bus_index == wanted_bus_index else 0.5,
			0.2
		)

# handles visibility, making it invisible and saving volume settings if timed out
func change_active(new_active: bool):
	is_active = new_active
	
	# stop tween if happening to visibility
	if visibility_tween:
		visibility_tween.kill()
	
	# update visibility
	visibility_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	visibility_tween.tween_property(
		self, 
		"modulate:a", 
		1.0 if new_active else 0.0, 
		0.2 if new_active else 1.0
	)
	
	if not new_active:
		# save settings
		change_current_bus(0)

# toggles is_mouse_inside for pausing the timeout timer
func change_mouse_inside(new_mouse_inside: bool):
	is_mouse_inside = new_mouse_inside
	if is_mouse_inside and is_active:
		change_active(true)
	
	timeout_timer.start()
	timeout_timer.paused = new_mouse_inside
