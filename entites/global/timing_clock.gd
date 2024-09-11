extends Node
class_name TimingClock
# using timestamps (seconds since the program has started running), 
# this will give accurate data on when the song started playing + the playback position
# far more precise and accurate than the built-in AudioStreamPlayer.get_playback_position()
# using BeatSyncronizers, you can get signals when a beat activates

var current_time: float
var start_time: float
# if pause_time == -1.0, its unpaused
var pause_time := 0.0

var bpm: float # beat length
var meter: int

# extras
var in_kiai := false
var local_offset := 0.0 # per-chart offset

# ensures play_music doesnt emit multiple times
var music_playing := false

var child_beatsyncs := []

@onready var info: Label = $Label

signal update_beatsyncs()
signal play_music(start_time: float)

# -------- system --------

func _process(delta) -> void:
	if Global.display_clocktiming_info and not info.visible:
		info.visible = true
	elif not Global.display_clocktiming_info and info.visible:
		info.visible = false
	
	if pause_time != -1.0:
		info.text = "start_time: %s\ncurrent_time: %s\npause_time: %s\nbpm: %s\nin_kiai: %s\nchild_beatsyncs: %s"  % [start_time, current_time, pause_time, bpm, in_kiai, child_beatsyncs]
		return
	
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset
	
	if not music_playing:
		try_play_music()
	
	info.text = "start_time: %s\ncurrent_time: %s\npause_time: %s\nbpm: %s\nin_kiai: %s\nchild_beatsyncs: %s"  % [start_time, current_time, pause_time, bpm, in_kiai, child_beatsyncs]

# -------- playback --------

# will delay the chart if first note is less than 2 seconds into the song
func start(start_offset: float) -> void:
	start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_output_latency() + start_offset
	# unpause
	pause_time = -1.0
	# ensure the current_time is set correctly before starting chart playback
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset - local_offset
	
	try_play_music()

func change_pause_state(is_paused) -> void:
	# pause
	if is_paused:
		music_playing = false
		pause_time = (Time.get_ticks_msec() / 1000.0)
		return
	
	# unpause
	# add the time that elapsed since pausing to the start_time
	start_time += (Time.get_ticks_msec() / 1000.0) - pause_time
	pause_time = -1.0
	
	# play_music at the current_time, not including offsets
	try_play_music()
	# set current_time to be accurate
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset - local_offset
	
	update_beatsyncs.emit()

# checks if (current_time without offsets) + (time to next mix) will be past 0, when the audio must be playing
func try_play_music() -> void:
	if current_time + Global.global_offset + AudioServer.get_time_to_next_mix() >= 0:
		music_playing = true
		play_music.emit(current_time + Global.global_offset + local_offset + AudioServer.get_time_to_next_mix())

# -------- data --------

func apply_timing_point(timing_point: TimingPoint) -> void:
	bpm = timing_point.bpm
	meter = timing_point.meter
	if timing_point.is_finisher != in_kiai:
		in_kiai = timing_point.is_finisher
	
	var beatsync_start := timing_point.timing
	if current_time < 0:
		while beatsync_start > current_time:
			beatsync_start -= get_bps() / 4.0
	
	for bs in child_beatsyncs:
		bs.next_beat_time = beatsync_start

func make_beat_syncronizer(meter := -1) -> BeatSyncronizer:
	var new_beatsync := BeatSyncronizer.new(self, meter)
	child_beatsyncs.append(new_beatsync)
	return new_beatsync

# -------- etc --------

func reset() -> void:
	current_time = 0.0
	start_time = 0.0
	pause_time = 0

	bpm = 0.0
	in_kiai = false
	local_offset = 0.0
	
	music_playing = false

func get_bps() -> float:
	var bps = 60.0 * meter / bpm
	return bps if bpm != 0 else 0
