extends Node

onready var noteObj = preload("res://Game/Objects/NoteObject.tscn")
onready var objContainer = get_node("../BarRight/HitPointOffset/ObjectContainers/NoteContainer")
onready var music = get_node("../Music")
onready var bg = get_node("../Background")

## finds origin of chart
#func findChartOrigin(path):
#	
#	return null;

# returns notes of a chart
func loadChart(data):
	#format it so that its just the notes
	var parsedChart = data.substr(data.find("[HitObjects]") + 13, data.length() - data.find("[HitObjects]"))
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
	for noteData in data:
		#fix to use special notes...
		var note = noteObj.instance()
		note.changeProperties(noteData["time"], 3, noteData["noteType"], noteData["finisher"])
		objContainer.add_child(note)
		#note.activate()

# returns song file of a chart
func loadAndProcessSong(data, filePath) -> void:
	#this is ugly im sorry
	#get audio file name and separate it in the file
	var audioFileName = data.substr(data.find("AudioFilename: ") + 15)
	audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
	
	#load audio file and apply to song player
	var audio_loader = AudioLoader.new()
	var folderPath = filePath.substr(0, filePath.find_last("/"))
	music.set_stream(audio_loader.loadfile(folderPath + "/" + audioFileName))
	#music.play()

# returns text info of a chart
func loadMetadata(data):
	# replace with origin check later
	
	var result = {};
	#osu
	if true:
		#print(data.find("[Metadata]"))
		var metadataSection = data.substr(data.find("[Metadata]") + 11)
		metadataSection = metadataSection.substr(0, metadataSection.find("[Difficulty]") - 2)
		#fix me hook hat, its not working for some reason
		metadataSection.split("\n", false, 0)
		result = metadataSection

	
	return result[5];
		
func loadAndProcessAll(filePath) -> void:
	var data = tools.loadText(filePath)
	var chartData = loadChart(data)
	loadAndProcessBackground(data, filePath)
	wipePastChart()
	processChart(chartData, filePath)
	loadAndProcessSong(data, filePath)

func loadAndProcessBackground(data, filePath) -> void:
	var folderPath = filePath.substr(0, filePath.find_last("/"))
	var temp = data.substr(data.find("//Background and Video events"), data.length() - data.find("//Background and Video events"))
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
