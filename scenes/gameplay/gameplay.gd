class_name Gameplay
extends Control

# UI
@onready var pause_overlay := $PauseOverlay
@onready var game_overlay := $GameOverlay as GameOverlay
@onready var hit_object_container := $Track/HitPoint/HitObjectContainer
@onready var audio_queuer := $AudioQueuer as AudioQueuer
var music: AudioStreamPlayer

@onready var drum_indicator: Node = $Track/DrumIndicator
var drum_indicator_tweens : Array = [null, null, null, null]
var spinner_gameplay_location := Vector2(69, 425)

# Data
var current_chart : Chart
var current_play_offset := 0.0
var score_instance := ScoreData.new()
var enabled_mods := []

var pause_time := 0.0
var music_starting_timer := Timer.new()
var current_time := 0.0
var start_time := 0.0
var first_hobj_timing := 0.0
var last_hobj_timing := 0.0

var current_bps := 0.0 # beats per second
var playing := false
var in_kiai := false

# Input
enum SIDE { NONE, LEFT, RIGHT }
enum SCORETYPE { MISS, INACCURATE, ACCURATE }
var last_side_input := SIDE.NONE
var active_finisher_note: Note

# Hitsounds
enum HITSOUND_STATES {NONE, NORMAL, FINISHER}
var current_hitsound_state = HITSOUND_STATES.NORMAL

var don_audio := preload("res://assets/default_skin/h_don.wav") as AudioStream
var kat_audio := preload("res://assets/default_skin/h_kat.wav") as AudioStream
var donfinisher_audio := preload("res://assets/default_skin/hf_don.wav") as AudioStream
var katfinisher_audio := preload("res://assets/default_skin/hf_kat.wav") as AudioStream
@onready var barline_tick_player := $BarlineTick as AudioStreamPlayer

@onready var offset_panel := $OffsetPanel

const OFFSET_INCREASE := 0.005
var local_offset := 0.0

# -------- system -------

func _ready() -> void:
	# replace this with it being provided from root, wait for player class implementation first
	apply_skin(Global.get_root().current_skin)
	
	score_instance.combo_break.connect(game_overlay.on_combo_break)
	
	add_child(music_starting_timer)
	music_starting_timer.one_shot = true
	music_starting_timer.stop()
	
	music = Global.music
	pause_overlay.get_node("VBoxContainer/Quit").pressed.connect(
		Global.get_root().change_to_results.bind(score_instance)
	)

func _process(_delta) -> void:
	# update progress bar
	game_overlay.update_progress(current_time, first_hobj_timing, last_hobj_timing)
	
	if playing:
		current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset - local_offset 
		
		# chart end check
		if current_time >= last_hobj_timing + 1:
			Global.get_root().change_to_results(score_instance)
		
		# move all hitobjects
		for hobj in hit_object_container.get_children():
			hobj.position.x = (hobj.speed * Global.resolution_multiplier) * (hobj.timing - current_time) - (hobj.size.x / 2)
		
		# check for misses/timing activations
		for i in range(hit_object_container.get_child_count() - 1, -1, -1):
			var hit_object := hit_object_container.get_child(i) as HitObject
			if not hit_object.active:
				continue
			if hit_object.timing > current_time:
				return
			
			# activating spinners
			if hit_object is Spinner and hit_object.hit_status == Spinner.hit_type.INACTIVE:
				# move interactive element out of hit object to make it still
				hit_object.remove_child(hit_object.spinner_gameplay)
				hit_object_container.get_parent().add_child(hit_object.spinner_gameplay)
				# set position
				hit_object.spinner_gameplay.position = spinner_gameplay_location
				hit_object.transition_to_playable()
				return
			
			# auto
			if enabled_mods.has(ModPanel.MOD_TYPES.AUTO):
				if hit_object is Note:
					if hit_check(SIDE.LEFT, hit_object.is_kat, hit_object):
						play_audio(SIDE.LEFT, hit_object.is_kat)
						current_hitsound_state = HITSOUND_STATES.NORMAL
						return
			
			# actual miss check!!
			var miss_result := hit_object.miss_check(current_time)
			if miss_result:
				if hit_object.is_in_group("Hittable"):
					if hit_object is Note:
						apply_score(hit_object, HitObject.HIT_RESULT.MISS)
					continue # could be more objects to miss (eg notes during a spinner)
				
				# if passing a timing point, apply it
				if hit_object is TimingPoint:
					apply_timing_point(hit_object, current_time)
					return
				# assume barline
				if enabled_mods.has(ModPanel.MOD_TYPES.BARLINE_AUDIO):
					barline_tick_player.play()
					return

