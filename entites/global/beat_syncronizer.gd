class_name BeatSyncronizer

var clock: TimingClock
var divisor: int

var first_beat_time: float
var next_beat_time: float

signal beat()

# -------- system --------

func _init(new_timing_clock: TimingClock, new_divisor: int) -> void:
	clock = new_timing_clock
	divisor = new_divisor
	next_beat_time = clock.current_time + (clock.get_bps() / divisor)

func _process(delta):
	if clock.current_time >= next_beat_time:
		beat.emit()
		next_beat_time = clock.current_time + (clock.get_bps() / divisor) 
	pass

# -------- data --------

func update_from_timing_point(timing_point: TimingPoint) -> void:
	first_beat_time = timing_point.timing
