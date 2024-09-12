extends Node
class_name BeatSyncronizer

var clock: TimingClock
var meter := -1 # -1 = get from clock

var next_beat_time := 0.0

signal beat()

# -------- system --------

func _init(new_timing_clock: TimingClock, new_meter: int) -> void:
	clock = new_timing_clock
	meter = new_meter

func _process(_delta):
	if clock.current_time >= next_beat_time:
		beat.emit()
		next_beat_time += clock.get_bps() / 4.0

func _notification(what):
	if (what == NOTIFICATION_PREDELETE):
		clock.child_beatsyncs.erase(self)