func _unhandled_input(event) -> void:
	if Global.focus_target:
		return
	
	# back to song select
	if Input.is_action_just_pressed("Back"):
		change_pause_state(playing)
	
	if event is InputEventKey or InputEventJoypadButton and event.is_pressed():
		if Input.is_action_just_pressed("AddLocalOffset"):
			adjust_offset(OFFSET_INCREASE)
		
		if Input.is_action_just_pressed("RemoveLocalOffset"):
			adjust_offset(-OFFSET_INCREASE)
		
		
		if Input.is_action_just_pressed("SkipIntro") and playing:
			skip_intro()
		
		if Input.is_action_just_pressed("Retry"):
			restart_chart()
		
		if enabled_mods.has(ModPanel.MOD_TYPES.AUTO) or !playing:
			return
		
		# get rhythm gameplay input
		var pressed_inputs := []
		for gameplay_input in Global.GAMEPLAY_KEYS:
			if Input.is_action_just_pressed(gameplay_input):
				pressed_inputs.append(gameplay_input)
				break
		
		if pressed_inputs.is_empty(): 
			return
		
		for input in pressed_inputs:
			current_hitsound_state = HITSOUND_STATES.NORMAL
			update_input_indicator(Global.GAMEPLAY_KEYS.find(input))
			
			var current_side_input = SIDE.LEFT if input.contains("Left") else SIDE.RIGHT
			var is_input_kat := false if input.contains("Don") else true
			
			# hit check
			if active_finisher_note:
				var finisher_note_idx = active_finisher_note.get_index()
				if finisher_hit_check(current_side_input, is_input_kat):
					play_audio(current_side_input, is_input_kat) # play finisher sound
					continue
			
			# roku note 2024-08-06
			# something went horribly wrong and will need to be undone in regards to this function
			# starts randomly missing all the time during hitchecks
			for i in range(hit_object_container.get_child_count() - 1, -1, -1):
				var hit_object := hit_object_container.get_child(i) as HitObject
				
				# ensure hobj can be hit
				if hit_object != null and hit_object.is_in_group("Hittable"):
					if hit_object.active:
						var start_time := hit_object.timing - Global.MISS_TIMING
						
						# if its a hobj with length, check the end time
						if hit_object is Roll or hit_object is Spinner:
							var end_time: float = hit_object.timing + hit_object.length + Global.INACC_TIMING
							
							# if the end times hasnt passed, do a hitcheck
							if end_time >= current_time:
								hit_check(current_side_input, is_input_kat, hit_object)
								continue # dont swallow input, continue
						
						# if the start is later than the current time...
						if start_time > current_time:
							break # stop checking hobj's
						
						# within bounds, do a hitcheck
						if hit_check(current_side_input, is_input_kat, hit_object):
							break
			play_audio(current_side_input, is_input_kat) # play normal sound

# -------- offset handling --------

func adjust_offset(value: float) -> float:
	local_offset += value
	offset_panel.change_offset_text(local_offset)
	return local_offset

func save_local_offset(_active := false) -> void:
	# _active only here so on_active_changed can work properly
	if _active:
		return
	
	var chart_settings_entries: Array = Global.database_manager.get_db_entries_by_id("chart_settings", current_chart.chart_info["id"])
	if chart_settings_entries:
		chart_settings_entries[0]["local_offset"] = local_offset
	else:
		chart_settings_entries.append({"id": current_chart.chart_info["id"], "hash": current_chart.hash, "local_offset": local_offset, "collections": 0})
	Global.database_manager.update_db_entry("chart_settings", chart_settings_entries[0])
	Global.push_console("Gameplay", "Saved local offset: %s" % local_offset)

# -------- chart playback --------

