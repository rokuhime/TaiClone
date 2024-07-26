class_name Gameplay
extends Control
# TODO: spinners are *sometimes* given the correct value(?) but are not playable atm, sliders are correct length but no ticks

# UI
@onready var hit_object_container := $Track/HitPoint/HitObjectContainer
@onready var audio_queuer := $AudioQueuer as AudioQueuer
@onready var score_manager := $ScoreManager as ScoreManager
var music: AudioStreamPlayer

@onready var drum_indicator: Node = $Track/DrumIndicator
var drum_indicator_tweens : Array = [null, null, null, null]

# Mascot
@onready var mascot := $Mascot as TextureRect
var current_bps := 0.0	# beats per second

var auto_enabled := false

# Data
var current_time := 0.0
var start_time := 0.0
var end_time := 0.0

var current_chart : Chart
var current_play_offset := 0.0
var playing := false
var skip_time := 0.0
var in_kiai := false

var next_note_idx := 0

# Input
enum SIDE { NONE, LEFT, RIGHT }
enum SCORETYPE { MISS, INACCURATE, ACCURATE }
var last_side_input := SIDE.NONE
var active_finisher_note: Note

# Hitsounds
enum HITSOUND_STATES {NONE, NORMAL, FINISHER}
var current_hitsound_state = HITSOUND_STATES.NORMAL

var don_audio := AudioLoader.load_file("res://assets/default_skin/h_don.wav") as AudioStream
var kat_audio := AudioLoader.load_file("res://assets/default_skin/h_kat.wav") as AudioStream
var donfinisher_audio := AudioLoader.load_file("res://assets/default_skin/hf_don.wav") as AudioStream
var katfinisher_audio := AudioLoader.load_file("res://assets/default_skin/hf_kat.wav") as AudioStream

func _ready() -> void:
	music = Global.music
	score_manager.connect("toast", Callable(mascot, "toast"))

func _process(_delta) -> void:
	# update progress bar
	score_manager.update_progress(current_time, hit_object_container.get_child(0).timing + 2, start_time)
	
	if playing:
		current_time = (Time.get_ticks_msec() / 1000.0) - Global.global_offset - start_time
		
		# chart end check
		if current_time >= end_time + 2:
			get_tree().get_first_node_in_group("Root").change_to_results(score_manager.get_packaged_score())
		
		# move all hitobjects
		for hobj in hit_object_container.get_children():
			hobj.position.x = (hobj.speed * Global.resolution_multiplier) * (hobj.timing - current_time)
		
		# bail out on finding the next note if chart is over
		if next_note_idx < 0:
			return
		
		# miss check
		for i in range(hit_object_container.get_child_count() - 1, -1, -1):
			var hit_object := hit_object_container.get_child(i) as HitObject
			if hit_object.timing <= current_time:
				# auto
				if hit_object.active and hit_object is Note and auto_enabled:
					hit_check(SIDE.LEFT, hit_object.is_kat, hit_object)
					play_audio(SIDE.LEFT, hit_object.is_kat)
					current_hitsound_state = HITSOUND_STATES.NORMAL
					return
				
				var miss_result := hit_object.miss_check(current_time)
				if miss_result:
					# if passing a timing point, apply it
					if hit_object is TimingPoint:
						apply_timing_point(hit_object, current_time)
						return
					
					apply_score(hit_object)
					if mascot.current_state != mascot.SPRITETYPES.FAIL:
						mascot.start_animation(mascot.SPRITETYPES.FAIL, current_bps, hit_object.timing)

func _unhandled_input(event) -> void:
	# back to song select
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_tree().get_first_node_in_group("Root").change_to_results(score_manager.get_packaged_score())
	
	if event is InputEventKey or InputEventJoypadMotion and event.is_pressed():
		if Input.is_action_just_pressed("SkipIntro") and playing:
			skip_intro()
		
		if auto_enabled:
			return
		
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
		
		# hit check
		if active_finisher_note:
			var finisher_note_idx = active_finisher_note.get_index()
			if finisher_hit_check(current_side_input, is_input_kat):
				play_audio(current_side_input, is_input_kat)
				
				# if the next hit object is outside of accurate timing, swallow the input to stop it from checking more notes
				if abs(hit_object_container.get_child(finisher_note_idx - 1).timing - current_time) > Global.ACC_TIMING:
					return
		
		for i in range(hit_object_container.get_child_count() - 1, -1, -1):
			var hit_object := hit_object_container.get_child(i) as HitObject
			if hit_object != null:
				# if its past being valid
				if hit_object.timing - current_time > Global.INACC_TIMING:
					break
				elif hit_check(current_side_input, is_input_kat, hit_object):
					if mascot.current_state != mascot.SPRITETYPES.IDLE and mascot.current_state != mascot.SPRITETYPES.KIAI:
						mascot.start_animation(mascot.SPRITETYPES.KIAI if in_kiai else mascot.SPRITETYPES.IDLE, 
							current_bps, 
							hit_object.timing)
					break
		
		play_audio(current_side_input, is_input_kat)

# plays note audio
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

# give hitobject hit info, gets result, and applies score
# returns true if hit was used on a note, otherwise returns false
func hit_check(input_side: SIDE, is_input_kat: bool, target_hobj: HitObject ) -> bool:
	var hit_result: HitObject.HIT_RESULT = target_hobj.hit_check(current_time, input_side, is_input_kat)
	
	match hit_result:
		HitObject.HIT_RESULT.HIT:
			if target_hobj is Note:
				apply_score(target_hobj)
		
		HitObject.HIT_RESULT.HIT_FINISHER:
			active_finisher_note = target_hobj
			current_hitsound_state = HITSOUND_STATES.FINISHER
			
			apply_score(target_hobj)
		
		HitObject.HIT_RESULT.MISS:
			apply_score(target_hobj, true)
		
		_:
			return false
	
	# if the hit object was a note, the hit was used. return true
	if target_hobj is Note:
		return true
	# if it was given to a spinner/roll, allow the input still be valid for another hit object
	return false

