extends HBoxContainer

onready var input = get_node("LineEdit")
onready var loadButt = get_node("LoadButton")
onready var playButt = get_node("PlayButton")

onready var chartLoader = get_node("../ChartLoader")
onready var debugTextThing = get_node("../debugtext")
onready var fpsText = get_node("../fpstext")

func _process(delta):
	fpsText.text = "FPS: " + str(Engine.get_frames_per_second())
	
func _ready():
	loadButt.connect("pressed", self, "loadFunc")
	playButt.connect("pressed", get_node("../ChartLoader"), "playFunc")
	
func loadFunc():
	var rawFile = tools.loadText(tools.fwdToBackSlash(input.text))
	if rawFile.length() > 0:
		var audioFileName = rawFile.substr(rawFile.find("AudioFilename: ") + 15)
		audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
		#debugTextThing.text = chartLoader.loadMetadata(rawFile);
		var fileDir = tools.fwdToBackSlash(input.text)
		fileDir = fileDir.substr(0, (fileDir.length() - fileDir.find_last("/") - 3))
		chartLoader.loadAndProcessAll(rawFile)