func load_chart(requested_chart: Chart) -> void:
	# empty out existing hit objects and reset stats just incasies
	for hobj in hit_object_container.get_children():
		hobj.queue_free()
	active_finisher_note = null
	
	current_chart = requested_chart.load_hit_objects()
	
	Global.get_root().update_current_chart(current_chart, true)
	var chart_settings = Global.database_manager.get_db_entries_by_id("chart_settings", current_chart.chart_info["id"])
	if chart_settings:
		if chart_settings[0]["hash"] == current_chart.hash:
			Global.push_console("Gameplay", "Found chart settings! Offset: %s" % chart_settings[0]["local_offset"])
			local_offset = chart_settings[0]["local_offset"]
	
	# add all hit objects to container
	for hobj in requested_chart.hit_objects:
		hit_object_container.add_child(hobj)
		if hobj is Spinner:
			hobj.on_finished.connect(apply_score)
	
	# set skip time to the first hit object's timing
	first_hobj_timing = current_chart.get_first_hitobject().timing
	
	last_hobj_timing = current_chart.hit_objects[0].timing
	if current_chart.hit_objects[0] is Spinner or current_chart.hit_objects[0] is Roll:
		last_hobj_timing += current_chart.hit_objects[0].length
	
	apply_skin(Global.get_root().current_skin)
	await get_tree().process_frame
	play_chart()

func play_chart() -> void:
	# error checks before starting to make sure chart is valid
	if current_chart == null:
		Global.push_console("Gameplay", "tried to play without a valid chart! abandoning...", 2)
		Global.get_root().change_to_results(score_instance)
		return
	
	if hit_object_container.get_child_count() <= 0:
		Global.push_console("Gameplay", "tried to play a chart without notes! abandoning...", 2)
		Global.get_root().change_to_results(score_instance)
		return

	current_play_offset = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	
	# delay the chart if first note is less than 2 seconds into the song
	var first_note_delay := 0.0
	var first_hit_object = current_chart.get_first_hitobject()
	
	if first_hit_object.timing < 2.0:
		first_note_delay = 2.0 - first_hit_object.timing
		current_play_offset -= first_note_delay
	
	start_time = Time.get_ticks_msec() / 1000.0 - current_play_offset
	playing = true
	
	# get first timing point and apply
	for i in range(hit_object_container.get_child_count() - 1, -1, -1):
		var hit_object = hit_object_container.get_child(i)
		if hit_object is TimingPoint:
			apply_timing_point(hit_object, start_time)
			break
	
	# ensure the current_time is set correctly and seek the music to it
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset - local_offset
	# if theres a delay before the audio starts, await it
	if current_time < 0:
		music_starting_timer.start(abs(current_time))
		await music_starting_timer.timeout
	music.play()

func restart_chart() -> void:
	playing = false
	music.stop()
	pause_overlay.visible = false
	
	active_finisher_note = null
	
	for hobj in hit_object_container.get_children():
		if not (hobj is TimingPoint):
			hobj.visible = true
			hobj.active = true
	
	score_instance.reset()
	
	await get_tree().process_frame
	play_chart()

func skip_intro() -> void:
	if current_time >= first_hobj_timing - 2.0:
		return
	var first_hit_object = current_chart.get_first_hitobject()
	
	start_time -= first_hit_object.timing - 2.0 - current_time
	music.seek(current_play_offset + first_hit_object.timing - 2.0)
	game_overlay.mascot.anim_start_time -= first_hit_object.timing - 2.0 - current_time

func change_pause_state(is_paused: bool) -> void:
	playing = not is_paused
	music.stream_paused = is_paused
	pause_overlay.visible = is_paused
	
	if is_paused:
		pause_time = Time.get_ticks_msec() / 1000.0
		music_starting_timer.stop()
		return
	
	# unpausing
	# add the time elapsed between pausing and unpausing, and compensate for audio delay
	start_time += (Time.get_ticks_msec() / 1000.0) - pause_time - AudioServer.get_time_to_next_mix()
	# ensure the current_time is set correctly and seek the music to it
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset - local_offset
	# if theres a delay before the audio starts, await it
	if current_time < 0:
		music_starting_timer.start(abs(current_time))
		await music_starting_timer.timeout
	music.play(current_time)

# -------- hit object checks --------

# give hitobject hit info, gets result, and applies score
# returns true if hit was used on a note, otherwise returns false
func hit_check(input_side: SIDE, is_input_kat: bool, target_hobj: HitObject ) -> bool:
	var hit_result: HitObject.HIT_RESULT = target_hobj.hit_check(current_time, input_side, is_input_kat)
	if hit_result != HitObject.HIT_RESULT.INVALID:
		if hit_result == HitObject.HIT_RESULT.F_INACC or hit_result == HitObject.HIT_RESULT.F_ACC:
			active_finisher_note = target_hobj
			current_hitsound_state = HITSOUND_STATES.FINISHER
		apply_score(target_hobj, hit_result)
	
	# if the hit object was a note, the hit was used. return true
	if target_hobj is Note:
		return true
	# if it was given to a spinner/roll, allow the input still be valid for another hit object
	return false

