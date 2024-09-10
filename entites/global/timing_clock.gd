class_name TimingClock
# using timestamps (seconds since the program has started running), 
# this will give accurate data on when the song started playing + the playback position
# far more precise and accurate than the built-in AudioStreamPlayer.get_playback_position()
# using BeatSyncronizers, you can get signals when a beat activates

var bps: float # beat length
var current_time: float
var start_time: float

# if pause_time == -1.0, assume its unpaused
var pause_time := -1.0
var child_beatsyncs := []

signal update_beatsyncs()
signal play_music(start_time: float)

# -------- system --------

func _process(delta) -> void:
	if pause_time:
		return
	
	# if the song hasnt started yet...
	if current_time < 0:
		current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset
		
		# if the next audio mix will put the time equal to or over when it needs to play...
		if current_time + AudioServer.get_time_to_next_mix() >= 0:
			play_music.emit(current_time + AudioServer.get_time_to_next_mix())
		return
	
	# song is playing, just update current_time and move on
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset

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

func get_beat_syncronizer(meter: int) -> BeatSyncronizer:
	var new_beatsync := BeatSyncronizer.new(self, meter)
	child_beatsyncs.append(new_beatsync)
	return new_beatsync

# -------- playback --------

func toggle_pause() -> void:
	# pause
	if pause_time == -1.0:
		pause_time = (Time.get_ticks_msec() / 1000.0)
		return
	
	# unpause
	# add the time that elapsed since pausing to the start_time
	start_time += (Time.get_ticks_msec() / 1000.0) - pause_time
	pause_time = -1.0
	
	# play_music at the current_time, not including offsets
	play_music.emit((Time.get_ticks_msec() / 1000.0) - start_time)
	
	# shift start_time forward to compensate for the mix
	start_time += AudioServer.get_time_to_next_mix()
	# set current_time to be accurate
	current_time = (Time.get_ticks_msec() / 1000.0) - start_time - Global.global_offset
	
	update_beatsyncs.emit()

func reset() -> void:
	bps = 0.0
	current_time = 0.0
	start_time = 0.0

	pause_time = -1.0
	child_beatsyncs = []
