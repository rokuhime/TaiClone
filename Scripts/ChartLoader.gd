extends Node

onready var hitManager = get_node("../HitManager")

onready var noteObj = preload("res://Game/Objects/NoteObject.tscn")
onready var spinWarnObj = preload("res://Game/Objects/SpinnerWarnObject.tscn")
onready var rollObj = preload("res://Game/Objects/RollObject.tscn")
onready var objContainer = get_node("../BarRight/HitPointOffset/ObjectContainers")

onready var music = get_node("../Music")
onready var bg = get_node("../Background")

var currentChartData;
var currentTimingData;

export var baseSVMultiplier : float = 1
var mapSVMultiplier = 1

func findValue(key, section):
	for line in currentChartData[section]:
		if(line.begins_with(key)):
			return line.substr(key.length())

func loadAndProcessAll(filePath) -> void:
	var section = ""
	currentChartData = {section: []}
	for line in tools.loadText(filePath).split("\n",false):
		if line.begins_with("[") && line.ends_with("]"):
			section = line.substr(1, line.length() - 2)
			currentChartData[section] = []
		else:
			currentChartData[section].push_back(line)

	#loadAndProcessBackground
	var folderPath = filePath.get_base_dir()
	var events = currentChartData["Events"]
	var bgFileName = events[events.find("//Background and Video events") + 1]
	bgFileName = bgFileName.substr(bgFileName.find('"')+1,bgFileName.length()-bgFileName.rfind('"')+1)
	var image = Image.new()
	if image.load(folderPath + "/" + bgFileName) != OK:
		# Failed
		pass
	else:
		var newtexture = ImageTexture.new()
		newtexture.create_from_image(image, 0)
		bg.texture = newtexture

	#wipePastChart
	for subContainer in objContainer.get_children():
		for note in subContainer.get_children():
			note.queue_free()

	hitManager.reset()

	#loadAndProcessChart
	#get timing points
	currentTimingData = []
	for timing in currentChartData["TimingPoints"]:
		timing = timing.split(",") #split it to array
		#store timing points in svArr, 0 = timing 1 = type 2 = value
		if float(timing[1]) >= 0: #if bpm
			currentTimingData.push_back([float(timing[0]) / 1000, 0, 60000 / float(timing[1])])
		else: #if sv
			currentTimingData.push_back([float(timing[0]) / 1000, 1, -100 / float(timing[1])])
	#note speed is bpm * sv
	#var currentSV = 1;
	#var nextChange = null;
	mapSVMultiplier = float(findValue("SliderMultiplier:", "Difficulty"))
	var curSVData = findTiming(0)
	# current sv = 0, current bpm = 1, next change = 2
	for noteData in currentChartData["HitObjects"]:
		#make note object
		var note = {}
		#split up the line by commas
		noteData = noteData.split(",")
		#set timing
		note["time"] = float(noteData[2]) / 1000
		#fix to use special notes...
		# check sv
		if curSVData[2] != null && note["time"] >= curSVData[2]: # if another bpm change exists... and if the current note time is above/equal to next bpm change
			curSVData = findTiming(note["time"])
		#figure out what kind of note it is
		#osu keeps type as an int that references bytes
		if 1 << 3 & int(noteData[3]): # spinner
			note["noteType"] = 2
			note["length"] = float(noteData[5]) / 1000 - note["time"]
			var noteObject = spinWarnObj.instance()
			noteObject.changeProperties(note["time"], (curSVData[0] * curSVData[1]) * mapSVMultiplier * baseSVMultiplier, note["length"])
			objContainer.get_node("EtcContainer").add_child(noteObject)
			objContainer.get_node("EtcContainer").move_child(noteObject, 0)
		else:
			#finisher check
			note["finisher"] = bool(1 << 2 & int(noteData[4]))
			if 1 << 1 & int(noteData[3]): # roll
				# osu makes rolls/sliders really bloody stinky so this weird conversion is mandatory
				# essentially its a sliders pixel length (osupx), and the repeats of it (repeats, obvs)
				# so the length = osupx * repeats * 100 to get it into seconds essentially
				var osupx = float(noteData[noteData.size() - 1])
				var repeats = int(noteData[noteData.size() - 2])
				var svData = findTiming(note["time"])
				var beatLength = getBeatLength(note["time"])
				note["noteType"] = 3
				#fix me hook hat
				#its directly copied from the .osu file format from the osu wiki so i have 0 clue why this doesnt work :(
				#also has had vigorous testing, half the time it works half the time it doesnt
				#if anyone knows why id really really appreciate the help
				note["length"] = (((osupx * repeats) / (140 * svData[1]) * abs(beatLength)) / 1000)
				var noteObject = rollObj.instance()
				noteObject.changeProperties(note["time"], (curSVData[0] * curSVData[1]) * mapSVMultiplier * baseSVMultiplier, note["finisher"], note["length"], curSVData[0])
				objContainer.get_node("EtcContainer").add_child(noteObject)
				objContainer.get_node("EtcContainer").move_child(noteObject, 0)
			else: #normal note
				note["noteType"] = int(bool(((1 << 1) + (1 << 3)) & int(noteData[4])))
				var noteObject = noteObj.instance()
				noteObject.changeProperties(note["time"], (curSVData[0] * curSVData[1]) * mapSVMultiplier * baseSVMultiplier, note["noteType"], note["finisher"])
				objContainer.get_node("NoteContainer").add_child(noteObject)
				objContainer.get_node("NoteContainer").move_child(noteObject, 0)

	#loadAndProcessSong
	#get audio file name and separate it in the file
	#load audio file and apply to song player
	music.set_stream(AudioLoader.new().loadfile(folderPath + "/" + findValue("AudioFilename: ","General")))

func findTiming(time):
	var bpm = null;
	var sv = null;
	var nextChange = null;
	#get the closest sv/bpm to the timing
	for value in currentTimingData:
		if value[0] <= time:
			match value[1]:
				0: #bpm
					bpm = value[2]
				1: #sv
					sv = value[2]
		else:
			nextChange = value[0]
			break
	#make sure you get the first bpm for sure
	if bpm == null:
		for value in currentTimingData:
			if value[1] == 0:
				bpm = value[2]
				break
	if sv == null: sv = 1;
	return [bpm, sv, nextChange]

func getBeatLength(time):
	var beatLength = null;
	var timingList = currentChartData["TimingPoints"]
	for timing in timingList:
		timing = timing.split(",") #split it to array
		# check for if beatLength not found yet
		if beatLength == null: #replaces beatLength with first beatLength first
			beatLength = float(timing[1])
		#checking for last timing before being called
		elif (float(timing[0]) / 1000 <= time):
			#sv
			beatLength = float(timing[1])
		else: #once all gained, get the next change time and stop looping
			break
	return beatLength

func playChart() -> void:
	hitManager.reset()
	if music.playing: music.stop()
	else:
		var allNotes = []
		for subContainer in objContainer.get_children():
			for note in subContainer.get_children():
				allNotes.push_front(note)
		for note in allNotes:
			note.activate()
		music.play()
