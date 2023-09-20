extends ColorRect

@onready var vol_section := [$Bars/Master, $Bars/Spesifics/Music, $Bars/Spesifics/SFX]
@onready var change_sound := $Audio as AudioStreamPlayer
@onready var timer := $Timeout as Timer
@onready var timeout_bar := $TimeoutBar as TextureProgressBar
var mouse_inside := false
var cur_bus := 0
var timeout_tween : Tween
var visible_tween : Tween

func _ready():
	# start invisible
	modulate = Color(1,1,1,0)
	
	# make sure all busses are at their correct values
	var i := 0
	for bus in vol_section:
		update_bar(i)
		i += 1

func _input(ev) -> void:
	# if using precise scrolling change by 1%, else change volume by 10%
	var change_amount : float
	change_amount = 0.01 if Input.is_action_pressed("VolPrecision") else 0.1
	
	if Input.is_action_pressed("VolUp"):
		change_vol(change_amount)
		if not mouse_inside:
			change_focus()
	
	elif Input.is_action_pressed("VolDown"):
		change_vol(change_amount * -1)
		if not mouse_inside:
			change_focus()

func update_bar(idx) -> void:
	# tween the bar value to make it smoothly jump to the value
	var bar := vol_section[idx].get_node("TextureProgressBar") as TextureProgressBar
	smart_tween(bar, "value", db_to_linear(AudioServer.get_bus_volume_db(idx)), 0.2)
	
	# change percentage text
	vol_section[idx].get_node("Percentage").text = str( round(db_to_linear(AudioServer.get_bus_volume_db(idx)) * 100) )

func change_vol(value : float) -> void:
	# get new volume value 0-1, clamped 
	var new_vol = clamp( db_to_linear(AudioServer.get_bus_volume_db(cur_bus)) + value, 0, 1)
	
	# set value and change display
	AudioServer.set_bus_volume_db(cur_bus, linear_to_db(new_vol))
	update_bar(cur_bus)
	
	# play sound for feedback
	change_sound.pitch_scale = new_vol + 0.5
	change_sound.play()

# automatically changes on mouse over
func change_cur_bus(idx := 0) -> void:
	cur_bus = idx
	
	# change modulate of other channels
	var i := 0
	for section in vol_section:
		if idx == i:
			smart_tween(section, "modulate", Color(1,1,1,1), 0.2)
		else:
			smart_tween(section, "modulate", Color(1,1,1,0.5), 0.2)
		i += 1

func change_focus(new_mouse_inside := false) -> void:
	mouse_inside = new_mouse_inside
	change_visibility(true)
	if mouse_inside: # volume is moused over
		timer.stop()
		
		if timeout_tween:
			timeout_tween.kill()
		timeout_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		timeout_tween.tween_property(timeout_bar, "value", 1, 0.2)
		return
	
	# timeout for disappearing
	timer.start()
	timeout_bar.value = 1
	
	if timeout_tween:
		timeout_tween.kill()
	timeout_tween = create_tween()
	timeout_tween.tween_property(timeout_bar, "value", 0, timer.wait_time)

func change_visibility(visible : bool) -> void:
	var new_colour : Color
	new_colour = Color.WHITE if visible else Color(1,1,1,0)
	
	if visible_tween:
		visible_tween.kill()
	visible_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	visible_tween.tween_property(self, "modulate", new_colour, 0.2)
	
	# change cur_bus to master if left to go invisible
	if not visible:
		change_cur_bus(0)

# automatically disposing tween, works best if same duration so it writes over possible dupiclates
# shorthand way so i dont have to write a novel to make a single tween www
func smart_tween(object, property: String, final_val, duration: float) -> void:
	# transitions make it nice n snappy :^D
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(object, property, final_val, duration)
	await tween.finished
	tween.kill()
