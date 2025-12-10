# res://scripts/ui/settings_screen.gd
extends Control

## Settings screen for audio controls

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var ui_slider: HSlider = %UiSlider

@onready var master_value_label: Label = %MasterValueLabel
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var ui_value_label: Label = %UiValueLabel

@onready var back_button: Button = %BackButton
@onready var apply_button: Button = %ApplyButton
@onready var controls_container: VBoxContainer = %ControlsContainer
@onready var reset_controls_button: Button = %ResetControlsButton

var tab_container: TabContainer = null

# Game tab (created dynamically when paused)
var game_tab: VBoxContainer = null
var resume_game_button: Button = null
var save_game_button: Button = null
var quit_to_menu_button: Button = null

# Control mapping
const CONTROL_ACTIONS = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"move_up": "Move Up",
	"move_down": "Move Down",
	"cast_line": "Cast/Reel Line",
	"attack": "Attack",
	"open_inventory": "Open Inventory"
}

var control_buttons: Dictionary = {}
var waiting_for_input: String = ""
var has_unsaved_changes: bool = false
var original_settings: Dictionary = {}
var original_key_bindings: Dictionary = {}

func _ready() -> void:
	# Ensure settings screen is always interactable even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get TabContainer (may not exist if using unique name or different scene structure)
	tab_container = get_node_or_null("%TabContainer")
	if tab_container == null:
		tab_container = find_child("TabContainer", true, false)
	
	# Set tree paused if coming from pause menu
	if has_node("/root/PauseManager") and get_node("/root/PauseManager").is_paused:
		back_button.text = "Resume Game"
		get_tree().paused = true
		setup_game_tab()
		print("[SettingsScreen] Opened from pause menu - UI is interactable")
	else:
		back_button.text = "Back"
		get_tree().paused = false
	
	# Connect signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	reset_controls_button.pressed.connect(_on_reset_controls_pressed)
	
	# Load settings
	load_settings()
	setup_control_bindings()
	
	# Store original state
	store_original_settings()
	
	# Initially disable apply button
	apply_button.disabled = true
	has_unsaved_changes = false
	
	# Setup UI sounds for all buttons and sliders
	if has_node("/root/UIAudioManager"):
		var ui_audio = get_node("/root/UIAudioManager")
		ui_audio.setup_all_buttons(self)
		# Add hover sounds to sliders
		ui_audio.setup_hover_sound(master_slider)
		ui_audio.setup_hover_sound(music_slider)
		ui_audio.setup_hover_sound(sfx_slider)
		ui_audio.setup_hover_sound(ui_slider)

func load_settings() -> void:
	var settings = DatabaseManager.load_settings()
	
	if settings.size() > 0:
		master_slider.value = settings.get("master_volume", 1.0)
		music_slider.value = settings.get("music_volume", 0.8)
		sfx_slider.value = settings.get("sfx_volume", 0.8)
		ui_slider.value = settings.get("ui_volume", 1.0)
		
		apply_audio_settings()

func _on_master_volume_changed(value: float) -> void:
	master_value_label.text = "%d%%" % int(value * 100)
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	check_for_changes()

func _on_music_volume_changed(value: float) -> void:
	music_value_label.text = "%d%%" % int(value * 100)
	check_for_changes()

func _on_sfx_volume_changed(value: float) -> void:
	sfx_value_label.text = "%d%%" % int(value * 100)
	check_for_changes()

func _on_ui_volume_changed(value: float) -> void:
	ui_value_label.text = "%d%%" % int(value * 100)
	# Apply UI volume in real-time
	var ui_bus_idx = get_or_create_bus("UI")
	if ui_bus_idx >= 0:
		AudioServer.set_bus_volume_db(ui_bus_idx, linear_to_db(value))
	check_for_changes()

func apply_audio_settings() -> void:
	# Apply Master volume
	AudioServer.set_bus_volume_db(0, linear_to_db(master_slider.value))
	
	# Apply UI volume
	var ui_bus_idx = get_or_create_bus("UI")
	if ui_bus_idx >= 0:
		AudioServer.set_bus_volume_db(ui_bus_idx, linear_to_db(ui_slider.value))
	
	# Music and SFX buses can be added when needed
	# For now they just save to database

