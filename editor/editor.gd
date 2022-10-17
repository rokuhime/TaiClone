extends Control

onready var root_viewport := $"/root" as Root
onready var exTimeline := $Timeline/Ex as Node
onready var timeline := $Timeline/Container/Timeline as Slider
onready var timestamp := $Timeline/Container/Timestamp as Label
onready var debugText := $Debug as Label

onready var obj_container := $Main/Display/HitPoint/ObjectContainer
onready var hit_point := $Main/Display/HitPoint as Control
onready var bar_right := $Main/Display as Control

onready var select_shader : ShaderMaterial

onready var tglkat_tex : Texture
onready var tgldon_tex : Texture
onready var tglfin_on_tex : Texture
onready var tglfin_off_tex : Texture

onready var tglkat_but := $Tools/GridContainer/ToggleKat as Button
onready var tglfin_but := $Tools/GridContainer/ToggleFinisher as Button

onready var tools := $Tools as WindowDialog

onready var save_file := $SaveFile

var holding_ctrl := false
var holding_shift := false
var current_finisher := false
var current_kat := false

var currently_selected = []

var currentTool := 0
var cur_time := 0.0

var using_constant_sv := true

var interactingWithTimeline := false
var exTimelineFlip := false

const DEFAULT_VELOCITY := 1750.0
var current_velocity := 1.0

func _init() -> void:
	select_shader = load("res://editor/select_matt.tres") as ShaderMaterial
	tglkat_tex = load("res://temporary/editor/togglekat.png")
	tgldon_tex = load("res://temporary/editor/toggledon.png")
	tglfin_on_tex = load("res://temporary/editor/togglefinisher_on.png")
	tglfin_off_tex = load("res://temporary/editor/togglefinisher_off.png")

func _ready() -> void:
	$"LoadFile".loadChart("C:/Users/Fus/AppData/Roaming/Godot/app_userdata/TaiClone/Songs/1383022 Toze - Incendiary/Toze - Incendiary (9_9) [Burning].fus")
	print('a')

func _process(_delta: float) -> void:
	var prev_time := cur_time
	
	debugText.text = "currentTool: " + String(currentTool) + "\n" + "FPS: %s" % Engine.get_frames_per_second()
	
	if not interactingWithTimeline:
		if root_viewport.music.stream.get_length():
			timeline.value = root_viewport.music.get_playback_position() * 100.0 / root_viewport.music.stream.get_length()
		
		#timestamp schenanigans
		var time = root_viewport.music.get_playback_position()
		var mils = fmod(time,1)*1000
		var secs = fmod(time,60)
		var mins = fmod(time, 60*60) / 60
		timestamp.text = "%02d:%02d:%03d" % [mins,secs,mils]
		cur_time = time
	
	if prev_time != cur_time:
		for i in range(obj_container.get_child_count() - 1, -1, -1):
			## Comment
			var hit_object := obj_container.get_child(i) as HitObject

			hit_object.move(bar_right.rect_size.x, cur_time)

func timelineDrag(_dummy, isDragging) -> void:
	if isDragging == false:
		changeCurrentTime()
	interactingWithTimeline = isDragging

func changeTool(newTool) -> void:
	if newTool >= 0:
		currentTool = newTool;
	else:
		match newTool:
			-1:
				current_kat = !current_kat
				if current_kat:
					tglkat_but.icon = tglkat_tex 
				else:
					tglkat_but.icon = tgldon_tex 
			-2:
				current_finisher = !current_finisher
				if current_finisher:
					tglfin_but.icon = tglfin_on_tex 
				else:
					tglfin_but.icon = tglfin_off_tex

func changeExTimelineFlip() -> void:
	exTimelineFlip = not exTimelineFlip
	
	exTimeline.get_child(int(exTimelineFlip)).visible = true
	exTimeline.get_child(int(!exTimelineFlip)).visible = false

func changeCurrentTime() -> void:
	if timeline.value == 100.0:
		root_viewport.music.stop()
	else:
		cur_time = root_viewport.music.stream.get_length() * timeline.value / 100.0
		root_viewport.music.seek(cur_time)

func playPause() -> void:
	if root_viewport.music.playing:
		root_viewport.music.stop()
		cur_time = root_viewport.music.get_playback_position()
		return
	root_viewport.music.play(cur_time)

