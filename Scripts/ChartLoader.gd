extends Node

onready var hitManager = get_node("../HitManager")

onready var noteObj = preload("res://Game/Objects/NoteObject.tscn")
onready var objContainer = get_node("../BarRight/HitPointOffset/ObjectContainers/NoteContainer")

onready var music = get_node("../Music")
onready var bg = get_node("../Background")

var currentChartData;

export var baseSVMultiplier : float = 1
#only used for osu beatmaps rn cuz its stinky lo
var mapSVMultiplier = 1

## finds origin of chart
#func findChartOrigin(path):
#	
#	return null;

# returns notes of a chart
func loadChart():
	#format it so that its just the notes
	var parsedChart = currentChartData.substr(currentChartData.find("[HitObjects]") + 13, currentChartData.length() - currentChartData.find("[HitObjects]"))
	#split by linebreak
	var parsedNotes = parsedChart.split("\n", false, 0)
	
	var noteCollection = []
	for noteData in parsedNotes:
		#make note object
		var note = {}

		#split up the line by commas
		var noteDataSection = noteData.split(",")
		#set timing
		note["time"] = noteDataSection[2].to_float() / 1000

		#all
		#noteDataSection[2] = timing
		#noteDataSection[3] = type
		#noteDataSection[4] = hitsound

		#slider
		#noteDataSection[noteDataSection.size() - 1]) = length (osupx)
		#noteDataSection[noteDataSection.size() - 2]) = repeats

		#spinner
		#noteDataSection[5] = length (time)

		#get note type
		match noteDataSection[3]:
			_:   #normal
				#is it d, k, finisher?
				match noteDataSection[4]:	
					"0": # d
						note["noteType"] = 0
						note["finisher"] = false
						pass 
					"4": # D
						note["noteType"] = 0
						note["finisher"] = true
						pass 

					"2": # k (whistle)
						note["noteType"] = 1
						note["finisher"] = false
						pass
					"6": # K (whistle)
						note["noteType"] = 1
						note["finisher"] = true  
						pass
					"8": # k (clap)
						note["noteType"] = 1
						note["finisher"] = false
						pass
					"12": # K (clap)
						note["noteType"] = 1
						note["finisher"] = true  
						pass 
		noteCollection.push_back(note)
	return noteCollection;

func processChart(data, filePath):
	#note speed is bpm * sv
	var currentSV = 1;
	var nextChange = null;
	
	var mapBaseSV;
	mapBaseSV = currentChartData.substr(currentChartData.find("SliderMultiplier:") + 17, currentChartData.length() - currentChartData.find("SliderTickRate:"))
	mapSVMultiplier = float(mapBaseSV) * baseSVMultiplier
	
	var curSVData = getSV(0)
	# current sv = 0, next change = 1
	
	for noteData in data:
		#fix to use special notes...
		
		#change sv if needed
		if (curSVData[1] != null):
			if (noteData["time"] >= curSVData[1]):
				curSVData = getSV(noteData["time"])
		#print("note made: t: " + str(noteData["time"]) + ", sv: " + str(curSVData[0]))
		var note = noteObj.instance()
		note.changeProperties(noteData["time"], curSVData[0] * mapSVMultiplier, noteData["noteType"], noteData["finisher"])
		objContainer.add_child(note)
		objContainer.move_child(note, 0)

func getSV(time):
	var bpm = null;
	var sv = null;
	var nextChange = null;
	
	var timingList = currentChartData.substr(currentChartData.find("[TimingPoints]") + 15)
	
	if (timingList.find("[Colours]") != -1):
		timingList = timingList.substr(0,timingList.find("[Colours]") - 3)
	else: 
		timingList = timingList.substr(0,timingList.find("[HitObjects]") - 3)
	
	timingList = timingList.split("\n", false, 0)

	for timing in timingList:
		timing = timing.split(",")
		# check for if sv/bpm not found yet
		if (sv == null && float(timing[1]) < 0):
			sv = (float(timing[1]) * -1) / 100
		elif (bpm == null && float(timing[1]) >= 0):
			bpm = 60000 / float(timing[1])
		
		elif (float(timing[0]) / 1000 <= time):
			#sv
			if(float(timing[1]) < 0):
				sv = (1 / (float(timing[1]) / -100))
			#bpm
			elif(float(timing[1]) >= 0):
				bpm = 60000 / float(timing[1])
				
		else:
			nextChange = float(timing[0]) / 1000
			break
			
	return [bpm * sv, nextChange]

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
		#print(data.find("[Metadata]"))
		var metadataSection = currentChartData.substr(currentChartData.find("[Metadata]") + 11)
		metadataSection = metadataSection.substr(0, metadataSection.find("[Difficulty]") - 2)
		#fix me hook hat, its not working for some reason
		metadataSection.split("\n", false, 0)
		result = metadataSection

	
	return result[5];
		
func loadAndProcessAll(filePath) -> void:
	currentChartData = tools.loadText(filePath)
	var chartData = loadChart()
	loadAndProcessBackground(filePath)
	wipePastChart()
	hitManager.reset()
	processChart(chartData, filePath)
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
		var allNotes = objContainer.get_children()
		for note in allNotes:
			note.activate()
		music.play()
	else: music.stop()

func wipePastChart() -> void:
	for note in objContainer.get_children():
		objContainer.remove_child(note)
		note.queue_free()