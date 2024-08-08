class_name ChartListing
extends Panel

static var chart_label = preload("res://entites/songselect/chart_label.tscn")
@onready var chart_label_container := $VBoxContainer/Labels

var chart: Chart
@onready var song_info_label := $VBoxContainer/SongInfo
@onready var chart_info_label := $VBoxContainer/ChartInfo

# used by songselect.gd
var movement_tween: Tween

signal selected_via_mouse

# roku note 2023-12-20
# for some reason, instancing this through SongListing.new(chart) deletes every single child node???????
# im assuming its because it extends Panel its using Panel.new(). no idea how to overwrite that as
# naming this function _init doesnt overwrite it. instantiate instead and manually invoke this
func init(wanted_chart: Chart):
	chart = wanted_chart

func _ready():
	if chart:
		song_info_label.text = chart.chart_info["song_title"] + " - " + chart.chart_info["song_artist"]
		chart_info_label.text = chart.chart_info["chart_title"] + " - " + chart.chart_info["chart_artist"]
		generate_chart_labels()
	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_echo() or event.button_index != MOUSE_BUTTON_LEFT or !event.is_pressed():
			return
		selected_via_mouse.emit()

func generate_chart_labels():
	# go through values
	# add relevant labels with add_chart_label(value, color)
	# spesifically looking at .osu converts, checvk if its even made for taiko to be able to add warning
	# OSU, CONVERT
	
	match chart.chart_info.get("origin", "").to_lower():
		"osu":
			add_chart_label(ChartLabelInfo.ORIGIN_OSU)
		"convert":
			add_chart_label(ChartLabelInfo.ORIGIN_CONVERT)
		_:
			add_chart_label(ChartLabelInfo.ORIGIN_UNKNOWN)

# uses ChartLabelInfo arrays to set info
func add_chart_label(label_info: Array):
	var new_label = chart_label.instantiate()
	new_label.get_node("Label").text = label_info[0]
	new_label.self_modulate = label_info[1]
	chart_label_container.add_child(new_label)
