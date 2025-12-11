# res://scripts/input_manager.gd
extends Node

## Input Manager - Loads and applies saved key bindings on startup

func _ready() -> void:
	# Wait for database to be ready
	if DatabaseManager.db == null:
		await DatabaseManager.database_ready
	
	load_key_bindings()

func load_key_bindings() -> void:
	var settings = DatabaseManager.load_settings()
	print("[InputManager] Loading key bindings...")
	print("[InputManager] Settings loaded: ", settings)
	
	if settings.size() == 0:
		print("[InputManager] No saved settings found, using default key bindings")
		return
	
	var bindings_json = settings.get("key_bindings", "{}")
	print("[InputManager] Key bindings JSON: ", bindings_json)
	print("[InputManager] JSON type: ", typeof(bindings_json))
	if bindings_json == null or bindings_json == "" or bindings_json == "{}":
		print("[InputManager] No saved key bindings found (null, empty, or default JSON), using defaults")
		return
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(bindings_json)
	
	if parse_result != OK:
		push_error("Failed to parse key bindings JSON")
		return
	
	var key_bindings = json.data
	
	if typeof(key_bindings) != TYPE_DICTIONARY:
		push_error("Key bindings data is not a dictionary")
		return
	
	# Apply saved bindings to InputMap
	for action in key_bindings.keys():
		var keycode = int(key_bindings[action])
		
		if InputMap.has_action(action):
			# Clear existing events
			InputMap.action_erase_events(action)
			
			# Add new event
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			InputMap.action_add_event(action, new_event)
			
			print("[InputManager] Loaded key binding for ", action, ": ", OS.get_keycode_string(keycode), " (keycode: ", keycode, ")")
	
	print("[InputManager] Key bindings loaded successfully")

func save_current_bindings() -> void:
	# Get current InputMap state
	var key_bindings = {}
	var actions = ["move_left", "move_right", "move_up", "move_down", "cast_line", "open_inventory", "open_shop"]
	
	for action in actions:
		if InputMap.has_action(action):
			var events = InputMap.action_get_events(action)
			if events.size() > 0:
				var event = events[0]
				if event is InputEventKey:
					key_bindings[action] = event.physical_keycode
	
	# Save to database
	var settings = {
		"key_bindings": JSON.stringify(key_bindings)
	}
	DatabaseManager.save_settings(settings)
	print("Key bindings saved")
