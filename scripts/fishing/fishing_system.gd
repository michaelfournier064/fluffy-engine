# res://scripts/fishing/fishing_system.gd
extends Node

## Core fishing mechanics system

signal fishing_started()
signal fish_hooked(fish_data: Dictionary)
signal fish_caught(fish_data: Dictionary)
signal fish_escaped()
signal fishing_ended()

# Fishing parameters
@export var cast_range: float = 150.0
@export var bite_time_min: float = 2.0
@export var bite_time_max: float = 8.0
@export var catch_window: float = 1.5  # Time to press button when fish bites
@export var struggle_duration: float = 3.0

# Fish database
var fish_types: Array[Dictionary] = [
	{
		"id": "bluegill",
		"name": "Bluegill",
		"rarity": "common",
		"min_size": 10.0,
		"max_size": 30.0,
		"base_weight": 0.3,
		"value": 5,
		"experience": 10
	},
	{
		"id": "bass",
		"name": "Largemouth Bass",
		"rarity": "common",
		"min_size": 30.0,
		"max_size": 60.0,
		"base_weight": 1.5,
		"value": 15,
		"experience": 25
	},
	{
		"id": "catfish",
		"name": "Catfish",
		"rarity": "uncommon",
		"min_size": 40.0,
		"max_size": 90.0,
		"base_weight": 3.0,
		"value": 30,
		"experience": 40
	},
	{
		"id": "pike",
		"name": "Northern Pike",
		"rarity": "uncommon",
		"min_size": 50.0,
		"max_size": 120.0,
		"base_weight": 5.0,
		"value": 50,
		"experience": 60
	},
	{
		"id": "trout",
		"name": "Rainbow Trout",
		"rarity": "rare",
		"min_size": 25.0,
		"max_size": 70.0,
		"base_weight": 2.0,
		"value": 40,
		"experience": 50
	},
	{
		"id": "salmon",
		"name": "Atlantic Salmon",
		"rarity": "rare",
		"min_size": 60.0,
		"max_size": 150.0,
		"base_weight": 8.0,
		"value": 80,
		"experience": 100
	},
	{
		"id": "goldfish",
		"name": "Golden Koi",
		"rarity": "legendary",
		"min_size": 30.0,
		"max_size": 50.0,
		"base_weight": 2.5,
		"value": 200,
		"experience": 200
	}
]

# Current fishing state
var is_fishing: bool = false
var waiting_for_bite: bool = false
var fish_hooked_active: bool = false
var current_fish: Dictionary = {}
var bite_timer: Timer
var catch_timer: Timer

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

## Start fishing
func start_fishing() -> bool:
	if is_fishing:
		return false
	
	is_fishing = true
	waiting_for_bite = true
	fishing_started.emit()
	
	# Random time until fish bites
	var bite_time = randf_range(bite_time_min, bite_time_max)
	bite_timer.start(bite_time)
	
	print("Fishing started! Waiting for bite...")
	return true

## Stop fishing (called from player)
func end_fishing() -> void:
	stop_fishing()

## Internal stop fishing
func stop_fishing() -> void:
	if not is_fishing:
		return
	
	is_fishing = false
	waiting_for_bite = false
	fish_hooked_active = false
	bite_timer.stop()
	catch_timer.stop()
	current_fish = {}
	fishing_ended.emit()
	print("Fishing ended")

## Player attempts to reel in
func attempt_catch() -> bool:
	if not fish_hooked_active:
		return false
	
	catch_timer.stop()
	
	# Success! Caught the fish
	var fish_data = generate_fish_data()
	fish_caught.emit(fish_data)
	
	# Add to database
	if GameState.current_save_id >= 0:
		DatabaseManager.add_fish_to_collection(GameState.current_save_id, fish_data)
		GameState.increment_fish_caught()
		GameState.add_experience(fish_data.experience)
		GameState.add_gold(fish_data.value)
		GameState.save_game_state()
	
	print("Caught: ", fish_data.fish_name, " (", fish_data.fish_size, "cm)")
	
	stop_fishing()
	return true

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
func select_random_fish() -> Dictionary:
	var roll = randf()
	var rarity = ""
	
	# Rarity chances: Common 60%, Uncommon 25%, Rare 13%, Legendary 2%
	if roll < 0.60:
		rarity = "common"
	elif roll < 0.85:
		rarity = "uncommon"
	elif roll < 0.98:
		rarity = "rare"
	else:
		rarity = "legendary"
	
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

## Get fish catalog for UI
func get_fish_catalog() -> Array[Dictionary]:
	return fish_types
