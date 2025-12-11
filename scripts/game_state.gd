# res://scripts/game_state.gd
extends Node

## Global game state manager
## Stores current game session data and interfaces with database

## Save data
var current_save_id: int = -1
var player_name: String = ""
var current_scene: String = ""

## Player stats
var player_level: int = 1
var player_experience: int = 0
var player_gold: int = 0
var fish_caught: int = 0
var total_playtime: int = 0
var player_position: Vector2 = Vector2.ZERO

## Player upgrades (purchased from shop)
var legendary_fish_chance_bonus: int = 0  # Additional % chance for legendary fish

## Player pets (purchased from shop)
var owned_pets: Array[String] = []  # List of pet names the player owns
var equipped_pet: String = ""  # Currently equipped pet (empty = none equipped)

signal game_saved()
signal game_loaded()

## Load game state from save data
func load_game_state(save_data: Dictionary) -> void:
	current_save_id = int(save_data.get("save_id", -1))
	var pname = save_data.get("player_name", "")
	player_name = str(pname) if pname != null else ""
	player_level = int(save_data.get("level", 1))
	player_experience = int(save_data.get("experience", 0))
	player_gold = int(save_data.get("gold", 0))
	fish_caught = int(save_data.get("fish_caught", 0))
	total_playtime = int(save_data.get("total_playtime", 0))
	player_position.x = float(save_data.get("player_position_x", 0.0))
	player_position.y = float(save_data.get("player_position_y", 0.0))
	var scene = save_data.get("current_scene", "")
	current_scene = str(scene) if scene != null else ""
	
	game_loaded.emit()
	print("Game state loaded for save ID: " + str(current_save_id))

## Save current game state to database
func save_game_state() -> void:
	if current_save_id < 0:
		push_error("No save ID set, cannot save game state")
		return
	
	# Update player position from the actual player node if available
	update_player_position()
	
	# Determine the correct scene to save
	var scene_to_save = get_tree().current_scene.scene_file_path
	
	# If we're in the settings screen, use the previous scene from PauseManager
	if scene_to_save == "res://scenes/ui/settings_screen.tscn":
		if has_node("/root/PauseManager"):
			var pause_manager = get_node("/root/PauseManager")
			if pause_manager.previous_scene != "" and pause_manager.previous_scene != "res://scenes/ui/settings_screen.tscn":
				scene_to_save = pause_manager.previous_scene
			else:
				# Default to main scene if no valid previous scene
				scene_to_save = "res://scenes/world/main.tscn"
	
	# Don't save UI scenes as the game scene
	if scene_to_save.begins_with("res://scenes/ui/"):
		scene_to_save = "res://scenes/world/main.tscn"
	
	var save_data = {
		"player_name": player_name,
		"level": player_level,
		"experience": player_experience,
		"gold": player_gold,
		"fish_caught": fish_caught,
		"total_playtime": total_playtime,
		"player_position_x": player_position.x,
		"player_position_y": player_position.y,
		"current_scene": scene_to_save
	}
	
	DatabaseManager.update_save(current_save_id, save_data)
	game_saved.emit()
	print("Game state saved to scene: ", scene_to_save)

## Create new game
func create_new_game(save_name: String, p_name: String = "") -> void:
	current_save_id = DatabaseManager.create_save(save_name, p_name)
	player_name = p_name
	player_level = 1
	player_experience = 0
	player_gold = 0
	fish_caught = 0
	total_playtime = 0
	player_position = Vector2.ZERO
	legendary_fish_chance_bonus = 0
	owned_pets.clear()
	equipped_pet = ""

	# Start new game
	get_tree().change_scene_to_file("res://scenes/world/main.tscn")

## Update player stats
func add_experience(amount: int) -> void:
	player_experience += amount
	check_level_up()

func add_gold(amount: int) -> void:
	player_gold += amount

func increment_fish_caught() -> void:
	fish_caught += 1

func check_level_up() -> void:
	var exp_needed = player_level * 100
	while player_experience >= exp_needed:
		player_level += 1
		player_experience -= exp_needed
		exp_needed = player_level * 100
		print("Level up! Now level " + str(player_level))

## Update player position from the actual player node in the scene
func update_player_position() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player is CharacterBody2D:
		player_position = player.position
		print("[GameState] Player position updated: ", player_position)

func reset_game_state() -> void:
	current_save_id = -1
	player_name = ""
	player_level = 1
	player_experience = 0
	player_gold = 0
	fish_caught = 0
	total_playtime = 0
	player_position = Vector2.ZERO
	current_scene = ""
	legendary_fish_chance_bonus = 0
	owned_pets.clear()
	equipped_pet = ""
