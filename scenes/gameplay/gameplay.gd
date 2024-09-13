class_name Gameplay
extends Control

# Core
var current_chart : Chart # this is a bit silly considering root.current_chart, but its used frequently enough to rationalize
var music: AudioStreamPlayer # TODO: change to Global.get_root().music
@onready var hit_object_container := $Track/HitPoint/HitObjectContainer

# UI
@onready var pause_overlay := $PauseOverlay
@onready var game_overlay := $GameOverlay as GameOverlay
@onready var audio_queuer := $AudioQueuer as AudioQueuer

@onready var drum_indicator: Node = $Track/DrumIndicator
var drum_indicator_tweens : Array = [null, null, null, null]

const SPINNER_GAMEPLAY_POS := Vector2(69, 425)

# Data
var enabled_mods := []
var score := ScoreData.new()

var clock: TimingClock
var first_hobj_timing := 0.0
var last_hobj_timing := 0.0

var playing := false
@onready var restart_timer: Timer = $RestartTimer
@onready var restart_overlay: ColorRect = $RestartOverlay
var restart_tween: Tween

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

# Offset
@onready var offset_panel := $OffsetPanel
const OFFSET_INCREASE := 0.005

# -------- system --------

func _ready() -> void:
	score.combo_break.connect(game_overlay.on_combo_break)
	pause_overlay.get_node("VBoxContainer/Quit").pressed.connect(
		Global.get_root().change_to_results.bind(score)
	)
	
	# TODO: replace this with it being provided from root
	apply_skin(Global.current_skin)
	
	music = Global.get_root().music
	music.stop()
	
	clock = Global.get_root().timing_clock
	for connection in clock.play_music.get_connections():
		clock.play_music.disconnect(connection["callable"])
	clock.play_music.connect(music.play)

func _process(_delta) -> void:
	if playing:
		# update progress bar
		game_overlay.update_progress(clock.current_time, first_hobj_timing, last_hobj_timing)
		
		# chart end check
		if clock.current_time >= last_hobj_timing + 1:
			Global.get_root().change_to_results(score)
		
		# move all hitobjects
		for hobj in hit_object_container.get_children():
			hobj.position.x = (hobj.speed * Global.resolution_multiplier) * (hobj.timing - clock.current_time) - (hobj.size.x / 2)
		
		# check for misses/timing activations
		for i in range(hit_object_container.get_child_count() - 1, -1, -1):
			var hit_object := hit_object_container.get_child(i) as HitObject
			
			# skip inactive hobjs, stop checking hobj's later than current_time
			if not hit_object.active:
				continue
			if hit_object.timing > clock.current_time:
				return
			
			# activating spinners
			if hit_object is Spinner and hit_object.hit_status == Spinner.hit_type.INACTIVE:
				# move interactive element out of hit object to make it still
				hit_object.remove_child(hit_object.spinner_gameplay)
				hit_object_container.get_parent().add_child(hit_object.spinner_gameplay)
				# set position
				hit_object.spinner_gameplay.position = SPINNER_GAMEPLAY_POS
				hit_object.transition_to_playable()
				return
			
			# auto
			if enabled_mods.has(ModPanel.MOD_TYPES.AUTO):
				if auto_hit_check(hit_object):
					return
			
			# actual miss check!!
			var miss_result := hit_object.miss_check(clock.current_time)
			if miss_result:
				if hit_object.is_in_group("Hittable"):
					if hit_object is Note:
						apply_score(hit_object, HitObject.HIT_RESULT.MISS)
					continue # could be more objects to miss (eg notes during a spinner)
				
				# if passing a timing point, apply it
				if hit_object is TimingPoint:
					apply_timing_point(hit_object)
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
	
	if Input.is_action_just_pressed("AddLocalOffset"):
		adjust_offset(OFFSET_INCREASE)
	
	if Input.is_action_just_pressed("RemoveLocalOffset"):
		adjust_offset(-OFFSET_INCREASE)
	
	if Input.is_action_just_pressed("SkipIntro") and playing:
		skip_intro()
	
	if Input.is_action_just_pressed("Retry"):
		restart_timer.start()
		
		if restart_tween:
			restart_tween.kill()
		restart_tween = restart_overlay.create_tween()
		restart_tween.tween_property(restart_overlay, "modulate:a", 1.0, restart_timer.wait_time)
	
	elif Input.is_action_just_released("Retry"):
		restart_timer.stop()
		
		if restart_tween:
			restart_tween.kill()
		restart_tween = Global.create_smooth_tween(restart_overlay, "modulate:a", 0.0, 0.1)
	
	# actual rhythm game input
	if event is InputEventKey or InputEventJoypadButton and event.is_pressed():
		if enabled_mods.has(ModPanel.MOD_TYPES.AUTO) or !playing:
			return
		
		# get rhythm gameplay input
		var pressed_inputs := get_pressed_gameplay_inputs()
		if pressed_inputs.is_empty(): 
			return
		
		# perform a hit check for each pressed input
		for input in pressed_inputs:
			# assume it will be a normal hitsound
			current_hitsound_state = HITSOUND_STATES.NORMAL
			
			var current_side_input = SIDE.LEFT if input.contains("Left") else SIDE.RIGHT
			var is_input_kat := false if input.contains("Don") else true
			
			# if the last hit note was a finisher, try to redirect input to a finisher_hit_check
			# if it fails, use it in a normal hitcheck
			if active_finisher_note:
				if finisher_hit_check(current_side_input, is_input_kat):
					activate_input_feedback(input) # update drum indicator
					continue
			
			var valid_length_hobjs = get_next_hittable_length_hobjs()
			if valid_length_hobjs:
				for hobj in valid_length_hobjs:
					hit_check(hobj, current_side_input, is_input_kat)
			
			var next_note = get_next_hittable_note()
			if next_note:
				hit_check(next_note, current_side_input, is_input_kat)
			
			# wait until now to play sound in order to ensure finishers update the current_hitsound_state
			activate_input_feedback(input) # play sound + update drum indicator

