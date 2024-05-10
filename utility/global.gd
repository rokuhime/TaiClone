extends Node

const CONVERTED_CHART_FOLDER := "user://ConvertedCharts/"
const SUPPORTED_CHART_FILETYPES := ["tc", "osu", "tja"]
var chart_paths := []
const GAMEPLAY_KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

# consider; judgement timing array. you could have as many judgements as you want,
# going from most accurate to inaccurate
# allows finer judgements if wanted and such

const ACC_TIMING := 0.03
const INACC_TIMING := 0.07
var resolution_multiplier = 4.0

var offset := 0.0

func _init() -> void:
	DisplayServer.window_set_title("TaiClone " + ProjectSettings.get_setting("application/config/version"), 0)

func get_chart_folders() -> Array:
	return chart_paths + [CONVERTED_CHART_FOLDER]

#static func send_signal(signal_target: Node, signal_name: String, obj: Object, method: String) -> void:
	#if obj.connect(signal_name, signal_target, method):
		#push_warning("Attempted to connect %s %s." % [obj.get_class(), signal_name])
