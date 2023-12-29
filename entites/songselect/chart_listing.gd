class_name ChartListing
extends Panel

var chart: Chart

@onready var song_info_label := $VBoxContainer/SongInfo
@onready var chart_info_label := $VBoxContainer/ChartInfo

# used by songselect.gd
var movement_tween: Tween
var selected := false

# roku note 2023-12-20
# for some reason, instancing this through SongListing.new(chart) deletes every single child node???????
# im assuming its because it extends Panel its using Panel.new(). no idea how to overwrite that as
# naming this function _init doesnt overwrite it
# instantiate instead and manually invoke this
func init(wanted_chart: Chart):
	chart = wanted_chart

func _ready():
	if chart:
		song_info_label.text = chart.chart_info["Song_Title"] + " - " + chart.chart_info["Song_Artist"]
		chart_info_label.text = chart.chart_info["Chart_Title"] + " - " + chart.chart_info["Chart_Artist"]
	else:
		print("wtf!@!!!")
	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_echo() or event.button_index != MOUSE_BUTTON_LEFT or !event.is_pressed():
			return
		
		if not selected:
			selected = true
			var a = get_tree().get_first_node_in_group("SongSelect")
			get_tree().get_first_node_in_group("SongSelect").select_listing(self)
		elif selected:
			print("ChartListing: Changing to gameplay with chart ", chart.chart_info["Song_Title"])
			get_tree().get_first_node_in_group("SongSelect").transition_to_gameplay()
			pass
		
