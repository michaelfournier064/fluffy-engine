# res://scripts/ui/fishing_ui.gd
extends CanvasLayer

## UI for fishing mechanics

@onready var fishing_panel: Panel = %FishingPanel
@onready var status_label: Label = %StatusLabel
@onready var action_label: Label = %ActionLabel
@onready var catch_button: Button = %CatchButton

var fishing_system: Node

# Minigame UI
var sequence_label: Label
var progress_label: Label
var timer_label: Label
var minigame_container: VBoxContainer

# Caught fish screen
var caught_screen: Control
var caught_image: TextureRect

func _ready() -> void:
	setup_minigame_ui()
	setup_caught_screen()
	hide_ui()
	catch_button.pressed.connect(_on_catch_button_pressed)

func setup_minigame_ui() -> void:
	# Create minigame UI elements dynamically
	minigame_container = VBoxContainer.new()
	minigame_container.name = "MinigameContainer"
	fishing_panel.add_child(minigame_container)
	minigame_container.visible = false

	sequence_label = Label.new()
	sequence_label.name = "SequenceLabel"
	sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sequence_label.add_theme_font_size_override("font_size", 24)
	minigame_container.add_child(sequence_label)

	progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 20)
	minigame_container.add_child(progress_label)

	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 18)
	minigame_container.add_child(timer_label)

func setup_caught_screen() -> void:
	# Create fullscreen overlay for caught fish
	caught_screen = Control.new()
	caught_screen.name = "CaughtScreen"
	caught_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	caught_screen.mouse_filter = Control.MOUSE_FILTER_STOP  # Make it clickable
	add_child(caught_screen)
	caught_screen.visible = false

	# Image display (clickable)
	caught_image = TextureRect.new()
	caught_image.name = "CaughtImage"
	caught_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	caught_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	caught_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	caught_screen.add_child(caught_image)

	# Make the screen clickable
	caught_screen.gui_input.connect(_on_caught_screen_clicked)

func set_fishing_system(system: Node) -> void:
	fishing_system = system

	# Connect to fishing signals
	fishing_system.fishing_started.connect(_on_fishing_started)
	fishing_system.fish_hooked.connect(_on_fish_hooked)
	fishing_system.fish_caught.connect(_on_fish_caught)
	fishing_system.fish_escaped.connect(_on_fish_escaped)
	fishing_system.fishing_ended.connect(_on_fishing_ended)

	# Connect to minigame signals
	fishing_system.minigame_started.connect(_on_minigame_started)
	fishing_system.minigame_key_pressed.connect(_on_minigame_key_pressed)
	fishing_system.minigame_failed.connect(_on_minigame_failed)

func show_ui() -> void:
	fishing_panel.visible = true

func hide_ui() -> void:
	fishing_panel.visible = false
	catch_button.visible = false
	minigame_container.visible = false
	status_label.visible = true
	action_label.visible = true

func _on_fishing_started() -> void:
	show_ui()
	status_label.text = "Waiting for a bite..."
	action_label.text = "Stay patient..."
	catch_button.visible = false

func _on_fish_hooked(_fish_data: Dictionary) -> void:
	status_label.text = "FISH ON THE LINE!"
	action_label.text = "Press button or SPACE to reel in!"
	catch_button.visible = true
	
	# Visual feedback
	fishing_panel.modulate = Color(1, 1, 0.5)

func _on_fish_caught(fish_data: Dictionary) -> void:
	# Hide fishing panel
	hide_ui()

	# Load and show the appropriate "you caught" image
	var image_path = get_caught_image_path(fish_data.fish_name)
	var texture = load(image_path)

	if texture:
		caught_image.texture = texture
		caught_screen.visible = true
		print("Showing caught screen for: ", fish_data.fish_name)
	else:
		# Fallback to text display if image not found
		status_label.text = "Caught: %s!" % fish_data.fish_name
		action_label.text = "Size: %.1fcm | Weight: %.2fkg | +%d Gold | +%d XP" % [
			fish_data.fish_size,
			fish_data.fish_weight,
			fish_data.value,
			fish_data.experience
		]
		fishing_panel.modulate = Color(0.5, 1, 0.5)
		fishing_panel.visible = true

		# Auto hide after delay
		await get_tree().create_timer(3.0).timeout
		hide_ui()

