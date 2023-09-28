extends Node

const VERSION := "v0.0.1 - how many branches does it take to screw in a lightbulb?"

enum NOTETYPE {TIMING_POINT, BARLINE, DON, KAT, ROLL, SPINNER}

var expiring_audio = preload("res://scenes/global/expiring_audio.tscn")
const ACC_TIMING := 0.03
const INACC_TIMING := 0.07

var offset := 0.0

func _init() -> void:
	DisplayServer.window_set_title("TaiClone " + VERSION, 0)

# made for timer class
func format_time(time) -> String:
	if time <= 0:
		return "00:00.00"
	var minute : int = floor(time / 60)
	var second : int = fmod(time, 60)
	var millisecond : int = fmod((time * 1000), 1000) / 10
	var new_str := "%02d:%02d.%02d" % [minute, second, millisecond]
	return new_str

func load_image(file_path: String, crop_transparent := true) -> Texture:
	var image = Image.load_from_file(file_path)
	
	# crops image to first visible pixels on every side, helps minimize small note skins
	if crop_transparent and not image.is_invisible():
		image = image.get_region(image.get_used_rect())
		
	var texture = ImageTexture.create_from_image(image)
	
	return texture
