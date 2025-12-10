# res://scripts/ui/load_game_screen.gd
extends Control

## Load Game screen for displaying and loading saved games

@onready var saves_container: VBoxContainer = %SavesContainer
@onready var back_button: Button = %BackButton
@onready var no_saves_label: Label = %NoSavesLabel

func _ready() -> void:
	# Setup UI sounds for all buttons
	if has_node("/root/UIAudioManager"):
		get_node("/root/UIAudioManager").setup_all_buttons(self)
	
	back_button.pressed.connect(_on_back_pressed)
	load_saves_list()

func load_saves_list() -> void:
	# Clear existing items
	for child in saves_container.get_children():
		child.queue_free()
	
	var saves = DatabaseManager.get_all_saves()
	
	if saves.size() == 0:
		no_saves_label.visible = true
		return
	
	no_saves_label.visible = false
	
	for save in saves:
		var save_item = create_save_item(save)
		saves_container.add_child(save_item)

func create_save_item(save_data: Dictionary) -> Control:
	var item = HBoxContainer.new()
	item.custom_minimum_size = Vector2(0, 60)
	
	# Save info container
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Save name
	var name_label = Label.new()
	name_label.text = save_data.get("save_name", "Unnamed Save")
	name_label.add_theme_font_size_override("font_size", 18)
	info_container.add_child(name_label)
	
	# Additional info
	var info_label = Label.new()
	var player_name = save_data.get("player_name", "")
	var level = save_data.get("level", 1)
	var fish_caught = save_data.get("fish_caught", 0)
	var last_modified = save_data.get("last_modified", "")
	
	info_label.text = "Player: %s | Level %d | Fish: %d | Last Played: %s" % [
		player_name if player_name != "" else "Unknown",
		level,
		fish_caught,
		last_modified.substr(0, 16) if last_modified != "" else "Unknown"
	]
	info_label.add_theme_font_size_override("font_size", 12)
	info_container.add_child(info_label)
	
	item.add_child(info_container)
	
	# Load button
	var load_btn = Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(100, 0)
	load_btn.pressed.connect(_on_load_save.bind(save_data.get("save_id", 0)))
	if has_node("/root/UIAudioManager"):
		get_node("/root/UIAudioManager").setup_button_sounds(load_btn)
	item.add_child(load_btn)
	
	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(100, 0)
	delete_btn.pressed.connect(_on_delete_save.bind(save_data.get("save_id", 0)))
	if has_node("/root/UIAudioManager"):
		get_node("/root/UIAudioManager").setup_button_sounds(delete_btn)
	item.add_child(delete_btn)
	
	return item

func _on_load_save(save_id: int) -> void:
	var save_data = DatabaseManager.load_save(save_id)
	if save_data.size() > 0:
		# Store current save ID globally
		GameState.current_save_id = save_id
		GameState.load_game_state(save_data)
		
		# Load the game scene
		var scene_path = save_data.get("current_scene", "res://scenes/world/main.tscn")
		if scene_path == null or scene_path == "":
			scene_path = "res://scenes/world/main.tscn"
		get_tree().change_scene_to_file(scene_path)

func _on_delete_save(save_id: int) -> void:
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to delete this save?"
	dialog.confirmed.connect(_confirm_delete.bind(save_id))
	add_child(dialog)
	dialog.popup_centered()

func _confirm_delete(save_id: int) -> void:
	DatabaseManager.delete_save(save_id)
	load_saves_list()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
