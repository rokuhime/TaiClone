extends Control

onready var root_viewport := $"/root" as Root
onready var exTimeline := $Timeline/Ex as Node
onready var timeline := $Timeline/Container/Timeline as Slider
onready var timestamp := $Timeline/Container/Timestamp as Label
onready var debugText := $Debug as Label

var currentTool := 0
var currentFinisher := false
var currentTime := 0.0

var interactingWithTimeline := false
var exTimelineFlip := false

func _process(_delta: float) -> void:
	debugText.text = "currentTool: " + String(currentTool)
	if not interactingWithTimeline:
		timeline.value = root_viewport.music.get_playback_position() * 100.0 / root_viewport.music.stream.get_length()
		
		#timestamp schenanigans
		var time = root_viewport.music.get_playback_position()
		var mils = fmod(time,1)*1000
		var secs = fmod(time,60)
		var mins = fmod(time, 60*60) / 60
		timestamp.text = "%02d:%02d:%03d" % [mins,secs,mils]

func timelineDrag(_dummy, isDragging) -> void:
	if isDragging == false:
		changeCurrentTime()
	interactingWithTimeline = isDragging

func changeTool(newTool) -> void:
	currentTool = newTool;

func changeExTimelineFlip() -> void:
	exTimelineFlip = not exTimelineFlip
	
	exTimeline.get_child(int(exTimelineFlip)).visible = true
	exTimeline.get_child(int(!exTimelineFlip)).visible = false

func changeCurrentTime() -> void:
	if timeline.value == 100.0:
		root_viewport.music.stop()
	else:
		currentTime = root_viewport.music.stream.get_length() * timeline.value / 100.0
		root_viewport.music.seek(currentTime)

func toggleMenu(menu) -> void:
	match menu:
		"a": 
			print("a")

func playPause() -> void:
	if root_viewport.music.playing:
		root_viewport.music.stop()
		currentTime = root_viewport.music.get_playback_position()
		return
	root_viewport.music.play(currentTime)

func stopMusic() -> void:
	root_viewport.music.stop()
	currentTime = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		## Comment
		var k_event := event as InputEventKey
		
		# pause/play
		if k_event.pressed and k_event.scancode == KEY_SPACE:
			playPause()
		# change tool: select
		if k_event.pressed and k_event.scancode == KEY_1:
			changeTool(0)
		# change tool: note
		if k_event.pressed and k_event.scancode == KEY_2:
			changeTool(1)
		# change tool: roll
		if k_event.pressed and k_event.scancode == KEY_3:
			changeTool(2)
		# change tool: spinner
		if k_event.pressed and k_event.scancode == KEY_4:
			changeTool(3)
			
		# change type: kat
		if k_event.pressed and k_event.scancode == KEY_W or k_event.scancode == KEY_R:
			print("changeToKat")
		# change tool: finisher
		if k_event.pressed and k_event.scancode == KEY_E:
			print("changeToFinisher")
