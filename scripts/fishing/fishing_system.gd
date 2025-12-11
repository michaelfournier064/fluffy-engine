# res://scripts/fishing/fishing_system.gd
extends Node

## Core fishing mechanics system

signal fishing_started()
signal fish_hooked(fish_data: Dictionary)
signal fish_caught(fish_data: Dictionary)
signal fish_escaped()
signal fishing_ended()
signal minigame_started(sequence: Array)
signal minigame_key_pressed(correct: bool, progress: int, total: int)
signal minigame_failed()

# Fishing parameters
@export var cast_range: float = 150.0
@export var bite_time_min: float = 2.0
@export var bite_time_max: float = 8.0
@export var catch_window: float = 1.5  # Time to press button when fish bites
@export var minigame_sequence_length: int = 5  # Number of keys to press
@export var minigame_time_limit: float = 5.0  # Time to complete sequence

# Fish database - Matches the 5 "you caught" images
var fish_types: Array[Dictionary] = [
	{
		"id": "bass",
		"name": "Bass",
		"rarity": "common",
		"min_size": 30.0,
		"max_size": 60.0,
		"base_weight": 1.5,
		"value": 15,
		"experience": 25
	},
	{
		"id": "trout",
		"name": "Trout",
		"rarity": "common",
		"min_size": 25.0,
		"max_size": 70.0,
		"base_weight": 2.0,
		"value": 20,
		"experience": 30
	},
	{
		"id": "snapper",
		"name": "Snapper",
		"rarity": "uncommon",
		"min_size": 40.0,
		"max_size": 90.0,
		"base_weight": 3.0,
		"value": 35,
		"experience": 45
	},
	{
		"id": "tuna",
		"name": "Tuna",
		"rarity": "rare",
		"min_size": 60.0,
		"max_size": 150.0,
		"base_weight": 8.0,
		"value": 60,
		"experience": 80
	},
	{
		"id": "goldfish",
		"name": "Goldfish",
		"rarity": "legendary",
		"min_size": 30.0,
		"max_size": 50.0,
		"base_weight": 2.5,
		"value": 100,
		"experience": 150
	}
]

# Current fishing state
var is_fishing: bool = false
var waiting_for_bite: bool = false
var fish_hooked_active: bool = false
var current_fish: Dictionary = {}
var bite_timer: Timer
var catch_timer: Timer

# Minigame state
var minigame_active: bool = false
var key_sequence: Array = []
var current_key_index: int = 0
var minigame_timer: Timer
const AVAILABLE_KEYS = ["move_up", "move_down", "move_left", "move_right"]  # W, S, A, D

func _ready() -> void:
	setup_timers()

func setup_timers() -> void:
	bite_timer = Timer.new()
	bite_timer.one_shot = true
	bite_timer.timeout.connect(_on_bite_timer_timeout)
	add_child(bite_timer)

	catch_timer = Timer.new()
	catch_timer.one_shot = true
	catch_timer.timeout.connect(_on_catch_timer_timeout)
	add_child(catch_timer)

	minigame_timer = Timer.new()
	minigame_timer.one_shot = true
	minigame_timer.timeout.connect(_on_minigame_timeout)
	add_child(minigame_timer)

## Start fishing
func start_fishing() -> bool:
	if is_fishing:
		print("Already fishing, cannot start new session")
		return false

	# Reset all states before starting
	is_fishing = true
	waiting_for_bite = true
	fish_hooked_active = false
	minigame_active = false
	current_key_index = 0
	key_sequence.clear()
	current_fish = {}

	fishing_started.emit()

	# Random time until fish bites
	var bite_time = randf_range(bite_time_min, bite_time_max)
	bite_timer.start(bite_time)

	print("Fishing started! Waiting for bite... (%.1fs)" % bite_time)
	return true

## Stop fishing (called from player)
func end_fishing() -> void:
	stop_fishing()

## Internal stop fishing
func stop_fishing() -> void:
	# Always reset ALL states, even if already not fishing
	# This prevents getting stuck in broken states
	var was_fishing = is_fishing

	# Reset all fishing states
	is_fishing = false
	waiting_for_bite = false
	fish_hooked_active = false

	# Reset minigame states
	minigame_active = false
	current_key_index = 0
	key_sequence.clear()

	# Stop all timers
	bite_timer.stop()
	catch_timer.stop()
	minigame_timer.stop()

	# Clear current fish
	current_fish = {}

	# Only emit signal if we were actually fishing
	if was_fishing:
		fishing_ended.emit()

	print("Fishing ended - all states reset")

## Player attempts to reel in - starts the minigame
func attempt_catch() -> bool:
	if not fish_hooked_active or minigame_active:
		return false

	catch_timer.stop()
	start_minigame()
	return true