# -------- offset handling --------

func adjust_offset(value: float) -> float:
	clock.local_offset += value
	offset_panel.change_offset_text(clock.local_offset)
	return clock.local_offset

func save_local_offset(_active := false) -> void:
	# _active only here so on_active_changed can work properly
	if _active:
		return
	
	var chart_settings_entries: Array = Global.database_manager.get_db_entries_by_id("chart_settings", current_chart.chart_info["id"])
	if chart_settings_entries:
		chart_settings_entries[0]["local_offset"] = clock.local_offset
	else:
		chart_settings_entries.append({"id": current_chart.chart_info["id"], "hash": current_chart.hash, "local_offset": clock.local_offset, "collections": 0})
	Global.database_manager.update_db_entry("chart_settings", chart_settings_entries[0])
	Global.push_console("Gameplay", "Saved local offset: %s" % clock.local_offset)

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
			clock.local_offset = chart_settings[0]["local_offset"]
		else:
			clock.local_offset = 0
	
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
	
	apply_skin(Global.current_skin)
	play_chart()

func play_chart() -> void:
	music.stop()
	clock.reset()
	
	# error checks before starting to make sure chart is valid
	if current_chart == null:
		Global.push_console("Gameplay", "tried to play without a valid chart! abandoning...", 2)
		Global.get_root().change_to_results(score)
		return
	
	if hit_object_container.get_child_count() <= 0:
		Global.push_console("Gameplay", "tried to play a chart without notes! abandoning...", 2)
		Global.get_root().change_to_results(score)
		return

	# delay the chart if first note is less than 2 seconds into the song
	var start_offset := 0.0
	
	if first_hobj_timing < 2.0:
		start_offset = 2.0 - first_hobj_timing
	
	clock.start(start_offset)
	
	# get first timing point and apply
	for i in range(hit_object_container.get_child_count() - 1, -1, -1):
		var hit_object = hit_object_container.get_child(i)
		if hit_object is TimingPoint:
			apply_timing_point(hit_object)
			break
	
	playing = true

func restart_chart() -> void:
	score.retry_count += 1
	
	playing = false
	pause_overlay.visible = false
	
	active_finisher_note = null
	
	for hobj in hit_object_container.get_children():
		if hobj is Spinner:
			hobj.reset()
			continue
		
		if not (hobj is TimingPoint):
			hobj.visible = true
			hobj.active = true
	
	score.reset()
	game_overlay.update_visuals(score)
	
	if restart_tween:
		restart_tween.kill()
		restart_tween = restart_overlay.create_tween()
		restart_tween.tween_property(restart_overlay, "modulate:a", 0.0, 0.2)
	
	await get_tree().process_frame
	play_chart()
	if skip_intro:
		skip_intro()

func skip_intro() -> void:
	if clock.current_time >= first_hobj_timing - 2.0:
		return
	var first_hit_object = current_chart.get_first_hitobject()
	
	clock.start_time -= first_hit_object.timing - 2.0 - clock.current_time
	
	music.seek(first_hit_object.timing - 2.0)
	game_overlay.mascot.anim_start_time -= first_hit_object.timing - 2.0 - clock.current_time

func change_pause_state(is_paused: bool) -> void:
	clock.change_pause_state(is_paused)
	
	playing = not is_paused
	music.stream_paused = is_paused
	pause_overlay.visible = is_paused
	
	if is_paused:
		for hobj in hit_object_container.get_children():
			if hobj is Spinner and hobj.active:
				if not hobj.timer.paused:
					hobj.timer.paused = true
		return
	
	# unpausing
	for hobj in hit_object_container.get_children():
			if hobj is Spinner and hobj.active:
				if hobj.timer.paused:
					hobj.timer.paused = false

# -------- get hobj of type --------
# roku note 2024-08-27
# these function names suck!!!!!!!!!!!!!!!
# finish tidying up gameplay, then rename hit object class names to something more appropriate
# HitObject = GameplayObject or RhythmObject?

func get_next_hittable_note():
	for i in range(hit_object_container.get_child_count() - 1, -1, -1):
		var hit_object := hit_object_container.get_child(i) as HitObject
		# ensure hobj can be hit
		if hit_object != null and hit_object is Note:
			if hit_object.active:
				var start_time := hit_object.timing - Global.MISS_TIMING
				
				# start is later than the current time, no valid hitobject
				if start_time > clock.current_time:
					return
				return hit_object
	return null

