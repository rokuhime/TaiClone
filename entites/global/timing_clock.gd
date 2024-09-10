extends Node
class_name TimingClock
# using timestamps (seconds since the program has started running), 
# this will give accurate data on when the song started playing + the playback position
# far more precise and accurate than the built-in AudioStreamPlayer.get_playback_position()
# using BeatSyncronizers, you can get signals when a beat activates

var bps: float # beat length
var current_time: float
var start_time: float
var in_kiai := false
var music_playing := false

# if pause_time == -1.0, assume its unpaused
var pause_time := 0.0
var child_beatsyncs := []

@onready var info: Label = $Label

signal update_beatsyncs()
signal play_music(start_time: float)

# -------- system --------

func _process(delta) -> void:
	if pause_time != -1.0:
		info.text = "start_time: %s\ncurrent_time: %s\npause_time: %s\nbps: %s\nusic_playing: %s\nchild_beatsyncs: %s" % [start_time, current_time, pause_time, bps, music_playing, child_beatsyncs]
		return
	
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset
	# if the song hasnt started yet...
	if not music_playing:
		# if the next audio mix will put the time equal to or over when it needs to play...
		try_play_music()
	
	info.text = "start_time: %s\ncurrent_time: %s\npause_time: %s\nbps: %s\nusic_playing: %s\nchild_beatsyncs: %s" % [start_time, current_time, pause_time, bps, music_playing, child_beatsyncs]

# -------- playback --------

# will delay the chart if first note is less than 2 seconds into the song
func start(start_offset: float) -> void:
	start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_output_latency() + start_offset
	
	pause_time = -1.0
	# ensure the current_time is set correctly before starting chart playback
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset
	
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
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset
	
	update_beatsyncs.emit()

# -------- data --------

func apply_data(new_bps: float, new_start_time = null) -> TimingClock:
	bps = new_bps
	if typeof(new_start_time) == TYPE_FLOAT:
		start_time = new_start_time
	else:
		start_time = Time.get_ticks_msec() / 1000.0 + AudioServer.get_output_latency()
	
	if current_time + AudioServer.get_time_to_next_mix() >= 0:
		play_music.emit(current_time + AudioServer.get_time_to_next_mix())
	
	update_beatsyncs.emit(TimingPoint)
	return self

func apply_timing_point(timing_point: TimingPoint) -> void:
	bps = 60.0 / timing_point.bpm
	if timing_point.is_finisher != in_kiai:
		in_kiai = timing_point.is_finisher

func make_beat_syncronizer(meter: int) -> BeatSyncronizer:
	var new_beatsync := BeatSyncronizer.new(self, meter)
	child_beatsyncs.append(new_beatsync)
	return new_beatsync

# -------- etc --------

# checks if current_time - offsets + time to next mix will be when the audio plays
func try_play_music() -> void:
	if current_time + Global.global_offset + AudioServer.get_time_to_next_mix() >= 0:
		music_playing = true
		play_music.emit(current_time + Global.global_offset + AudioServer.get_time_to_next_mix())

func reset() -> void:
	bps = 0.0
	current_time = 0.0
	start_time = 0.0

	pause_time = 0
	child_beatsyncs = []
	music_playing = false
