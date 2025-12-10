# res://scripts/pause_manager.gd
extends Node

## Pause Manager - Handles game pausing and settings access during gameplay

signal game_paused
signal game_resumed

var is_paused: bool = false
var previous_scene: String = ""
var can_pause: bool = true  # Can be disabled during cutscenes, etc.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and can_pause:
		# Don't allow ESC to resume if we're in settings screen
		var current_scene = get_tree().current_scene.scene_file_path
		if is_paused and current_scene == "res://scenes/ui/settings_screen.tscn":
			# ESC is disabled in settings - user must use back button
			return
		
		if is_paused:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	if is_paused or not can_pause:
		return
	
	is_paused = true
	previous_scene = get_tree().current_scene.scene_file_path
	game_paused.emit()
	
	print("[PauseManager] Game paused, opening settings from: ", previous_scene)
	
	# Open settings screen (paused mode will be set after scene loads)
	get_tree().change_scene_to_file("res://scenes/ui/settings_screen.tscn")

func resume_game() -> void:
	if not is_paused:
		return
	
	is_paused = false
	get_tree().paused = false
	game_resumed.emit()
	
	print("[PauseManager] Game resumed, returning to: ", previous_scene)
	
	# Return to previous scene
	if previous_scene != "" and previous_scene != "res://scenes/ui/settings_screen.tscn":
		get_tree().change_scene_to_file(previous_scene)
	else:
		# Default to title screen if no previous scene
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
	
	previous_scene = ""

func is_in_game() -> bool:
	var current = get_tree().current_scene.scene_file_path
	# Consider in-game if not in UI screens
	return not (current.begins_with("res://scenes/ui/title_screen") or 
				current.begins_with("res://scenes/ui/load_game") or
				current == "res://scenes/ui/settings_screen.tscn")

func set_can_pause(value: bool) -> void:
	can_pause = value
