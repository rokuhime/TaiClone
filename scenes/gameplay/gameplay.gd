extends Control

@onready var obj_container := $Lane/ObjectContainers/TaikoSV
@onready var audio_container := $Audio
@onready var drum_indicator := $Lane/DrumIndicator
@onready var music := $Music
@onready var background := $Background
@onready var hit_indicator := $Lane/ObjectContainers/Target/HitIndicator
@onready var miss_indicator := $Lane/ObjectContainers/Target/MissIndicator

var note_scene = load("res://scenes/gameplay/hitobject/note.tscn")

const VELOCITY_MULTIPLIER := 1.9

## The [Array] of customizable key-binds used in [Gameplay].
const KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

# includes every currently playing drum indicator tween, index'd through input name (see above)
var keypress_tweens := {}

# tween for accurate/inaccurate hit indicator
var hit_indicator_tween : Tween

# tween for miss indicator
var miss_indicator_tween : Tween

var _cur_time := 0.0
var _time_begin := 0.0
var cur_object := 0

func _ready() -> void:
	var chart_path = ChartLoader.get_chart_path("/home/roku/Documents/Programming/TaiClone/Project Files/Post 2hu/assets/stella/LeoNeed x Hatsune Miku - Stella (Nanatsu) [Inner Oni].osu", true)
	if typeof(chart_path) == TYPE_INT:
		# error, shoot a notif to let the user know what happened
		pass
	
	# TODO: rename ChartLoader.load_chart or something, this is stupid
	load_chart(ChartLoader.load_chart(chart_path))
	
	# set time when song starts, using AudioServer to help with latency
	_time_begin += Time.get_ticks_usec() / 1000000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	music.play()

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.is_pressed():
		# collect all inputs into an array to check
		var inputs := []

		for key in KEYS:
			if event.is_action_pressed(str(key), false, true):
				inputs.append(str(key))
				play_keypress_tween(key)

		# hit detection
		# basic invalid index check
		if obj_container.get_child_count() > cur_object:
			# set variable as intended hit object
			var hit_object := obj_container.get_child(cur_object) #as HitObject
			
			# let hit object do hit check
			var hit_check = hit_object.hit(inputs, _cur_time)
			if bool(hit_check):
				
				if hit_indicator_tween:
					hit_indicator_tween.kill()
				hit_indicator_tween = create_tween()
				
				hit_indicator.self_modulate = Color.WHITE
				hit_indicator_tween.tween_property(hit_indicator, "self_modulate", Color(Color.WHITE, 0), 0.3)
				
				# accurate hit
				hit_indicator.texture = SkinManager.hitin_accurate
				if hit_check == 1: # inaccurate hit
					hit_indicator.texture = SkinManager.hitin_inaccurate
				
				# set cur_object to next hit object
				cur_object -= 1

		for key in inputs:
			play_audio(str(key))

func _process(_delta) -> void:
	_cur_time = (Time.get_ticks_usec() / 1000.0) / 1000 - _time_begin
	
	# make all hitobjects move
	for obj in obj_container.get_children():
		obj.move(_cur_time)

		# if already hit, skip misscheck
		if obj.state == -1:
			continue

		# miss check
		if obj.get_index() == cur_object:
			if obj.time < _cur_time - Global.INACC_TIMING:
				obj.miss()
				# set cur_object to next hit object
				cur_object -= 1

func play_audio(input : String, finisher := false) -> void:
	# find intended position of the audio
	var x =  ProjectSettings.get_setting("display/window/size/viewport_width") / 2
	var y =  ProjectSettings.get_setting("display/window/size/viewport_height") / 2
	
	# add offset, and make spawn pos var
	var offset : int
	offset = 200 if input.contains("Right") else -200
	var spawn_pos = Vector2(x + offset,y)
	
	# play sound
	if input.contains("Kat"):
		return Global.expiring_audio.instantiate().ini(audio_container, SkinManager.audio_kat, "SFX", spawn_pos)
	return Global.expiring_audio.instantiate().ini(audio_container, SkinManager.audio_don, "SFX", spawn_pos)

func play_keypress_tween(input : String) -> void:
	# if its already playing, remove it to make a new one
	if keypress_tweens.has(input):
		keypress_tweens[input].kill()
	
	# get wanted section of drum indicator
	var target = drum_indicator.get_child(0).get_node(input)
	
	# create tween, set initial colour, and tween it
	keypress_tweens[input] = create_tween()
	target.self_modulate = Color.WHITE
	keypress_tweens[input].tween_property(target, "self_modulate", Color(Color.WHITE, 0.2196), 0.2)

func load_chart(chart: Chart) -> void:
	music.stream = chart.audio 
	background.texture = chart.background
	
	# treating everything as a note for now
	for h_obj in chart.hit_objects:
		var note = note_scene.instantiate()
		var is_kat = true if h_obj[2] == 3 else false
		note.change_properties(h_obj[0], h_obj[1] * VELOCITY_MULTIPLIER, is_kat)
		
		obj_container.add_child(note)
		for i in range(obj_container.get_child_count()):
			if note.time > (obj_container.get_child(i)).time:
				obj_container.move_child(note, i)
				break
	
	cur_object = obj_container.get_child_count() - 1
