class_name Root
extends Viewport

var acc_timing: float
var global_offset: float
var inacc_timing: float


func _init() -> void:
	acc_timing = 0.06
	global_offset = 0
	inacc_timing = 0.145
