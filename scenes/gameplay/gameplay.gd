class_name Gameplay
extends Control
# TODO: last thing i started was actual input registration with notes, but i didnt get past making next_note_idx
# spinners are given the correct value(?) but are not playable atm, sliders are correct length but no ticks

@onready var hit_object_container := $Track/HitPoint/HitObjectContainer
var music: AudioStreamPlayer
@onready var audio_queuer := $AudioQueuer as AudioQueuer
@onready var fps_label := $fps as Label
@onready var score_manager := $ScoreManager as ScoreManager

@onready var drum_indicator: Node = $Track/DrumIndicator
var drum_indicator_tweens : Array = [null, null, null, null]

var current_chart : Chart
@export var current_time := 0.0
@export var start_time := 0.0
var current_play_offset := 0.0
var playing := false
var skip_time := 0.0

@export var next_note_idx := 0

enum SIDE { NONE, LEFT, RIGHT }
var last_side_input := SIDE.NONE
var active_finisher_note: Note

enum HITSOUND_STATES {NONE, NORMAL, FINISHER}
var current_hitsound_state = HITSOUND_STATES.NORMAL

var don_audio := AudioLoader.load_file("res://assets/default_skin/h_don.wav") as AudioStream
var kat_audio := AudioLoader.load_file("res://assets/default_skin/h_kat.wav") as AudioStream
var donfinisher_audio := AudioLoader.load_file("res://assets/default_skin/hf_don.wav") as AudioStream
var katfinisher_audio := AudioLoader.load_file("res://assets/default_skin/hf_kat.wav") as AudioStream

func _ready() -> void:
	music = Global.music

func _process(_delta) -> void:
	score_manager.update_progress(current_time, hit_object_container.get_child(0).timing + 2, start_time)
	
	if playing:
		current_time = Time.get_ticks_msec() / 1000.0 - start_time
		
		if current_time >= hit_object_container.get_child(0).timing + 2:
			get_tree().get_first_node_in_group("Root").change_to_results(score_manager.get_packaged_score())
		
		for hobj in hit_object_container.get_children():
			hobj.position.x = (hobj.speed * Global.resolution_multiplier) * (hobj.timing - current_time)
		
		if next_note_idx <= 0:
			return
			
		var next_note : Note = get_next_note()
		if next_note.timing + Global.INACC_TIMING < current_time:
			apply_score(next_note.timing - current_time, next_note)
			pass

func _unhandled_input(event) -> void:
	# back to song select
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_tree().get_first_node_in_group("Root").change_to_results(score_manager.get_packaged_score())
	
	if event is InputEventKey or InputEventJoypadMotion and event.is_pressed():
		var next_note: Note = get_next_note()
		if next_note == null:
			return
		if Input.is_action_just_pressed("SkipIntro") and playing:
			skip_intro()
		
		# get rhythm gameplay input
		var pressed_input := ""
		
		for gameplay_input in Global.GAMEPLAY_KEYS:
			if Input.is_action_just_pressed(gameplay_input):
				pressed_input = gameplay_input
				break
		
		if pressed_input == "" or !playing: 
			return
		
		current_hitsound_state = HITSOUND_STATES.NORMAL
		update_input_indicator(Global.GAMEPLAY_KEYS.find(pressed_input))
		
		var current_side_input = SIDE.LEFT if pressed_input.contains("Left") else SIDE.RIGHT
		var is_input_kat := false if pressed_input.contains("Don") else true
		
		if next_note_idx > 0:
			hit_check(current_side_input, is_input_kat, next_note)
		play_audio(current_side_input, is_input_kat)

func play_audio(input_side: SIDE, is_input_kat: bool):
	var stream_audio = kat_audio if is_input_kat else don_audio
	match current_hitsound_state:
		HITSOUND_STATES.NONE:
			return
		HITSOUND_STATES.FINISHER:
			stream_audio = katfinisher_audio if is_input_kat else donfinisher_audio
	
	# audio
	var stream_pos_offset = 250 if input_side == SIDE.RIGHT else -250
	var stream_position := Vector2(0, ProjectSettings.get_setting("display/window/size/viewport_height") / 2)
	stream_position.x = ProjectSettings.get_setting("display/window/size/viewport_width") / 2 + stream_pos_offset
	
	audio_queuer.play_audio(stream_audio, stream_position)

