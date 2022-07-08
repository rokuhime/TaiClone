extends Node

var configPath = "res://config.ini"
var configFile

var keybinds = {}

func _ready():
	configFile = ConfigFile.new()
	if configFile.load(configPath) == OK:
		for key in configFile.get_section_keys("Keybinds"):
			var key_value = configFile.get_value("Keybinds", key)
			
			keybinds[key] = key_value
		loadKeybinds()
	else:
		print("config not found!")

func loadKeybinds():
	for key in keybinds.keys():
		var actionList = InputMap.get_action_list(key)
		if !actionList.empty():
			InputMap.action_erase_event(key, actionList[0])
		var newKey = InputEventKey.new()
		newKey.set_scancode(keybinds[key])
		InputMap.action_add_event(key, newKey)

func saveConfig():
	print("saving config...")
	for key in keybinds.keys():
		var key_value = keybinds[key]
		configFile.set_value("Keybinds", key, key_value)
	configFile.save(configPath)
	print("saved!")