func _on_apply_pressed() -> void:
	# Save audio settings
	var settings = {
		"master_volume": master_slider.value,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"ui_volume": ui_slider.value
	}
	
	# Save control bindings
	var key_bindings = {}
	for action in CONTROL_ACTIONS.keys():
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				key_bindings[action] = event.physical_keycode
	
	settings["key_bindings"] = JSON.stringify(key_bindings)
	
	print("[SettingsScreen] Saving key bindings: ", settings["key_bindings"])
	DatabaseManager.save_settings(settings)
	apply_audio_settings()
	print("[SettingsScreen] Settings saved!")
	
	# Reset change tracking
	has_unsaved_changes = false
	apply_button.disabled = true
	store_original_settings()

func _on_back_pressed() -> void:
	# Check for unsaved changes
	if has_unsaved_changes:
		# Show confirmation dialog
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "You have unsaved changes. Are you sure you want to discard them?"
		dialog.ok_button_text = "Discard"
		dialog.cancel_button_text = "Cancel"
		dialog.confirmed.connect(_on_discard_confirmed)
		add_child(dialog)
		dialog.popup_centered()
		return
	
	_on_discard_confirmed()

func _on_discard_confirmed() -> void:
	# Check if we came from in-game (paused)
	if has_node("/root/PauseManager"):
		var pause_manager = get_node("/root/PauseManager")
		if pause_manager.is_paused:
			pause_manager.resume_game()
			return
	
	# From title screen
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

func setup_control_bindings() -> void:
	# Clear existing controls
	for child in controls_container.get_children():
		child.queue_free()
	
	# Note: InputManager already loads bindings on startup and applies them to InputMap
	# We just need to display the current InputMap state
	print("[SettingsScreen] Setting up control bindings UI...")
	
	# Create UI for each control
	for action in CONTROL_ACTIONS.keys():
		var container = HBoxContainer.new()
		container.custom_minimum_size.y = 40
		
		# Action label
		var label = Label.new()
		label.text = CONTROL_ACTIONS[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(label)
		
		# Key button
		var key_button = Button.new()
		key_button.custom_minimum_size = Vector2(150, 0)
		key_button.text = get_key_text(action)
		key_button.pressed.connect(_on_rebind_key.bind(action, key_button))
		control_buttons[action] = key_button
		
		# Setup sound effects for this button
		if has_node("/root/UIAudioManager"):
			get_node("/root/UIAudioManager").setup_button_sounds(key_button)
		
		container.add_child(key_button)
		
		controls_container.add_child(container)

func get_key_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			var key_string = OS.get_keycode_string(event.physical_keycode)
			print("[SettingsScreen] Action '", action, "' has key: ", key_string, " (keycode: ", event.physical_keycode, ")")
			return key_string
	print("[SettingsScreen] Action '", action, "' has no key set")
	return "Not Set"

func _on_rebind_key(action: String, button: Button) -> void:
	waiting_for_input = action
	button.text = "Press any key..."
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if waiting_for_input != "" and event is InputEventKey and event.pressed:
		# Don't allow ESC key to be bound (reserved for pause)
		if event.physical_keycode == KEY_ESCAPE:
			print("[SettingsScreen] ESC key is reserved for pause menu")
			if waiting_for_input in control_buttons:
				control_buttons[waiting_for_input].text = get_key_text(waiting_for_input)
			waiting_for_input = ""
			set_process_input(false)
			return
		
		# Rebind the key
		InputMap.action_erase_events(waiting_for_input)
		var new_event = InputEventKey.new()
		new_event.physical_keycode = event.physical_keycode
		InputMap.action_add_event(waiting_for_input, new_event)
		
		# Update button text
		if waiting_for_input in control_buttons:
			control_buttons[waiting_for_input].text = get_key_text(waiting_for_input)
		
		waiting_for_input = ""
		set_process_input(false)
		get_viewport().set_input_as_handled()
		
		# Mark as changed
		check_for_changes()

func _on_reset_controls_pressed() -> void:
	# Reset to default keybindings
	var defaults = {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_W,
		"move_down": KEY_S,
		"cast_line": KEY_SPACE,
		"attack": KEY_J,
		"open_inventory": KEY_I
	}
	
	for action in defaults.keys():
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			var new_event = InputEventKey.new()
			new_event.physical_keycode = defaults[action]
			InputMap.action_add_event(action, new_event)
			
			if action in control_buttons:
				control_buttons[action].text = get_key_text(action)
	
	print("Controls reset to defaults")
	check_for_changes()

func store_original_settings() -> void:
	# Store current audio settings
	original_settings = {
		"master_volume": master_slider.value,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"ui_volume": ui_slider.value
	}
	
	# Store current key bindings
	original_key_bindings.clear()
	for action in CONTROL_ACTIONS.keys():
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				original_key_bindings[action] = event.physical_keycode

func get_or_create_bus(bus_name: String) -> int:
	# Check if bus exists
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		# Create the bus
		AudioServer.add_bus()
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, bus_name)
		# Set it as a child of Master bus
		AudioServer.set_bus_send(bus_idx, "Master")
		print("[SettingsScreen] Created audio bus: ", bus_name)
	return bus_idx