func hit_check(input_side: SIDE, is_input_kat: bool, target_note: Note ) -> void:
	if active_finisher_note:  #for secondary finisher hit
		if (active_finisher_note.timing - current_time) > Global.INACC_TIMING:
			pass
		elif active_finisher_note.last_side_hit != input_side and active_finisher_note.is_kat == is_input_kat:
			apply_finisher_score(active_finisher_note.timing - current_time)
			current_hitsound_state = HITSOUND_STATES.NONE
			#print("secondary finisher hit")
			return
		# if the input is the same side/different colour, null the active finisher and look at next circle
		elif active_finisher_note.last_side_hit == input_side or active_finisher_note.is_kat != is_input_kat:
			active_finisher_note = null 
			#print("redirecting finisher hit to normal hit")
	
	# if not hittable yet
	if abs(target_note.timing - current_time) > Global.INACC_TIMING:
		#print("not hittable")
		return
	
	# wrong input type miss
	elif target_note.is_kat != is_input_kat:
		#print("wrong kat")
		apply_score(target_note.timing - current_time, target_note, true)
		return
	
	# new finisher hit
	if target_note.is_finisher and !active_finisher_note:
		#print("new finisher")
		current_hitsound_state = HITSOUND_STATES.FINISHER
		active_finisher_note = target_note
		target_note.last_side_hit = input_side as Note.SIDE
	
	#print("hitting note")
	apply_score(target_note.timing - current_time, target_note)

func apply_finisher_score(hit_time_difference: float) -> void:
	score_manager.add_finisher_score(hit_time_difference)
	active_finisher_note = null

func apply_score(hit_time_difference: float, target_hit_obj: HitObject, missed := false) -> void:
	next_note_idx -= 1
	target_hit_obj.visible = false
	score_manager.add_score(hit_time_difference, missed)

func load_chart(requested_chart: Chart) -> void:
	for hobj in hit_object_container.get_children():
		hobj.queue_free()
	active_finisher_note = null 
	score_manager.reset()
	
	current_chart = requested_chart
	for hobj in requested_chart.hit_objects:
		if !skip_time:
			skip_time = hobj.timing - 2
		hit_object_container.add_child(hobj)
	music.stream = requested_chart.audio
	
	next_note_idx = current_chart.hit_objects.size() - 1
	
	play_chart()

func play_chart() -> void:
	if current_chart == null:
		printerr("Gameplay: tried to play without a valid chart!")
		return
	
	current_play_offset = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	var next_hit_object: HitObject = get_next_note()
	if next_hit_object == null:
		return
	
	# TODO: timer causes early audio desync (i cant figure out why for the life of me)
	
	start_time = Time.get_ticks_msec() / 1000.0 + current_play_offset
	#var aaaaa := 0.0
	#if next_hit_object.timing < 2.0:
		#aaaaa = 2.0 - next_hit_object.timing
		#start_time += aaaaa
	playing = true;
	
	# delay audio playing if theres a positive (late) offset
	#if aaaaa:
		#await get_tree().create_timer(aaaaa + current_play_offset).timeout
	music.play()
	# callable version:
	# var play_music := Callable(music, "play")
	# get_tree().create_timer(start_offset).timeout.connect(play_music)

func update_input_indicator(part_index: int) -> void:
	var indicator_target: Control = drum_indicator.get_children()[part_index]
	
	if drum_indicator_tweens[part_index]:
		drum_indicator_tweens[part_index].kill()
	
	drum_indicator_tweens[part_index] = create_tween()
	drum_indicator_tweens[part_index].tween_property(indicator_target, "modulate:a", 0.0, 0.2).from(1.0)

func skip_intro() -> void:
	if next_note_idx < current_chart.hit_objects.size() or current_time >= skip_time:
		return
	
	print("skipping intro!")
	var next_hit_object: HitObject = get_next_note()
	if next_hit_object == null:
		return
	start_time -= next_hit_object.timing - 2.0 - current_time
	music.seek(current_play_offset + next_hit_object.timing - 2.0)

func get_next_note() -> Note:
	if hit_object_container.get_child_count() == 0:
		return null;
	
	var next_note : HitObject 
	var next_note_offset = 0
	while !(next_note is Note):
		if hit_object_container.get_children()[next_note_idx - next_note_offset] is Note:
			next_note = hit_object_container.get_children()[next_note_idx - next_note_offset]
		next_note_offset += 1
	return next_note
