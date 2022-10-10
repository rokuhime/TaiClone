extends Panel

onready var fileMenu := $HBoxContainer/File/PopupMenu as PopupMenu
onready var editMenu := $HBoxContainer/Edit/PopupMenu as PopupMenu
onready var viewMenu := $HBoxContainer/View/PopupMenu as PopupMenu
onready var helpMenu := $HBoxContainer/Help/PopupMenu as PopupMenu

func openMenu(menu) -> void:
	fileMenu.visible = menu == "file" and not fileMenu.visible
	viewMenu.visible = menu == "view" and not viewMenu.visible
	editMenu.visible = menu == "edit" and not editMenu.visible
	helpMenu.visible = menu == "help" and not helpMenu.visible

func openGithub(_dummy) -> void:
	OS.shell_open("https://github.com/FuzzyFus/TaiClone/tree/editor")