func get_caught_image_path(fish_name: String) -> String:
	# Map fish names to image files - exact matches
	var fish_lower = fish_name.to_lower()

	# Exact matches for the 5 fish types
	if fish_lower == "bass":
		return "res://assets/sprites/youcaughtbass.jpg"
	elif fish_lower == "goldfish":
		return "res://assets/sprites/youcaughtgoldfish.jpg"
	elif fish_lower == "trout":
		return "res://assets/sprites/youcaughttrout.jpg"
	elif fish_lower == "snapper":
		return "res://assets/sprites/youcaughtsnapper.jpg"
	elif fish_lower == "tuna":
		return "res://assets/sprites/youcaughttuna.jpg"

	# Fallback (shouldn't happen with correct fish names)
	print("Warning: Unknown fish name: ", fish_name)
	return "res://assets/sprites/youcaughtbass.jpg"

func _on_caught_screen_clicked(event: InputEvent) -> void:
	# Check if it's a mouse click or touch
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Hide caught screen and return to game
		caught_screen.visible = false
		fishing_panel.modulate = Color.WHITE
		print("Continuing game...")

func _on_fish_escaped() -> void:
	status_label.text = "The fish got away!"
	action_label.text = "Too slow... Try again!"
	catch_button.visible = false
	
	# Failure color
	fishing_panel.modulate = Color(1, 0.5, 0.5)
	
	# Auto hide after delay
	await get_tree().create_timer(2.0).timeout
	hide_ui()

func _on_fishing_ended() -> void:
	# Reset all UI elements
	minigame_container.visible = false
	status_label.visible = true
	action_label.visible = true
	catch_button.visible = false
	hide_ui()
	fishing_panel.modulate = Color.WHITE

func _on_catch_button_pressed() -> void:
	if fishing_system:
		fishing_system.attempt_catch()

func _on_minigame_started(sequence: Array) -> void:
	# Hide catch button, show minigame UI
	catch_button.visible = false
	status_label.visible = false
	action_label.visible = false
	minigame_container.visible = true

	# Convert action names to key letters
	var key_letters = []
	for action in sequence:
		match action:
			"move_up": key_letters.append("W")
			"move_down": key_letters.append("S")
			"move_left": key_letters.append("A")
			"move_right": key_letters.append("D")

	sequence_label.text = " ".join(key_letters)
	progress_label.text = "Press the keys in order!"
	timer_label.text = "Time: %.1fs" % fishing_system.minigame_time_limit

	# Start timer display update
	_update_timer_display()

func _on_minigame_key_pressed(correct: bool, progress: int, total: int) -> void:
	if correct:
		# Show progress
		progress_label.text = "Correct! %d/%d" % [progress, total]
		progress_label.modulate = Color.GREEN
	else:
		progress_label.text = "Wrong key!"
		progress_label.modulate = Color.RED

func _on_minigame_failed() -> void:
	# Hide minigame UI and reset
	minigame_container.visible = false
	status_label.visible = true
	action_label.visible = true

	# Reset progress labels
	if progress_label:
		progress_label.modulate = Color.WHITE

func _update_timer_display() -> void:
	if fishing_system and fishing_system.minigame_active:
		var time_left = fishing_system.minigame_timer.time_left
		timer_label.text = "Time: %.1fs" % time_left

		# Color based on time remaining
		if time_left < 2.0:
			timer_label.modulate = Color.RED
		elif time_left < 3.0:
			timer_label.modulate = Color.YELLOW
		else:
			timer_label.modulate = Color.WHITE

		# Update again next frame
		await get_tree().create_timer(0.1).timeout
		_update_timer_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_line") and catch_button.visible:
		_on_catch_button_pressed()
