# res://scripts/ui/ui_audio_manager.gd
extends Node

## UI Audio Manager - Handles all UI sound effects (hover, click, etc.)

var click_sound: AudioStream
var hover_sound: AudioStream
var audio_player: AudioStreamPlayer

func _ready() -> void:
	# Load sounds
	click_sound = load("res://assets/sounds/click_sound.mp3")
	hover_sound = click_sound  # Use same sound for hover (lower volume)
	
	# Create UI audio bus if it doesn't exist
	var ui_bus_idx = AudioServer.get_bus_index("UI")
	if ui_bus_idx < 0:
		AudioServer.add_bus()
		ui_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(ui_bus_idx, "UI")
		AudioServer.set_bus_send(ui_bus_idx, "Master")
		print("[UIAudioManager] Created UI audio bus")
	
	# Create audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "UI"
	add_child(audio_player)
	
	print("[UIAudioManager] UI audio system initialized")
	
	# Wait for database to be ready before loading settings
	if DatabaseManager.db == null:
		await DatabaseManager.database_ready
	
	# Load and apply saved UI volume
	var settings = DatabaseManager.load_settings()
	if settings.size() > 0:
		var ui_volume = settings.get("ui_volume", 1.0)
		AudioServer.set_bus_volume_db(ui_bus_idx, linear_to_db(ui_volume))
		print("[UIAudioManager] Applied saved UI volume: ", ui_volume)

func play_click() -> void:
	if click_sound:
		audio_player.stream = click_sound
		audio_player.volume_db = 0.0
		audio_player.play()

func play_hover() -> void:
	if hover_sound:
		audio_player.stream = hover_sound
		audio_player.volume_db = -6.0  # Quieter than click
		audio_player.play()

## Connects UI sound effects to a button
func setup_button_sounds(button: Button) -> void:
	if not button:
		return
	

## Connects UI sound effects to any Control node that can be hovered
func setup_hover_sound(control: Control) -> void:
	if not control:
		return
	
	control.mouse_entered.connect(_on_control_hover.bind(control))

func _on_button_hover(button: Button) -> void:
	if button.disabled:
		return
	play_hover()

func _on_button_click(_button: Button) -> void:
	play_click()

func _on_control_hover(_control: Control) -> void:
	play_hover()

## Automatically connects sounds to all buttons in a scene tree
func setup_all_buttons(root: Node) -> void:
	for node in _get_all_descendants(root):
		if node is Button:
			setup_button_sounds(node)

func _get_all_descendants(node: Node) -> Array:
	var descendants = []
	for child in node.get_children():
		descendants.append(child)
		descendants.append_array(_get_all_descendants(child))
	return descendants