# finisher second hit check, returns if it was successful or not
func finisher_hit_check(input_side: SIDE, is_input_kat: bool) -> bool:
	if active_finisher_note:
		if abs(current_time - active_finisher_note.timing) < Global.INACC_TIMING:
			# in time
			if active_finisher_note.last_side_hit != input_side and active_finisher_note.is_kat == is_input_kat:
				# add score, reset finisher variables
				score_instance.add_finisher_score(active_finisher_note.timing - current_time)
				active_finisher_note = null
				current_hitsound_state = HITSOUND_STATES.NONE
				return true
	
	active_finisher_note = null 
	return false

func apply_score(target_hit_obj: HitObject, hit_result: HitObject.HIT_RESULT) -> void:
	if target_hit_obj is Note:
		score_instance.add_score(hit_result, target_hit_obj.timing - current_time)
	else:
		score_instance.add_score(hit_result)
	game_overlay.on_score_update(score_instance, target_hit_obj, hit_result, target_hit_obj.timing - current_time)

func apply_timing_point(timing_point: TimingPoint, current_time: float) -> void:
	current_bps = 60.0 / timing_point.bpm
	if timing_point.is_finisher != in_kiai:
		in_kiai = timing_point.is_finisher
	# roku note 2024-08-06
	# this can be implemented as a miss check
	game_overlay.update_mascot(Mascot.SPRITETYPES.KIAI if in_kiai else Mascot.SPRITETYPES.IDLE, 
								current_bps, 
								timing_point.timing - current_time)

# -------- feedback -------

# plays note audio
func play_audio(input_side: SIDE, is_input_kat: bool) -> void:
	var volume := 1.0
	var stream_audio = kat_audio if is_input_kat else don_audio
	match current_hitsound_state:
		HITSOUND_STATES.NONE:
			return
		HITSOUND_STATES.FINISHER:
			volume += 0.5
			stream_audio = katfinisher_audio if is_input_kat else donfinisher_audio
	
	# audio
	var stream_pos_offset = 250 if input_side == SIDE.RIGHT else -250
	var stream_position := Vector2(0, ProjectSettings.get_setting("display/window/size/viewport_height") / 2)
	stream_position.x = ProjectSettings.get_setting("display/window/size/viewport_width") / 2 + stream_pos_offset
	
	audio_queuer.play_audio(stream_audio, stream_position, volume)

func update_input_indicator(part_index: int) -> void:
	var indicator_target: Control = drum_indicator.get_children()[part_index]
	
	if drum_indicator_tweens[part_index]:
		drum_indicator_tweens[part_index].kill()
	
	drum_indicator_tweens[part_index] = create_tween()
	drum_indicator_tweens[part_index].tween_property(indicator_target, "modulate:a", 0.0, 0.2).from(1.0)

# -------- etc -------

func apply_skin(skin_manager: SkinManager) -> void:
	for hitobject in hit_object_container.get_children():
		hitobject.apply_skin(skin_manager)

	game_overlay.apply_skin(skin_manager)
	
	# set track textures
	if skin_manager.resources["texture"].keys().has("track"):
		$Track.texture = skin_manager.resources["texture"]["track"]
	if skin_manager.resources["texture"].keys().has("drum_indicator"):
		drum_indicator.texture = skin_manager.resources["texture"]["drum_indicator"]
	if skin_manager.resources["texture"].keys().has("drum_indicator_don"):
		drum_indicator.get_node("LeftDon").texture = skin_manager.resources["texture"]["drum_indicator_don"]
		drum_indicator.get_node("RightDon").texture = skin_manager.resources["texture"]["drum_indicator_don"]
	if skin_manager.resources["texture"].keys().has("drum_indicator_kat"):
		drum_indicator.get_node("LeftKat").texture = skin_manager.resources["texture"]["drum_indicator_kat"]
		drum_indicator.get_node("RightKat").texture = skin_manager.resources["texture"]["drum_indicator_kat"]