# gets any active hit objects with length (drumrolls, spinners)
func get_next_hittable_length_hobjs():
	var valid_hobjs := []
	
	for i in range(hit_object_container.get_child_count() - 1, -1, -1):
		var hit_object := hit_object_container.get_child(i) as HitObject
		# ensure hobj can be hit
		if hit_object != null and hit_object.is_in_group("Hittable"):
			if hit_object.active:
				var start_time := hit_object.timing - Global.MISS_TIMING
				# hobj timing is later than the current time, stop checking
				if start_time > clock.current_time:
					break
				
				if not hit_object is Roll and not hit_object is Spinner:
					continue
				
				# if its a hobj with length, check the end time
				var end_time: float = hit_object.timing + hit_object.length + Global.INACC_TIMING
				
				# if the end times hasnt passed, return it
				if end_time >= clock.current_time:
					valid_hobjs.append(hit_object)
	
	return valid_hobjs

# -------- hit checks --------

# give hitobject hit info, gets result, and applies score
# returns true if hit was used on a note, otherwise returns false
func hit_check(target_hobj: HitObject, input_side: SIDE, is_input_kat: bool) -> bool:
	var hit_result: HitObject.HIT_RESULT = target_hobj.hit_check(clock.current_time, input_side, is_input_kat)
	
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
		if abs(clock.current_time - active_finisher_note.timing) < Global.INACC_TIMING:
			# in time
			if active_finisher_note.last_side_hit != input_side and active_finisher_note.is_kat == is_input_kat:
				# add score, reset finisher variables
				score.add_finisher_score(active_finisher_note.timing - clock.current_time)
				active_finisher_note = null
				current_hitsound_state = HITSOUND_STATES.NONE
				return true
	
	active_finisher_note = null 
	return false

# returns if hit was successful
func auto_hit_check(target_hobj: HitObject) -> bool:
	if target_hobj is Note:
		if hit_check(target_hobj, SIDE.LEFT, target_hobj.is_kat):
			play_audio(SIDE.LEFT, target_hobj.is_kat)
			current_hitsound_state = HITSOUND_STATES.NORMAL
			return true
	return false

func apply_timing_point(timing_point: TimingPoint) -> void:
	clock.apply_timing_point(timing_point)
	
	game_overlay.update_mascot(Mascot.SPRITETYPES.KIAI if timing_point.is_finisher else Mascot.SPRITETYPES.IDLE)

# -------- feedback --------

func apply_score(target_hit_obj: HitObject, hit_result: HitObject.HIT_RESULT) -> void:
	if target_hit_obj is Note:
		score.add_score(hit_result, target_hit_obj.timing - clock.current_time)
	else:
		score.add_score(hit_result)
	game_overlay.on_score_update(score, target_hit_obj, hit_result, clock.current_time)

# plays sound + activates drum indicator visual
func activate_input_feedback(input_name: String) -> void:
	update_input_indicator(Global.GAMEPLAY_KEYS.find(input_name))
	play_audio(
		SIDE.LEFT if input_name.contains("Left") else SIDE.RIGHT,
		true if input_name.contains("Kat") else false
	)

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

# -------- etc --------

func apply_skin(skin: SkinManager) -> void:
	for hitobject in hit_object_container.get_children():
		hitobject.apply_skin(skin)

	game_overlay.apply_skin(skin)
	
	# set track textures
	if skin.resource_exists("texture/track"):
		$Track.texture = skin.resources["texture"]["track"]
		
	if skin.resource_exists("texture/drum_indicator"):
		drum_indicator.texture = skin.resources["texture"]["drum_indicator"]
	if skin.resource_exists("texture/drum_indicator_don"):
		drum_indicator.get_node("LeftDon").texture = skin.resources["texture"]["drum_indicator_don"]
		drum_indicator.get_node("RightDon").texture = skin.resources["texture"]["drum_indicator_don"]
	if skin.resource_exists("texture/drum_indicator_kat"):
		drum_indicator.get_node("LeftKat").texture = skin.resources["texture"]["drum_indicator_kat"]
		drum_indicator.get_node("RightKat").texture = skin.resources["texture"]["drum_indicator_kat"]
	
	# TODO: THIS IS SO UGLY
	if skin.resource_exists("audio/don"):
		don_audio = skin.resources["audio"]["don"]
	if skin.resource_exists("audio/don_f"):
		donfinisher_audio = skin.resources["audio"]["don_f"]
	if skin.resource_exists("audio/kat"):
		kat_audio = skin.resources["audio"]["kat"]
	if skin.resource_exists("audio/kat_f"):
		katfinisher_audio = skin.resources["audio"]["kat_f"]

func get_pressed_gameplay_inputs() -> Array:
	var pressed_inputs := []
	for gameplay_input in Global.GAMEPLAY_KEYS:
		if Input.is_action_just_pressed(gameplay_input):
			pressed_inputs.append(gameplay_input)
	
	return pressed_inputs
