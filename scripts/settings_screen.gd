# res://scripts/settings_screen.gd
extends Control

## Settings screen UI controller
## Manages all settings UI elements and interactions

# Tab references
@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer

# Audio tab controls
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_label: Label = %MasterVolumeLabel
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_label: Label = %MusicVolumeLabel
@onready var sfx_volume_slider: HSlider = %SfxVolumeSlider
@onready var sfx_volume_label: Label = %SfxVolumeLabel
@onready var ui_volume_slider: HSlider = %UiVolumeSlider
@onready var ui_volume_label: Label = %UiVolumeLabel

# Controls tab
@onready var controls_container: VBoxContainer = %ControlsContainer
@onready var reset_controls_button: CustomButton = %ResetControlsButton

# Bottom buttons
@onready var apply_button: CustomButton = %ApplyButton
@onready var reset_button: CustomButton = %ResetButton
@onready var back_button: CustomButton = %BackButton

var has_unsaved_changes: bool = false
var key_rebind_buttons: Dictionary = {}  # action_name -> button reference

func _ready() -> void:
	setup_controls()
	setup_key_bindings()
	load_current_settings()
	connect_signals()

func setup_controls() -> void:
	# Setup sliders
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.step = 0.01
	
	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 1.0
	music_volume_slider.step = 0.01
	
	sfx_volume_slider.min_value = 0.0
	sfx_volume_slider.max_value = 1.0
	sfx_volume_slider.step = 0.01
	
	ui_volume_slider.min_value = 0.0
	ui_volume_slider.max_value = 1.0
	ui_volume_slider.step = 0.01

func setup_key_bindings() -> void:
	# Clear existing controls
	for child in controls_container.get_children():
		child.queue_free()
	
	key_rebind_buttons.clear()
	
	# Load the key rebind button script
	var KeyRebindButton = load("res://scripts/utilities/key_rebind_button.gd")
	
	# Create a rebind button for each action
	for action in UserControls.get_all_actions():
		var container = HBoxContainer.new()
		container.custom_minimum_size = Vector2(0, 35)
		
		# Action label
		var label = Label.new()
		label.text = UserControls.get_action_display_name(action)
		label.custom_minimum_size = Vector2(200, 0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(label)
		
		# Rebind button
		var button = Button.new()
		button.custom_minimum_size = Vector2(150, 0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_script(KeyRebindButton)
		button.setup(action, UserControls.get_action_keycode(action))
		button.key_assigned.connect(_on_key_assigned)
		container.add_child(button)
		
		controls_container.add_child(container)
		key_rebind_buttons[action] = button

func load_current_settings() -> void:
	# Audio settings
	master_volume_slider.value = SettingsManager.master_volume
	update_volume_label(master_volume_label, SettingsManager.master_volume)
	
	music_volume_slider.value = SettingsManager.music_volume
	update_volume_label(music_volume_label, SettingsManager.music_volume)
	
	sfx_volume_slider.value = SettingsManager.sfx_volume
	update_volume_label(sfx_volume_label, SettingsManager.sfx_volume)
	
	ui_volume_slider.value = SettingsManager.ui_volume
	update_volume_label(ui_volume_label, SettingsManager.ui_volume)
	
	has_unsaved_changes = false
	update_apply_button()

func connect_signals() -> void:
	# Audio signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_volume_slider.value_changed.connect(_on_ui_volume_changed)
	
	# Button signals
	apply_button.pressed_confirmed.connect(_on_apply_pressed)
	reset_button.pressed_confirmed.connect(_on_reset_pressed)
	back_button.pressed_confirmed.connect(_on_back_pressed)
	
	# Controls tab signals
	reset_controls_button.pressed_confirmed.connect(_on_reset_controls_pressed)

func _on_key_assigned(action: String, keycode: int) -> void:
	UserControls.set_action_key(action, keycode, true)
	print("Rebound %s to %s" % [UserControls.get_action_display_name(action), UserControls.get_key_name(keycode)])

func _on_reset_controls_pressed() -> void:
	UserControls.reset_to_defaults()
	# Refresh all button displays
	for action in key_rebind_buttons.keys():
		var button = key_rebind_buttons[action]
		button.update_display(UserControls.get_action_keycode(action))
	print("Key bindings reset to defaults")

func _on_setting_changed(_value = null) -> void:
	has_unsaved_changes = true
	update_apply_button()

func _on_master_volume_changed(value: float) -> void:
	update_volume_label(master_volume_label, value)
	# Apply immediately for audio feedback
	SettingsManager.master_volume = value
	SettingsManager.apply_audio_settings()
	has_unsaved_changes = true
	update_apply_button()

func _on_music_volume_changed(value: float) -> void:
	update_volume_label(music_volume_label, value)
	SettingsManager.music_volume = value
	SettingsManager.apply_audio_settings()
	has_unsaved_changes = true
	update_apply_button()

func _on_sfx_volume_changed(value: float) -> void:
	update_volume_label(sfx_volume_label, value)
	SettingsManager.sfx_volume = value
	SettingsManager.apply_audio_settings()
	# Play test sound
	if is_inside_tree():
		UserInterfaceAudio.play_click()
	has_unsaved_changes = true
	update_apply_button()

func _on_ui_volume_changed(value: float) -> void:
	update_volume_label(ui_volume_label, value)
	SettingsManager.ui_volume = value
	SettingsManager.apply_audio_settings()
	has_unsaved_changes = true
	update_apply_button()

func update_volume_label(label: Label, value: float) -> void:
	label.text = "%d%%" % int(value * 100)

func update_apply_button() -> void:
	apply_button.disabled = not has_unsaved_changes

func _on_apply_pressed() -> void:
	apply_all_settings()
	has_unsaved_changes = false
	update_apply_button()

func apply_all_settings() -> void:
	# Audio settings (already applied in real-time)
	SettingsManager.master_volume = master_volume_slider.value
	SettingsManager.music_volume = music_volume_slider.value
	SettingsManager.sfx_volume = sfx_volume_slider.value
	SettingsManager.ui_volume = ui_volume_slider.value
	
	# Apply and save
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	
	print("Settings applied and saved")

func _on_reset_pressed() -> void:
	SettingsManager.reset_to_defaults()
	load_current_settings()
	print("Settings reset to defaults")

func _on_back_pressed() -> void:
	if has_unsaved_changes:
		# Optionally show a confirmation dialog
		# For now, just discard changes
		pass
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
