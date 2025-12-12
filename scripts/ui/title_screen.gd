extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var load_game_button: Button = %LoadGameButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	# Setup UI sounds for all buttons
	if has_node("/root/UIAudioManager"):
		get_node("/root/UIAudioManager").setup_all_buttons(self)
	
	# Clear pause state when on title screen
	if has_node("/root/PauseManager"):
		var pause_manager = get_node("/root/PauseManager")
		if pause_manager.is_paused:
			pause_manager.is_paused = false
			get_tree().paused = false
	
	# Connect button signals - use get_node with fallback for optional nodes
	if has_node("%NewGameButton"):
		new_game_button.pressed.connect(_on_new_game_pressed)
	if has_node("%LoadGameButton"):
		load_game_button.pressed.connect(_on_load_game_pressed)
	if has_node("%SettingsButton"):
		settings_button.pressed.connect(_on_settings_pressed)
	if has_node("%QuitButton"):
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Also support legacy play button if it exists
	if has_node("CenterContainer/PlayButton"):
		var play_btn = get_node("CenterContainer/PlayButton")
		play_btn.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed() -> void:
	# Legacy play button - start new game
	_on_new_game_pressed()

func _on_new_game_pressed() -> void:
	# For now, create a quick save and start game
	# You can enhance this with a name input dialog
	var save_name = "Save " + Time.get_datetime_string_from_system().replace(":", "-")
	GameState.create_new_game(save_name, "Player")

func _on_load_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/load_game_screen.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings_screen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
