# res://scripts/database/database_manager.gd
extends Node

## SQLite Database Manager for local game data storage
## Handles game saves, player data, settings, and other persistent data

const DATABASE_PATH := "user://game_database.db"

var db
var db_name := DATABASE_PATH

signal database_ready()
signal save_completed(save_id: int)
signal save_loaded(save_data: Dictionary)
signal database_error(error_message: String)

func _ready() -> void:
	# Wait one frame for GDExtension to load
	await get_tree().process_frame
	initialize_database()

## Initialize SQLite database and create tables
func initialize_database() -> void:
	# Check if SQLite class is available
	if not ClassDB.class_exists("SQLite"):
		push_error("SQLite extension not loaded. Please enable godot-sqlite plugin in Project Settings.")
		database_error.emit("SQLite extension not available")
		return
	
	db = ClassDB.instantiate("SQLite")
	db.path = db_name
	
	if not db.open_db():
		push_error("Failed to open database at: " + db_name)
		database_error.emit("Failed to open database")
		return
	
	create_tables()
	apply_saved_audio_settings()
	database_ready.emit()
	print("Database initialized at: " + db_name)

## Create all necessary tables
func create_tables() -> void:
	# Game Saves table
	var save_table = """
	CREATE TABLE IF NOT EXISTS game_saves (
		save_id INTEGER PRIMARY KEY AUTOINCREMENT,
		save_name TEXT NOT NULL,
		player_name TEXT,
		level INTEGER DEFAULT 1,
		experience INTEGER DEFAULT 0,
		gold INTEGER DEFAULT 0,
		fish_caught INTEGER DEFAULT 0,
		total_playtime INTEGER DEFAULT 0,
		player_position_x REAL DEFAULT 0,
		player_position_y REAL DEFAULT 0,
		current_scene TEXT,
		save_date DATETIME DEFAULT CURRENT_TIMESTAMP,
		last_modified DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""
	db.query(save_table)
	
	# Player Inventory table
	var inventory_table = """
	CREATE TABLE IF NOT EXISTS player_inventory (
		inventory_id INTEGER PRIMARY KEY AUTOINCREMENT,
		save_id INTEGER NOT NULL,
		item_id TEXT NOT NULL,
		item_name TEXT NOT NULL,
		item_type TEXT,
		quantity INTEGER DEFAULT 1,
		equipped BOOLEAN DEFAULT 0,
		FOREIGN KEY (save_id) REFERENCES game_saves(save_id) ON DELETE CASCADE
	);
	"""
	db.query(inventory_table)
	
	# Fish Collection table
	var fish_table = """
	CREATE TABLE IF NOT EXISTS fish_collection (
		collection_id INTEGER PRIMARY KEY AUTOINCREMENT,
		save_id INTEGER NOT NULL,
		fish_id TEXT NOT NULL,
		fish_name TEXT NOT NULL,
		fish_size REAL,
		fish_weight REAL,
		rarity TEXT,
		value INTEGER DEFAULT 0,
		experience INTEGER DEFAULT 0,
		caught_date DATETIME DEFAULT CURRENT_TIMESTAMP,
		location TEXT,
		FOREIGN KEY (save_id) REFERENCES game_saves(save_id) ON DELETE CASCADE
	);
	"""
	db.query(fish_table)
	
	# Quests table
	var quests_table = """
	CREATE TABLE IF NOT EXISTS quests (
		quest_id INTEGER PRIMARY KEY AUTOINCREMENT,
		save_id INTEGER NOT NULL,
		quest_name TEXT NOT NULL,
		quest_description TEXT,
		quest_status TEXT DEFAULT 'active',
		progress INTEGER DEFAULT 0,
		goal INTEGER DEFAULT 1,
		reward_gold INTEGER DEFAULT 0,
		reward_experience INTEGER DEFAULT 0,
		FOREIGN KEY (save_id) REFERENCES game_saves(save_id) ON DELETE CASCADE
	);
	"""
	db.query(quests_table)
	
	# Settings table
	var settings_table = """
	CREATE TABLE IF NOT EXISTS game_settings (
		setting_id INTEGER PRIMARY KEY,
		master_volume REAL DEFAULT 1.0,
		music_volume REAL DEFAULT 0.8,
		sfx_volume REAL DEFAULT 0.8,
		ui_volume REAL DEFAULT 1.0,
		fullscreen BOOLEAN DEFAULT 0,
		vsync BOOLEAN DEFAULT 1,
		resolution_width INTEGER DEFAULT 1920,
		resolution_height INTEGER DEFAULT 1080,
		key_bindings TEXT DEFAULT '{}'
	);
	"""
	db.query(settings_table)
	
	# Insert default settings if not exists
	db.query("INSERT OR IGNORE INTO game_settings (setting_id) VALUES (1);")
	
	# Add key_bindings column if it doesn't exist (migration for existing databases)
	db.query("PRAGMA table_info(game_settings);")
	var has_key_bindings = false
	for column in db.query_result:
		if column.get("name", "") == "key_bindings":
			has_key_bindings = true
			break
	
	if not has_key_bindings:
		print("Adding key_bindings column to game_settings table...")
		db.query("ALTER TABLE game_settings ADD COLUMN key_bindings TEXT DEFAULT '{}';")
		print("key_bindings column added successfully")
	
	print("Database tables created successfully")

## Create a new game save
func create_save(save_name: String, player_name: String = "") -> int:
	var query = """
	INSERT INTO game_saves (save_name, player_name)
	VALUES (?, ?);
	"""
	db.query_with_bindings(query, [save_name, player_name])
	
	var save_id = db.last_insert_rowid
	save_completed.emit(save_id)
	print("Created new save: " + save_name + " (ID: " + str(save_id) + ")")
	return save_id

## Update an existing save
func update_save(save_id: int, save_data: Dictionary) -> bool:
	var fields = []
	var values = []
	
	for key in save_data.keys():
		fields.append(key + " = ?")
		values.append(save_data[key])
	
	fields.append("last_modified = CURRENT_TIMESTAMP")
	values.append(save_id)
	
	var query = "UPDATE game_saves SET " + ", ".join(fields) + " WHERE save_id = ?;"
	db.query_with_bindings(query, values)
	
	print("Updated save ID: " + str(save_id))
	return true

## Load a game save by ID
func load_save(save_id: int) -> Dictionary:
	var query = "SELECT * FROM game_saves WHERE save_id = ?;"
	db.query_with_bindings(query, [save_id])
	
	var result = db.query_result
	if result.size() > 0:
		save_loaded.emit(result[0])
		return result[0]
	
	push_error("Save not found: " + str(save_id))
	return {}

## Get all game saves
func get_all_saves() -> Array:
	db.query("SELECT * FROM game_saves ORDER BY last_modified DESC;")
	return db.query_result

## Delete a save
func delete_save(save_id: int) -> void:
	var query = "DELETE FROM game_saves WHERE save_id = ?;"
	db.query_with_bindings(query, [save_id])
	print("Deleted save ID: " + str(save_id))

## Add item to inventory
func add_inventory_item(save_id: int, item_id: String, item_name: String, item_type: String = "", quantity: int = 1) -> void:
	# Check if item already exists
	var check_query = "SELECT * FROM player_inventory WHERE save_id = ? AND item_id = ?;"
	db.query_with_bindings(check_query, [save_id, item_id])
	
	if db.query_result.size() > 0:
		# Update quantity
		var current_quantity = db.query_result[0]["quantity"]
		var update_query = "UPDATE player_inventory SET quantity = ? WHERE save_id = ? AND item_id = ?;"
		db.query_with_bindings(update_query, [current_quantity + quantity, save_id, item_id])
	else:
		# Insert new item
		var insert_query = """
		INSERT INTO player_inventory (save_id, item_id, item_name, item_type, quantity)
		VALUES (?, ?, ?, ?, ?);
		"""
		db.query_with_bindings(insert_query, [save_id, item_id, item_name, item_type, quantity])

## Get inventory for a save
func get_inventory(save_id: int) -> Array:
	var query = "SELECT * FROM player_inventory WHERE save_id = ?;"
	db.query_with_bindings(query, [save_id])
	return db.query_result

## Add caught fish to collection
func add_fish_to_collection(save_id: int, fish_data: Dictionary) -> void:
	var query = """
	INSERT INTO fish_collection (save_id, fish_id, fish_name, fish_size, fish_weight, rarity, value, experience, location)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
	"""
	db.query_with_bindings(query, [
		save_id,
		fish_data.get("fish_id", ""),
		fish_data.get("fish_name", "Unknown Fish"),
		fish_data.get("fish_size", 0.0),
		fish_data.get("fish_weight", 0.0),
		fish_data.get("rarity", "common"),
		fish_data.get("value", 0),
		fish_data.get("experience", 0),
		fish_data.get("location", "")
	])
	print("Added fish to collection: " + fish_data.get("fish_name", "Unknown"))

## Get fish collection for a save
func get_fish_collection(save_id: int) -> Array:
	var query = "SELECT * FROM fish_collection WHERE save_id = ? ORDER BY caught_date DESC;"
	db.query_with_bindings(query, [save_id])
	return db.query_result

## Delete a fish from collection (for selling)
func delete_fish_from_collection(collection_id: int) -> void:
	var query = "DELETE FROM fish_collection WHERE collection_id = ?;"
	db.query_with_bindings(query, [collection_id])
	print("Deleted fish from collection ID: " + str(collection_id))

## Get aggregated fish collection with counts
func get_fish_collection_summary(save_id: int) -> Array:
	var query = """
	SELECT 
		fish_name,
		rarity,
		COUNT(*) as count,
		AVG(value) as value,
		MAX(fish_size) as max_size,
		MAX(fish_weight) as max_weight
	FROM fish_collection 
	WHERE save_id = ? 
	GROUP BY fish_name, rarity
	ORDER BY rarity DESC, fish_name ASC;
	"""
	db.query_with_bindings(query, [save_id])
	return db.query_result

## Save settings to database
func save_settings(settings_data: Dictionary) -> void:
	var fields = []
	var values = []
	
	for key in settings_data.keys():
		fields.append(key + " = ?")
		values.append(settings_data[key])
	
	values.append(1)  # setting_id
	
	var query = "UPDATE game_settings SET " + ", ".join(fields) + " WHERE setting_id = ?;"
	db.query_with_bindings(query, values)
	print("Settings saved to database")

## Load settings from database
func load_settings() -> Dictionary:
	if db == null:
		push_warning("Database not initialized yet")
		return {}
	db.query("SELECT * FROM game_settings WHERE setting_id = 1;")
	if db.query_result.size() > 0:
		return db.query_result[0]
	return {}

## Apply saved audio settings to AudioServer
func apply_saved_audio_settings() -> void:
	var settings = load_settings()
	if settings.size() == 0:
		return
	
	# Apply master volume
	var master_volume = settings.get("master_volume", 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	print("[DatabaseManager] Applied Master volume: ", master_volume)
	
	# Note: UI volume will be applied by UIAudioManager when it initializes

## Add or update quest
func update_quest(save_id: int, quest_data: Dictionary) -> void:
	var check_query = "SELECT * FROM quests WHERE save_id = ? AND quest_name = ?;"
	db.query_with_bindings(check_query, [save_id, quest_data.get("quest_name", "")])
	
	if db.query_result.size() > 0:
		# Update existing quest
		var update_query = """
		UPDATE quests SET quest_status = ?, progress = ?, goal = ?
		WHERE save_id = ? AND quest_name = ?;
		"""
		db.query_with_bindings(update_query, [
			quest_data.get("quest_status", "active"),
			quest_data.get("progress", 0),
			quest_data.get("goal", 1),
			save_id,
			quest_data.get("quest_name", "")
		])
	else:
		# Insert new quest
		var insert_query = """
		INSERT INTO quests (save_id, quest_name, quest_description, quest_status, progress, goal, reward_gold, reward_experience)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?);
		"""
		db.query_with_bindings(insert_query, [
			save_id,
			quest_data.get("quest_name", ""),
			quest_data.get("quest_description", ""),
			quest_data.get("quest_status", "active"),
			quest_data.get("progress", 0),
			quest_data.get("goal", 1),
			quest_data.get("reward_gold", 0),
			quest_data.get("reward_experience", 0)
		])

## Get quests for a save
func get_quests(save_id: int, status: String = "") -> Array:
	var query = "SELECT * FROM quests WHERE save_id = ?"
	if status != "":
		query += " AND quest_status = '" + status + "'"
	query += ";"
	
	db.query_with_bindings(query, [save_id])
	return db.query_result

## Execute custom SQL query (use with caution)
func execute_query(query: String, bindings: Array = []) -> Array:
	if bindings.size() > 0:
		db.query_with_bindings(query, bindings)
	else:
		db.query(query)
	return db.query_result

## Close database connection
func close_database() -> void:
	if db:
		db.close_db()
		print("Database closed")

func _exit_tree() -> void:
	close_database()
