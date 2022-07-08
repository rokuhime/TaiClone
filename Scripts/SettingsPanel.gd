extends Panel

onready var settingsButt = get_node("../SettingsButton")
onready var saveButt = get_node("SaveButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	settingsButt.connect("pressed", self, "toggleSettings")
	saveButt.connect("pressed", self, "saveSettings")
	pass # Replace with function body.

func toggleSettings():
	self.visible = !self.visible

func saveSettings():
	settings.saveConfig()
