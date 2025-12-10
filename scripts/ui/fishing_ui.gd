# res://scripts/ui/fishing_ui.gd
extends CanvasLayer

## UI for fishing mechanics

@onready var fishing_panel: Panel = %FishingPanel
@onready var status_label: Label = %StatusLabel
@onready var action_label: Label = %ActionLabel
@onready var catch_button: Button = %CatchButton

var fishing_system: Node

func _ready() -> void:
	hide_ui()
	catch_button.pressed.connect(_on_catch_button_pressed)

func set_fishing_system(system: Node) -> void:
	fishing_system = system
	
	# Connect to fishing signals
	fishing_system.fishing_started.connect(_on_fishing_started)
	fishing_system.fish_hooked.connect(_on_fish_hooked)
	fishing_system.fish_caught.connect(_on_fish_caught)
	fishing_system.fish_escaped.connect(_on_fish_escaped)
	fishing_system.fishing_ended.connect(_on_fishing_ended)

func show_ui() -> void:
	fishing_panel.visible = true

func hide_ui() -> void:
	fishing_panel.visible = false
	catch_button.visible = false

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
	status_label.text = "Caught: %s!" % fish_data.fish_name
	action_label.text = "Size: %.1fcm | Weight: %.2fkg | +%d Gold | +%d XP" % [
		fish_data.fish_size,
		fish_data.fish_weight,
		fish_data.value,
		fish_data.experience
	]
	catch_button.visible = false
	
	# Success color
	fishing_panel.modulate = Color(0.5, 1, 0.5)
	
	# Auto hide after delay
	await get_tree().create_timer(3.0).timeout
	hide_ui()

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
	hide_ui()
	fishing_panel.modulate = Color.WHITE

func _on_catch_button_pressed() -> void:
	if fishing_system:
		fishing_system.attempt_catch()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_line") and catch_button.visible:
		_on_catch_button_pressed()