func miss_check(next_note: HitObject) -> void:
	var miss_result = next_note.miss_check(current_time)
		
	match next_note.get_class():
		"Note":
			apply_score(next_note, true)
		
		# roku note 2024-05-17
		# no roku, NO. BAD
		# this is stupid, score_manager.add_score() needs to be reworked for manual score adding (for ticks n such)
		"Spinner":
			match miss_result:
				HitObject.HIT_RESULT.INVALID:
					print("miss_check invalid spinner result")
					get_tree().create_timer(1).timeout.connect(func(): miss_check(next_note))
				# more than half hit
				HitObject.HIT_RESULT.HIT:
					score_manager.add_score(Global.INACC_TIMING)
				# less than half hit
				HitObject.HIT_RESULT.MISS:
					score_manager.add_score(Global.INACC_TIMING + 5)

# finisher second hit check, returns if it was successful or not
func finisher_hit_check(input_side: SIDE, is_input_kat: bool) -> bool:
	if active_finisher_note:
		if (active_finisher_note.timing - current_time) < Global.ACC_TIMING:
			# in time
			if active_finisher_note.last_side_hit != input_side and active_finisher_note.is_kat == is_input_kat:
				# add score, reset finisher variables
				score_manager.add_finisher_score(active_finisher_note.timing - current_time)
				active_finisher_note = null
				current_hitsound_state = HITSOUND_STATES.NONE
				return true
	
	active_finisher_note = null 
	return false

func apply_score(target_hit_obj: HitObject, missed := false) -> void:
	next_note_idx -= 1
	target_hit_obj.visible = false
	score_manager.add_score(target_hit_obj.timing - current_time, missed)

func load_chart(requested_chart: Chart) -> void:
	# empty out existing hit objects and reset stats just incasies
	for hobj in hit_object_container.get_children():
		hobj.queue_free()
	active_finisher_note = null 
	score_manager.reset()
	
	current_chart = requested_chart
	
	# add all hit objects to container
	for hobj in requested_chart.hit_objects:
		hit_object_container.add_child(hobj)
	music.stream = requested_chart.audio
	
	# set skip time to the first hit object's timing - 2 secs
	skip_time = get_first_hitobject().timing - 2
	
	end_time = current_chart.hit_objects[0].timing
	if current_chart.hit_objects[0] is Spinner or current_chart.hit_objects[0] is Roll:
		end_time += current_chart.hit_objects[0].length
	
	# ensure next note is correct and play
	next_note_idx = current_chart.hit_objects.size() - 1
	play_chart()

func play_chart() -> void:
	# error checks before starting to make sure chart is valid
	if current_chart == null:
		printerr("Gameplay: tried to play without a valid chart! abandoning...")
		return
	
	if hit_object_container.get_child_count() <= 0:
		printerr("Gameplay: tried to play a chart without notes! abandoning...")
		return
	
	current_play_offset = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	
	# delay the chart if first note is less than 2 seconds into the song
	var first_note_delay := 0.0
	var first_hit_object = get_first_hitobject()
	
	if first_hit_object.timing < 2.0:
		first_note_delay = 2.0 - first_hit_object.timing
		current_play_offset += first_note_delay
	
	start_time = Time.get_ticks_msec() / 1000.0 + current_play_offset
	playing = true
	
	# get first timing point and apply
	for i in range(hit_object_container.get_child_count() - 1, -1, -1):
		var hit_object = hit_object_container.get_child(i)
		if hit_object is TimingPoint:
			apply_timing_point(hit_object, start_time)
			break
	
	# delay audio playing if theres a positive (late) offset
	if first_note_delay:
		await get_tree().create_timer(first_note_delay).timeout
	music.play()

func update_input_indicator(part_index: int) -> void:
	var indicator_target: Control = drum_indicator.get_children()[part_index]
	
	if drum_indicator_tweens[part_index]:
		drum_indicator_tweens[part_index].kill()
	
	drum_indicator_tweens[part_index] = create_tween()
	drum_indicator_tweens[part_index].tween_property(indicator_target, "modulate:a", 0.0, 0.2).from(1.0)

func skip_intro() -> void:
	if current_time >= skip_time:
		return
	var first_hit_object = get_first_hitobject()
	start_time -= first_hit_object.timing - 2.0 - current_time
	music.seek(current_play_offset + first_hit_object.timing - 2.0)
	mascot.anim_start_time -= first_hit_object.timing - 2.0 - current_time

func apply_timing_point(timing_point: TimingPoint, current_time: float) -> void:
	current_bps = 60.0 / timing_point.bpm
	if timing_point.is_finisher != in_kiai:
		in_kiai = timing_point.is_finisher
	mascot.start_animation(mascot.SPRITETYPES.KIAI if in_kiai else mascot.SPRITETYPES.IDLE, 
							current_bps, 
							timing_point.timing - current_time)

func get_first_hitobject() -> HitObject:
	# get first hit object thats not a timing point
	var first_hit_object: HitObject
	for i in range(hit_object_container.get_child_count() - 1, -1, -1):
		var hit_object := hit_object_container.get_child(i) as HitObject
		if hit_object is TimingPoint:
			continue
		return hit_object
	return null
