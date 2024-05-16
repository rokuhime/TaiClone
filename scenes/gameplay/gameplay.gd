class_name Gameplay
extends Control
# TODO: spinners are *sometimes* given the correct value(?) but are not playable atm, sliders are correct length but no ticks

@onready var hit_object_container := $Track/HitPoint/HitObjectContainer
var music: AudioStreamPlayer
@onready var audio_queuer := $AudioQueuer as AudioQueuer
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
	# update progress bar
	score_manager.update_progress(current_time, hit_object_container.get_child(0).timing + 2, start_time)
	
	if playing:
		current_time = Time.get_ticks_msec() / 1000.0 - start_time
		
		# chart end check
		if current_time >= hit_object_container.get_child(0).timing + 2:
			get_tree().get_first_node_in_group("Root").change_to_results(score_manager.get_packaged_score())
		
		# move all hitobjects
		for hobj in hit_object_container.get_children():
			hobj.position.x = (hobj.speed * Global.resolution_multiplier) * (hobj.timing - current_time)
		
		# bail out on finding the next note if chart is over
		if next_note_idx < 0:
			return
		
		# miss check
		var next_note: HitObject = get_next_note()
		if next_note.timing + Global.INACC_TIMING < current_time:
			apply_score(next_note.timing - current_time, next_note)
			pass

func _unhandled_input(event) -> void:
	# back to song select
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_tree().get_first_node_in_group("Root").change_to_results(score_manager.get_packaged_score())
	
	if event is InputEventKey or InputEventJoypadMotion and event.is_pressed():
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
		
		# hit check
		if next_note_idx >= 0:
			# check if this hit is going to a finisher, if not then continue
			if finisher_hit_check(current_side_input, is_input_kat):
				return
			
			# check next note
			var next_note: Note = get_next_note()
			if next_note != null:
				hit_check(current_side_input, is_input_kat, next_note)
			
			# check special notes (spinners, rolls)
			for hobj in get_active_hitobjects():
				var result = hobj.hit_check(current_time, current_side_input, is_input_kat)
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
func hit_check(input_side: SIDE, is_input_kat: bool, target_hobj: HitObject ) -> void:
	var hit_result: HitObject.HIT_RESULT = target_hobj.hit_check(current_time, input_side, is_input_kat)
	
	match hit_result:
		HitObject.HIT_RESULT.HIT:
			if target_hobj is Note:
				apply_score(target_hobj.timing - current_time, target_hobj)
			if target_hobj is Roll:
				# add score
				pass
			if target_hobj is Spinner:
				# add score
				pass
		
		# assume hitobject is Note for now
		HitObject.HIT_RESULT.HIT_FINISHER:
			active_finisher_note = target_hobj
			current_hitsound_state = HITSOUND_STATES.FINISHER
			
			apply_score(target_hobj.timing - current_time, target_hobj)
		
		HitObject.HIT_RESULT.MISS:
			apply_score(target_hobj.timing - current_time, target_hobj, true)
		
		_:
			return

# finisher second hit check, returns if it was successful or not
func finisher_hit_check(input_side: SIDE, is_input_kat: bool) -> bool:
	if active_finisher_note:
		if (active_finisher_note.timing - current_time) > Global.INACC_TIMING:
			return false
		
		# successful hit
		elif active_finisher_note.last_side_hit != input_side and active_finisher_note.is_kat == is_input_kat:
			# add score, reset finisher variables
			score_manager.add_finisher_score(active_finisher_note.timing - current_time)
			active_finisher_note = null
			current_hitsound_state = HITSOUND_STATES.NONE
			return true
		
		# if the input is the same side/different colour, null the active finisher and return false
		elif active_finisher_note.last_side_hit == input_side or active_finisher_note.is_kat != is_input_kat:
			active_finisher_note = null 
	return false

func apply_score(hit_time_difference: float, target_hit_obj: HitObject, missed := false) -> void:
	next_note_idx -= 1
	target_hit_obj.visible = false
	score_manager.add_score(hit_time_difference, missed)

func load_chart(requested_chart: Chart) -> void:
	# empty out existing hit objects and reset stats just incasies
	for hobj in hit_object_container.get_children():
		hobj.queue_free()
	active_finisher_note = null 
	score_manager.reset()
	
	current_chart = requested_chart
	
	# set skip time to the first hit object's timing - 2 secs
	skip_time = requested_chart.hit_objects[requested_chart.hit_objects.size() - 1].timing - 2
	# add all hit objects to container
	for hobj in requested_chart.hit_objects:
		hit_object_container.add_child(hobj)
	music.stream = requested_chart.audio
	
	# ensure next note is correct and play
	next_note_idx = current_chart.hit_objects.size() - 1
	play_chart()

func play_chart() -> void:
	# error checks before starting to make sure chart is valid
	if current_chart == null:
		printerr("Gameplay: tried to play without a valid chart! abandoning...")
		return
	
	var next_hit_object: HitObject = get_next_note()
	if next_hit_object == null:
		printerr("Gameplay: tried to play a chart without notes! abandoning...")
		return
	
	current_play_offset = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	
	# delay the chart if first note is less than 2 seconds into the song
	var first_note_delay := 0.0
	if next_hit_object.timing < 2.0:
		first_note_delay = 2.0 - next_hit_object.timing
	current_play_offset += first_note_delay
	
	start_time = Time.get_ticks_msec() / 1000.0 + current_play_offset
	playing = true;
	
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
	
	# get first note timing and seek to it
	var next_hit_object: HitObject = get_next_note()
	if next_hit_object == null:
		return
	start_time -= next_hit_object.timing - 2.0 - current_time
	music.seek(current_play_offset + next_hit_object.timing - 2.0)

# returns next valid note object
func get_next_note() -> Note:
	if hit_object_container.get_child_count() == 0:
		return null;
	
	var next_note : HitObject 
	var next_note_offset = 0
	# check hitobjects for next valid note
	while !(next_note is Note):
		if hit_object_container.get_children()[next_note_idx - next_note_offset] is Note:
			next_note = hit_object_container.get_children()[next_note_idx - next_note_offset]
		next_note_offset += 1
	if next_note:
		return next_note
	
	# no notes left
	return null

# returns any hit objects with length that have started but not ended
func get_active_hitobjects() -> Array:
	var active_hobjs := []
	var next_hobj: HitObject
	var next_hobj_offset = hit_object_container.get_child_count() - 1
	
	# check hitobjects for next valid note, otherwise return the last object
	while next_hobj_offset >= 0:
		next_hobj = hit_object_container.get_children()[next_hobj_offset]
		
		# if it has length...
		if next_hobj is Roll or next_hobj is Spinner:
			# if hit object timing is after current_time, bail out
			if next_hobj.timing - Global.INACC_TIMING > current_time:
				break
			
			# if hit object timing has passed but has not ended, add to array
			# allows for stacking sliders/spinners/whatever else (hypothetically)
			if next_hobj.timing + next_hobj.length + Global.INACC_TIMING > current_time:
				active_hobjs.append(next_hobj)
		next_hobj_offset -= 1
		
		# if last hitobj, break and return hit objects
		if next_hobj_offset <= 0:
			break
	
	return active_hobjs
