extends HBoxContainer

onready var music = get_node("../../Music")

onready var input = get_node("LineEdit")
onready var loadButt = get_node("LoadButton")
onready var playButt = get_node("PlayButton")
onready var muteMToggle = get_node("MuteMToggle")
onready var muteHToggle = get_node("MuteHToggle")
onready var rateButt = get_node("PlayButton")
onready var rateInput = get_node("RateInput")
onready var autoToggle = get_node("AutoToggle")

onready var hitManager = get_node("../../HitManager")
onready var chartLoader = get_node("../../ChartLoader")
onready var debugTextThing = get_node("../debugtext")
onready var fpsText = get_node("../fpstext")

func _process(_delta):
	fpsText.text = "FPS: " + str(Engine.get_frames_per_second())
	
func _ready():
	loadButt.connect("pressed", self, "loadFunc")
	playButt.connect("pressed", get_node("../../ChartLoader"), "playChart")
	muteMToggle.connect("pressed", self, "toggleMMute")
	muteHToggle.connect("pressed", self, "toggleHMute")
	autoToggle.connect("pressed", self, "autoThing")
	rateButt.connect("pressed", self, "changeRate")
	
func loadFunc():
	debugTextThing.text = "Loading... [Checking File]"
	var rawFile = tools.loadText(tools.fwdToBackSlash(input.text))
	if rawFile != "" && rawFile != null:
		#var audioFileName = rawFile.substr(rawFile.find("AudioFilename: ") + 15)
		#audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
		#debugTextThing.text = chartLoader.loadMetadata(rawFile);
		debugTextThing.text = "Loading... [Reading File]"
		chartLoader.loadAndProcessAll(tools.fwdToBackSlash(input.text))
		debugTextThing.text = "Done!"
	else: debugTextThing.text = "Invalid file!"

func autoThing():
	hitManager.auto = autoToggle.pressed

func changeRate():
	var rate = float(rateInput.text)
	music.set_pitch_scale(rate)

func toggleMMute():
	if muteMToggle.pressed: music.volume_db = -100000
	else: music.volume_db = 0
	pass

func toggleHMute():
	var vol = 0;
	if muteHToggle.pressed: vol = -100000
	get_node("../../DrumInteraction/LeftDonAudio").volume_db = vol
	get_node("../../DrumInteraction/LeftKatAudio").volume_db = vol
	get_node("../../DrumInteraction/RightDonAudio").volume_db = vol
	get_node("../../DrumInteraction/RightKatAudio").volume_db = vol
	pass
