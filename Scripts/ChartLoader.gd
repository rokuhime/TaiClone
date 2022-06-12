extends Node

onready var noteObj = preload("res://Game/Objects/NoteObject.tscn")
onready var objContainer = get_node("../BarRight/ObjectContainers/NoteContainer")
onready var music = get_node("../Music")

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

	var noteCollection = {}
	for noteData in parsedNotes:
		#make note object
		var note

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
						pass 
					"4": # D
						note["noteType"] = 0
						note["finisher"] = true
						pass 

					"2": # k (whistle)
						note["noteType"] = 1
						pass
					"6": # K (whistle)
						note["noteType"] = 1
						note["finisher"] = true  
						pass
					"8": # k (clap)
						note["noteType"] = 1
						pass
					"12": # K (clap)
						note["noteType"] = 1
						note["finisher"] = true  
						pass 
		noteCollection.push_back(note)
	return noteCollection;

func processAll(data, filePath):
	for noteData in data:
		#fix to use special notes...
		var note = noteObj.instance()
		objContainer.get_node("EtcContainer").add_child(note)
		note.activate()
	
	loadAndProcessSong(data, filePath)

# returns song file of a chart
func loadAndProcessSong(data, filePath) -> void:
	#this is ugly im sorry
	
	#get audio file name and separate it in the file
	var audioFileName = data.substr(data.find("AudioFilename: ") + 15)
	audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
	
	#load audio file and apply to song player
	var audio_loader = AudioLoader.new()
	var folderPath = filePath.substr(0, filePath.find_last("/"))
	music.set_stream(audio_loader.loadfile(filePath + "/" + audioFileName))
	music.play()

# returns text info of a chart
func loadMetadata(data):
	# replace with origin check later
	
	var result = {};
	#osu
	if true:
		print(data.find("[Metadata]"))
		var metadataSection = data.substr(data.find("[Metadata]") + 11)
		metadataSection = metadataSection.substr(0, metadataSection.find("[Difficulty]") - 2)
		#fix me hook hat, its not working for some reason
		metadataSection.split("\n", false, 0)
		result = metadataSection

	
	return result[5];
		
func loadAndProcessAll(filePath) -> void:
	var data = tools.loadText(filePath)
	processAll(loadChart(data), filePath)

#func load_chart(chartType, chartText):
#	match chartType:
#		"osu":
#			### AUDIO
#			#this is ugly im sorry
#
#			#get audio file name and separate it in the file
#			var audioFileName = chartText.substr(chartText.find("AudioFilename: ") + 15)
#			audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
#
#			#load audio file and apply to song player
#			var audio_loader = AudioLoader.new()
#			var music = get_node("../SongManager/Song")
#			music.set_stream(tools.loadAudio((settings.ChartPath + "/" + audioFileName)))
#
#			### CHART
#			#get bpm
#			######## edit for adding changing bpm maps!!!
#			var parsedTimingPoints = chartText.substr(chartText.find("[TimingPoints]") + 15, chartText.find("[HitObjects]"))
#			var parsedTiming = parsedTimingPoints.split("\n", false, 0)
#			for timingData in parsedTiming:
#				var timingDataSection = timingData.split(",")
##				if timingDataSection[6] == "1": # bpm change
##					songManager.bpm = float(timingDataSection[6])
##					break
##				else: #sv change
##					pass
#
#			#format it so that its just the notes
#			var parsedChart = chartText.substr(chartText.find("[HitObjects]") + 13, chartText.length() - chartText.find("[HitObjects]"))
#			#split by linebreak
#			var parsedNotes = parsedChart.split("\n", false, 0)
#
#			for noteData in parsedNotes:
#				#make note object
#				var note = noteObj.instance()
#
#				#split up the line by commas
#				var noteDataSection = noteData.split(",")
#				#set timing
#				note.time = noteDataSection[2].to_float() / 1000
#
#				if (noteDataSection[3] != "2" && noteDataSection[3] != "12"): chartHolder.get_node("Notes").add_child(note)
#				else: chartHolder.get_node("Special").add_child(note)
#
#				#all
#				#noteDataSection[2] = timing
#				#noteDataSection[3] = type
#				#noteDataSection[4] = hitsound
#
#				#slider
#				#noteDataSection[noteDataSection.size() - 1]) = length (osupx)
#				#noteDataSection[noteDataSection.size() - 2]) = repeats
#
#				#spinner
#				#noteDataSection[5] = length (time)
#
#				#get note type
#				match noteDataSection[3]:
#					"2": #slider
#						note.noteType = 2
#						note.makeSpecial("slider", float(noteDataSection[noteDataSection.size() - 1]), float(noteDataSection[noteDataSection.size() - 2]))
#						pass
#					"12": #spinner
#						note.noteType = 3
#						note.makeSpecial("spinner", noteDataSection[5], 0)
#						pass
#
#					_:   #normal
#						#is it d, k, finisher?
#						match noteDataSection[4]:	
#							"0": # d
#								note.noteType = 0
#								pass 
#							"4": # D
#								note.noteType = 0
#								note.finisher = true
#								pass 
#
#							"2": # k (whistle)
#								note.noteType = 1
#								pass
#							"6": # K (whistle)
#								note.noteType = 1
#								note.finisher = true  
#								pass
#							"8": # k (clap)
#								note.noteType = 1
#								pass
#							"12": # K (clap)
#								note.noteType = 1
#								note.finisher = true  
#								pass 
#				note.initialize()
#			music.play()
