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

#ive got to clean this sometime soon, gosh

# returns notes of a chart
func loadChart():
	#format it so that its just the notes
	var parsedChart = currentChartData.substr(currentChartData.find("[HitObjects]") + 13, 
						currentChartData.length() - currentChartData.find("[HitObjects]"))
	var mapBaseSV;
	mapBaseSV = float(currentChartData.substr(currentChartData.find("SliderMultiplier:") + 17, 
				currentChartData.length() - currentChartData.find("SliderTickRate:")))
	#split by linebreak
	var parsedNotes = parsedChart.split("\n", false, 0)
	#get timing points
	loadTiming()
	
	var noteCollection = []
	for noteData in parsedNotes:
		#make note object
		var note = {}
		
		#split up the line by commas
		var noteDataSection = noteData.split(",")
		#set timing
		note["time"] = noteDataSection[2].to_float() / 1000
		
		#get note type
		#osu keeps type as an int that references bytes
		
		if(1 << 3 & int(noteDataSection[3])): # spinner
			note["noteType"] = 2
			note["length"] = (float(noteDataSection[5]) / 1000) - note["time"]
			
		elif(1 << 1 & int(noteDataSection[3])): # roll
			# osu makes rolls/sliders really bloody stinky so this weird conversion is mandatory
			# essentially its a sliders pixel length (osupx), and the repeats of it (repeats, obvs)
			# so the length = osupx * repeats * 100 to get it into seconds essentially
			var osupx = float(noteDataSection[noteDataSection.size() - 1])
			var repeats = int(noteDataSection[noteDataSection.size() - 2])
			var svData = findTiming(note["time"])
			var beatLength = getBeatLength(note["time"])
			
			note["noteType"] = 3
			
			#finisher check
			if(1 << 2 & int(noteDataSection[4])): note["finisher"] = true
			else: note["finisher"] = false
			
			#fix me hook hat
			#its directly copied from the .osu file format from the osu wiki so i have 0 clue why this doesnt work :(
			#also has had vigorous testing, half the time it works half the time it doesnt
			#if anyone knows why id really really appreciate the help
			note["length"] = (((osupx * repeats) / (140 * svData[1]) * abs(beatLength)) / 1000)
			
		else: #normal note
			#finisher
			if(1 << 2 & int(noteDataSection[4])):
				note["finisher"] = true
			else:
				note["finisher"] = false
			
			#kat (whistle)
			if(1 << 1 & int(noteDataSection[4])):
				note["noteType"] = 1
			#kat (clap)
			elif(1 << 3 & int(noteDataSection[4])):
				note["noteType"] = 1
			#don
			else:
				note["noteType"] = 0
			
		noteCollection.push_back(note)
	return noteCollection;

func processChart(data):
	#note speed is bpm * sv
	#var currentSV = 1;
	#var nextChange = null;
	
	var mapBaseSV;
	mapBaseSV = currentChartData.substr(currentChartData.find("SliderMultiplier:") + 17, 
				currentChartData.length() - currentChartData.find("SliderTickRate:"))
	mapSVMultiplier = float(mapBaseSV)
	
	var curSVData = findTiming(0)
	# current sv = 0, current bpm = 1, next change = 2
	
	for noteData in data:
		#fix to use special notes...
		# check sv
		if (curSVData[2] != null): # if another bpm change exists...
			if (noteData["time"] >= curSVData[2]): #if the current note time is above/equal to next bpm change
				curSVData = findTiming(noteData["time"])
		
		#figure out what kind of note it is
		#normal note
		if (noteData["noteType"] == 0 || noteData["noteType"] == 1):
			var note = noteObj.instance()
			note.changeProperties(noteData["time"], (curSVData[0] * curSVData[1]) * mapSVMultiplier * baseSVMultiplier, 
													noteData["noteType"], noteData["finisher"])
			objContainer.get_node("NoteContainer").add_child(note)
			objContainer.get_node("NoteContainer").move_child(note, 0)
		
		#special note
		else:
			match(noteData["noteType"]):
				2: #spinner
					var note = spinWarnObj.instance()
					note.changeProperties(noteData["time"], (curSVData[0] * curSVData[1]) * mapSVMultiplier * baseSVMultiplier, 
															noteData["length"])
					objContainer.get_node("EtcContainer").add_child(note)
					objContainer.get_node("EtcContainer").move_child(note, 0)
					
				3: #roll
					var note = rollObj.instance()
					note.changeProperties(noteData["time"], (curSVData[0] * curSVData[1]) * mapSVMultiplier * baseSVMultiplier, 
															noteData["finisher"], noteData["length"], curSVData[0])
					objContainer.get_node("EtcContainer").add_child(note)
					objContainer.get_node("EtcContainer").move_child(note, 0)
					
				_: #emergency
					print("bad note at " + str(noteData["time"]) + "!")

