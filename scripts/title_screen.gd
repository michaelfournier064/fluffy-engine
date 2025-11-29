# res://scripts/title_screen.gd
extends Node2D

@onready var quit_button:      CustomButton = $AspectRatioContainer/VBoxContainer/QuitGameButton
@onready var new_game_button:  CustomButton = $AspectRatioContainer/VBoxContainer/NewGameButton
@onready var load_game_button: CustomButton = $AspectRatioContainer/VBoxContainer/LoadGameButton
@onready var settings_button:  CustomButton = $AspectRatioContainer/VBoxContainer/SettingsButton

func _ready() -> void:
	quit_button.pressed_confirmed.connect(_on_quit_game_pressed)
	new_game_button.pressed_confirmed.connect(on_new_game_pressed)
	load_game_button.pressed_confirmed.connect(on_load_game_pressed)
	settings_button.pressed_confirmed.connect(on_settings_pressed)

func on_new_game_pressed() -> void: print("New Game Pressed")
func on_load_game_pressed() -> void: print("Load Game Pressed")
func on_settings_pressed(): 
	get_tree().change_scene_to_file("res://scenes/settings_screen.tscn")
func _on_quit_game_pressed() -> void: get_tree().quit()