func stopMusic() -> void:
	root_viewport.music.stop()
	cur_time = 0.0

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
			# if editing objects...
			if currently_selected.size() != 0:
				var changingto := true

				# check if first note selected is/isnt kat
				if currently_selected[0].is_in_group("Note"):
					var first_select_obj := currently_selected[0] as Note
					changingto = !first_select_obj._is_kat

				for selection in currently_selected:
					if selection.is_in_group("Note"):
						selection.change_display(changingto, selection.finisher)
			else:
				changeTool(-1)

			
		# change tool: finisher
		if k_event.pressed and k_event.scancode == KEY_E:
			if currently_selected.size() != 0:
				var changingto := true

				# check if first note selected is/isnt kat
				if currently_selected[0].is_in_group("Note"):
					var first_select_obj := currently_selected[0] as Note
					print("changing to from true to ", !first_select_obj.finisher)
					changingto = !first_select_obj.finisher

				for selection in currently_selected:
					if selection.is_in_group("Note"):
						selection.change_display(selection._is_kat, changingto)
			else:
				changeTool(-1)

		# ctrl toggle
		if k_event.pressed and k_event.scancode == KEY_CONTROL:
			holding_ctrl = true
		if not k_event.pressed and k_event.scancode == KEY_CONTROL:
			holding_ctrl = false
		# shift toggle
		if k_event.pressed and k_event.scancode == KEY_SHIFT:
			holding_shift = true
		if not k_event.pressed and k_event.scancode == KEY_SHIFT:
			holding_shift = false
		

func topOptionSelected(id, type):
	match type:
		"file":
			match id:
				0:
					$FileDialog.visible = true
				2:
					save_file.save_map()
		"view":
			match id:
				0:
					tools.visible = true
	pass # Replace with function body.

func change_editor_speed(factor: float) -> void:
	if not using_constant_sv:
		return
	if factor == 0:
		current_velocity = 1
	else:
		current_velocity += factor
	
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		var hit_object := obj_container.get_child(i) as HitObject

		hit_object.speed = DEFAULT_VELOCITY * current_velocity
		hit_object.move(bar_right.rect_size.x, cur_time)
	
func change_playfield_view(is_constant: bool) -> void:
	using_constant_sv = is_constant
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var hit_object := obj_container.get_child(i) as HitObject


		if is_constant:
			hit_object.speed = DEFAULT_VELOCITY * current_velocity
		else:
			hit_object.speed = hit_object.actual_speed

		hit_object.move(bar_right.rect_size.x, cur_time)
	
	var width := hit_point.rect_size.x
	if is_constant:
		hit_point.anchor_left = 0.5
		hit_point.anchor_right = 0.5
		hit_point.margin_left = -width / 2
	else:
		hit_point.anchor_left = 0
		hit_point.anchor_right = 0
		hit_point.margin_left = 300
	hit_point.margin_right = hit_point.margin_left + width

func moused_over_object(event: InputEvent, obj: TextureRect) ->  void:
	## deals with selecting objects

	# make sure its a mouse input
	if event is InputEventMouseButton:
		if event.is_pressed():
			if not holding_ctrl:
				var was_selected: bool = currently_selected.has(obj) and currently_selected.size() == 1
				while currently_selected.size() != 0:
					remove_object(currently_selected[0])
				if was_selected:
					return

			elif currently_selected.has(obj):
				remove_object(obj)
				return

			obj.material = select_shader
			currently_selected.append(obj)

func change_object(initial_obj: Node, change: Array) -> void:
	var group = initial_obj.get_groups()[0]
	var obj
	#make sure its one of the valid groups and reassign it accordingly
	match group:
		"Note":
			obj = initial_obj as Note
			if change[0] == "kat":
				obj.change_display(change[1], obj.finisher)
			if change[0] == "finisher":
				obj.change_display(obj._is_kat, change[1])
			pass
		"Roll":
			obj = initial_obj as Roll
			pass
		"SpinnerWarn":
			pass
		_:
			return

func change_speed(new_speed: float) -> void:
	root_viewport.music.pitch_scale = new_speed

func remove_object(obj: Control) -> void:
	obj.material = null
	currently_selected.erase(obj)