func loadTiming():
	var timingArr = []
	var curSV = 0
	var timingList = currentChartData.substr(currentChartData.find("[TimingPoints]") + 15)
	
	if (timingList.find("[Colours]") != -1):
		timingList = timingList.substr(0,timingList.find("[Colours]") - 3)
	else: 
		timingList = timingList.substr(0,timingList.find("[HitObjects]") - 3)
	
	timingList = timingList.split("\n", false, 0)

	for timing in timingList:
		timing = timing.split(",") #split it to array
		
		#store timing points in svArr, 0 = timing 1 = type 2 = value
		if (float(timing[1]) >= 0): #if bpm
			timingArr.push_back([float(timing[0]) / 1000, 0, (60000 / float(timing[1]))])
		else: #if sv
			timingArr.push_back([float(timing[0]) / 1000, 1, (1 / (float(timing[1]) / -100))])	
	currentTimingData = timingArr;

func findTiming(time):
	var bpm = null;
	var sv = null;
	var nextChange = null;
	
	#get the closest sv/bpm to the timing
	for value in currentTimingData:
		if (value[0] <= time):
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
			if (value[1] == 0):
				bpm = value[2]
				break
	
	if sv == null: sv = 1;
	
	return [bpm, sv, nextChange]

func getBeatLength(time):
	var beatLength = null;
	
	var timingList = currentChartData.substr(currentChartData.find("[TimingPoints]") + 15)
	
	if (timingList.find("[Colours]") != -1):
		timingList = timingList.substr(0,timingList.find("[Colours]") - 3)
	else: 
		timingList = timingList.substr(0,timingList.find("[HitObjects]") - 3)
	
	timingList = timingList.split("\n", false, 0)

	for timing in timingList:
		timing = timing.split(",") #split it to array
		
		# check for if beatLength not found yet
		if (beatLength == null): #replaces beatLength with first beatLength first
			beatLength = float(timing[1])
		
		#checking for last timing before being called
		elif (float(timing[0]) / 1000 <= time):
			#sv
			beatLength = float(timing[1])
				
		else: #once all gained, get the next change time and stop looping
			break
	return beatLength

# returns song file of a chart
func loadAndProcessSong(filePath) -> void:
	#this is ugly im sorry
	#get audio file name and separate it in the file
	var audioFileName = currentChartData.substr(currentChartData.find("AudioFilename: ") + 15)
	audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
	
	#load audio file and apply to song player
	var audio_loader = AudioLoader.new()
	var folderPath = filePath.substr(0, filePath.find_last("/"))
	music.set_stream(audio_loader.loadfile(folderPath + "/" + audioFileName))

# returns text info of a chart
func loadMetadata():
	# replace with origin check later
	
	var result = {};
	#osu
	if true:
		var metadataSection = currentChartData.substr(currentChartData.find("[Metadata]") + 11)
		metadataSection = metadataSection.substr(0, metadataSection.find("[Difficulty]") - 2)
		metadataSection.split("\n", false, 0)
		result = metadataSection

	
	return result[5];
		
func loadAndProcessAll(filePath) -> void:
	currentChartData = tools.loadText(filePath)
	var chartData = loadChart()
	loadAndProcessBackground(filePath)
	wipePastChart()
	hitManager.reset()
	processChart(chartData)
	loadAndProcessSong(filePath)

func loadAndProcessBackground(filePath) -> void:
	var folderPath = filePath.substr(0, filePath.find_last("/"))
	var temp = currentChartData.substr(currentChartData.find("//Background and Video events"), currentChartData.length() - currentChartData.find("//Background and Video events"))
	temp = temp.substr(temp.find("\n") + 1, temp.length())
	temp = temp.substr(0, temp.find("\n"))
	temp = temp.substr(temp.find("\"") + 1, temp.find_last("\"") - (temp.find("\"") + 1))
	
	var image = Image.new()
	var err = image.load(folderPath + "/" + temp)
	if err != OK:
		# Failed
		pass
	else:
		var newtexture = ImageTexture.new()
		newtexture.create_from_image(image, 0)
		bg.texture = newtexture

func playChart() -> void:
	hitManager.reset()
	if (music.playing == false):
		var allNotes = []
		for subContainer in objContainer.get_children():
			for note in subContainer.get_children():
				allNotes.push_front(note)
		for note in allNotes:
			note.activate()
		music.play()
	else: music.stop()

func wipePastChart() -> void:
	for subContainer in objContainer.get_children():
		for note in subContainer.get_children():
			note.queue_free()