func check_for_changes() -> void:
	# Check audio settings
	var audio_changed = (
		master_slider.value != original_settings.get("master_volume", 1.0) or
		music_slider.value != original_settings.get("music_volume", 0.8) or
		sfx_slider.value != original_settings.get("sfx_volume", 0.8) or
		ui_slider.value != original_settings.get("ui_volume", 1.0)
	)
	
	# Check key bindings
	var keys_changed = false
	for action in CONTROL_ACTIONS.keys():
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				if event.physical_keycode != original_key_bindings.get(action, 0):
					keys_changed = true
					break
	
	# Update state
	has_unsaved_changes = audio_changed or keys_changed
	apply_button.disabled = not has_unsaved_changes
	
	if has_unsaved_changes:
		print("[SettingsScreen] Unsaved changes detected")

func setup_game_tab() -> void:
	if tab_container == null:
		push_warning("[SettingsScreen] TabContainer not found, cannot create Game tab")
		return
	
	# Create Game tab container
	game_tab = VBoxContainer.new()
	game_tab.name = "Game"
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	game_tab.add_child(spacer1)
	
	# Title
	var title = Label.new()
	title.text = "Game Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	game_tab.add_child(title)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	game_tab.add_child(spacer2)
	
	# Resume Game button
	resume_game_button = Button.new()
	resume_game_button.text = "Resume Game"
	resume_game_button.custom_minimum_size = Vector2(200, 50)
	resume_game_button.pressed.connect(_on_resume_game_pressed)
	game_tab.add_child(resume_game_button)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	game_tab.add_child(spacer3)
	
	# Save Game button
	save_game_button = Button.new()
	save_game_button.text = "Save Game"
	save_game_button.custom_minimum_size = Vector2(200, 50)
	save_game_button.pressed.connect(_on_save_game_pressed)
	# Disable if no active save
	if GameState.current_save_id < 0:
		save_game_button.disabled = true
		save_game_button.text = "No Active Save"
	game_tab.add_child(save_game_button)
	
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 10)
	game_tab.add_child(spacer4)
	
	# Quit to Menu button
	quit_to_menu_button = Button.new()
	quit_to_menu_button.text = "Quit to Main Menu"
	quit_to_menu_button.custom_minimum_size = Vector2(200, 50)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)
	game_tab.add_child(quit_to_menu_button)
	
	# Add tab as first tab
	tab_container.add_child(game_tab)
	tab_container.move_child(game_tab, 0)
	tab_container.current_tab = 0
	
	# Setup UI sounds
	if has_node("/root/UIAudioManager"):
		var ui_audio = get_node("/root/UIAudioManager")
		ui_audio.setup_button_sounds(resume_game_button)
		ui_audio.setup_button_sounds(save_game_button)
		ui_audio.setup_button_sounds(quit_to_menu_button)
	
	print("[SettingsScreen] Game tab created")

func _on_resume_game_pressed() -> void:
	if has_node("/root/PauseManager"):
		get_node("/root/PauseManager").resume_game()

func _on_save_game_pressed() -> void:
	if GameState.current_save_id >= 0:
		GameState.save_game_state()
		# Show feedback
		save_game_button.text = "Game Saved!"
		await get_tree().create_timer(1.0).timeout
		save_game_button.text = "Save Game"

func _on_quit_to_menu_pressed() -> void:
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Return to main menu? Any unsaved progress will be lost."
	dialog.ok_button_text = "Quit to Menu"
	dialog.cancel_button_text = "Cancel"
	dialog.confirmed.connect(_on_quit_to_menu_confirmed)
	add_child(dialog)
	dialog.popup_centered()

func _on_quit_to_menu_confirmed() -> void:
	# Clear pause state
	if has_node("/root/PauseManager"):
		var pause_manager = get_node("/root/PauseManager")
		pause_manager.is_paused = false
		pause_manager.previous_scene = ""
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
