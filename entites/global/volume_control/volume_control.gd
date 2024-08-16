class_name VolumeControl
extends TimeoutControl

var bus_sections := []
var bus_bar_size_tweens := [null]
var bus_bar_alpha_tweens := [null]

@onready var change_sound_player: AudioStreamPlayer = $Audio
var volume_keys := ["VolumeUp", "VolumeDown", "VolumeBusNext", "VolumeBusPrevious"]

const CHANGE_AMOUNT := 0.1
const CHANGE_AMOUNT_PRECISE := 0.01

var current_bus_index := 0
var is_mouse_pressed := false

# -------- system -------

func _ready() -> void:
	super()
	
	var master_bar = get_node("Bars/Master")
	bus_sections.append(master_bar)
	master_bar.mouse_entered.connect(change_current_bus.bind(0))
	master_bar.gui_input.connect(mouse_volume_input.bind(0))
	
	for bar_idx in get_node("Bars/Specifics").get_child_count():
		# ensure theres the same amount of tweens for the sections
		bus_bar_size_tweens.append(null)
		bus_bar_alpha_tweens.append(null)
		
		# add bar to bus_sections and update their visual
		var target_bus: Control = get_node("Bars/Specifics").get_child(bar_idx)
		bus_sections.append(target_bus)
		target_bus.mouse_entered.connect(change_current_bus.bind(bar_idx + 1))
		target_bus.gui_input.connect(mouse_volume_input.bind(bar_idx + 1))
		
		update_bar(bar_idx + 1)
	
	on_active_changed.connect(active_changed)
	
	# ensure it starts invisible
	modulate = Color(1,1,1,0)

func _unhandled_input(_event) -> void:
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

# -------- input -------

func mouse_volume_input(event: InputEventMouse, bus_index: int) -> void:
	if event is InputEventMouseButton:
		# ignore any other inputs but left/right clicks
		if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
			return
		is_mouse_pressed = event.pressed
	
	if is_mouse_pressed:
		var bus_size = bus_sections[bus_index].get_child(0).size.y
		change_volume(clampf((bus_size - event.position.y) / bus_size, 0, 1), true)

# -------- changing values -------

func change_volume(change_amount: float, change_exact := false) -> void:
	change_active(true)
	var new_volume := change_amount if change_exact else clampf(db_to_linear(AudioServer.get_bus_volume_db(current_bus_index)) + change_amount, 0, 1)
	
	# set value and change display
	AudioServer.set_bus_volume_db(current_bus_index, linear_to_db(new_volume))
	update_bar(current_bus_index)
	
	# play sound
	change_sound_player.pitch_scale = new_volume + 0.5
	change_sound_player.play()

func change_current_bus(wanted_bus_index: int) -> void:
	if is_mouse_pressed:
		return
	
	current_bus_index = wanted_bus_index
	
	# change transparency
	for bus_index in bus_sections.size():
		# stop any tweens happening to bar visual
		if bus_bar_alpha_tweens[bus_index]:
			bus_bar_alpha_tweens[bus_index].kill()
		
		# update bus section alpha
		bus_bar_alpha_tweens[bus_index] = Global.create_smooth_tween()
		bus_bar_alpha_tweens[bus_index].tween_property(
			bus_sections[bus_index], 
			"modulate:a", 
			1.0 if bus_index == wanted_bus_index else 0.5,
			0.2
		)

# -------- visual -------

func update_bar(bus_index: int = -1) -> void:
	# if no bus index specified, update all
	if bus_index == -1:
		for i in bus_bar_size_tweens.size():
			update_bar(i)
		return
	
	var volume_slider: TextureProgressBar = bus_sections[bus_index].get_node("TextureProgressBar")
	
	# stop any current tweens happening to bar visual
	if bus_bar_size_tweens[bus_index]:
		bus_bar_size_tweens[bus_index].kill()
	
	# update bar visual
	bus_bar_size_tweens[bus_index] = Global.create_smooth_tween()
	bus_bar_size_tweens[bus_index].tween_property(volume_slider, "value", db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.2)
	
	# set percentage text
	bus_sections[bus_index].get_node("Percentage").text = str( roundi( db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100 ))

# saves settings and goes back to selecting master when unselected
func active_changed(new_active: bool) -> void:
	if not new_active:
		Global.save_settings()
		change_current_bus(0)