## Start the key sequence minigame
func start_minigame() -> void:
	minigame_active = true
	current_key_index = 0

	# Generate random sequence of keys
	key_sequence.clear()
	for i in range(minigame_sequence_length):
		key_sequence.append(AVAILABLE_KEYS[randi() % AVAILABLE_KEYS.size()])

	minigame_started.emit(key_sequence)
	minigame_timer.start(minigame_time_limit)
	print("Minigame started! Sequence: ", key_sequence)

## Check if player pressed the correct key
func check_key_input(action: String) -> bool:
	if not minigame_active:
		return false

	var expected_key = key_sequence[current_key_index]

	if action == expected_key:
		# Correct key!
		current_key_index += 1
		minigame_key_pressed.emit(true, current_key_index, key_sequence.size())
		print("Correct! Progress: %d/%d" % [current_key_index, key_sequence.size()])

		# Check if sequence completed
		if current_key_index >= key_sequence.size():
			complete_minigame_success()

		return true
	else:
		# Wrong key!
		minigame_key_pressed.emit(false, current_key_index, key_sequence.size())
		print("Wrong key! Expected: ", expected_key, " Got: ", action)
		fail_minigame()
		return false

## Minigame completed successfully
func complete_minigame_success() -> void:
	minigame_active = false
	minigame_timer.stop()

	# Success! Caught the fish
	var fish_data = generate_fish_data()
	fish_caught.emit(fish_data)

	# Add to database
	if GameState.current_save_id >= 0:
		DatabaseManager.add_fish_to_collection(GameState.current_save_id, fish_data)
		GameState.increment_fish_caught()
		GameState.add_experience(fish_data.experience)
		# Don't add gold here - player must sell fish in shop
		GameState.save_game_state()

	print("Caught: ", fish_data.fish_name, " (", fish_data.fish_size, "cm)")

	stop_fishing()

## Minigame failed
func fail_minigame() -> void:
	minigame_active = false
	minigame_timer.stop()
	minigame_failed.emit()
	fish_escaped.emit()
	print("Minigame failed!")
	stop_fishing()

## Generate random fish with stats
func generate_fish_data() -> Dictionary:
	var fish = select_random_fish()
	var size = randf_range(fish.min_size, fish.max_size)
	var weight = fish.base_weight * (size / fish.min_size)
	
	return {
		"fish_id": fish.id + "_" + str(randi()),
		"fish_name": fish.name,
		"fish_size": snappedf(size, 0.1),
		"fish_weight": snappedf(weight, 0.01),
		"rarity": fish.rarity,
		"location": "Lake",
		"value": fish.value,
		"experience": fish.experience
	}

## Select random fish based on rarity
## Applies legendary fish chance bonus from upgrades
func select_random_fish() -> Dictionary:
	var roll = randf()
	var rarity = ""

	# Base rarity chances: Common 60%, Uncommon 25%, Rare 13%, Legendary 2%
	# Legendary chance can be increased by shop upgrades
	var base_legendary_chance = 0.02  # 2% base
	var legendary_bonus = GameState.legendary_fish_chance_bonus / 100.0  # Convert % to decimal
	var legendary_chance = base_legendary_chance + legendary_bonus
	var legendary_threshold = 1.0 - legendary_chance

	# Determine rarity based on roll
	if roll < 0.60:
		rarity = "common"
	elif roll < 0.85:
		rarity = "uncommon"
	elif roll < legendary_threshold:
		rarity = "rare"
	else:
		rarity = "legendary"
		print("Legendary fish! (Chance: " + str(legendary_chance * 100) + "%)")

	# Filter fish by rarity
	var available_fish = fish_types.filter(func(f): return f.rarity == rarity)

	if available_fish.size() == 0:
		available_fish = fish_types.filter(func(f): return f.rarity == "common")

	return available_fish[randi() % available_fish.size()]

## Called when fish bites
func _on_bite_timer_timeout() -> void:
	if not is_fishing:
		return
	
	waiting_for_bite = false
	fish_hooked_active = true
	current_fish = select_random_fish()
	
	fish_hooked.emit(current_fish)
	catch_timer.start(catch_window)
	
	print("FISH ON! Press SPACE to reel in!")

## Called when catch window expires
func _on_catch_timer_timeout() -> void:
	if not fish_hooked_active:
		return

	# Player missed the catch window
	fish_hooked_active = false
	fish_escaped.emit()
	print("The fish got away...")

	stop_fishing()

## Called when minigame time runs out
func _on_minigame_timeout() -> void:
	if minigame_active:
		print("Minigame time expired!")
		fail_minigame()

## Get fish catalog for UI
func get_fish_catalog() -> Array[Dictionary]:
	return fish_types
