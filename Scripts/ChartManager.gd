extends Node

onready var noteObj = preload("res://Objects/NoteObject.tscn")
onready var chartHolder = get_node("../ChartHolder")
onready var hitNotes = get_node("../HitNotes")

var chartFilePath = "E:/Games/osu!/Songs/1385528 fhana - Aozora no Rhapsody (TV Size)"
var chartFileName = "fhana - Aozora no Rhapsody (TV Size) (driodx) [test].osu"

#var chartFilePath = "E:/Games/osu!/Songs/895493 keyyoung - Rainy Abyss"
#var chartFileName = "keyyoung - Rainy Abyss (Raphalge) [Inner Oni].osu"

#var chartFilePath = "E:/Games/osu!/Songs/1334132 Official HIGE DANdism - Bad for me (Dz'Xa's Amenpunk)"
#var chartFileName = "Official HIGE DANdism - Bad for me (Dz'Xa's Amenpunk) (KTYN) [Passing love].osu"

func _ready():
	#load file
	load_chart("osu", load_file(chartFilePath + "/" + chartFileName))
	
func load_file(file):
	var f = File.new()
	var fileInText = ""
	
	f.open(file, File.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		fileInText += line + "\n"
	f.close()
	return fileInText

func load_chart(chartType, chartText):
	match chartType:
		"osu":
			### AUDIO
			#this is ugly im sorry
			
			#get audio file name and separate it in the file
			var audioFileName = chartText.substr(chartText.find("AudioFilename: ") + 15)
			audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
			
			#load audio file and apply to song player
			var audio_loader = AudioLoader.new()
			var music = get_node("../SongManager/Song")
			music.set_stream(audio_loader.loadfile(chartFilePath + "/" + audioFileName))
			
			### CHART
			##format it so that its just the notes
			var parsedChart = chartText.substr(chartText.find("[HitObjects]") + 13, chartText.length() - chartText.find("[HitObjects]"))
			#split by linebreak
			var parsedNotes = parsedChart.split("\n", false, 0)

			for noteData in parsedNotes:
				#make note object
				var note = noteObj.instance()
				chartHolder.add_child(note)

				#split up the line by commas
				var noteDataSection = noteData.split(",")
				#set timing
				note.time = noteDataSection[2].to_float() / 1000

				#all
				#noteDataSection[2] = timing
				#noteDataSection[3] = type
				#noteDataSection[4] = hitsound
				
				#slider
				#noteDataSection[noteDataSection.length() - 1]) = length (osupx)
				#noteDataSection[noteDataSection.length() - 2]) = repeats
				
				#spinner
				#noteDataSection[5] = length (time)
				
				#get note type
				match noteDataSection[3]:
					"2": #slider
						note.noteType = 2
						note.makeSpecial("slider", noteDataSection[noteDataSection.length() - 1], noteDataSection[noteDataSection.length() - 2])
						pass
					"12": #spinner
						note.noteType = 3
						note.makeSpecial("spinner", noteDataSection[5], 0)
						pass

					_:   #normal
						#is it d, k, finisher?
						match noteDataSection[4]:	
							"0": # d
								note.noteType = 0
								pass 
							"4": # D
								note.noteType = 0
								note.finisher = true
								pass 

							"2": # k (whistle)
								note.noteType = 1
								pass
							"6": # K (whistle)
								note.noteType = 1
								note.finisher = true  
								pass
							"8": # k (clap)
								note.noteType = 1
								pass
							"12": # K (clap)
								note.noteType = 1
								note.finisher = true  
								pass 
				note.initialize()
			music.play()
