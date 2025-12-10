# res://scripts/ui/inventory_ui.gd
extends CanvasLayer

## Inventory UI for viewing caught fish and player stats

@onready var inventory_panel: Panel = %InventoryPanel
@onready var fish_list: VBoxContainer = %FishList
@onready var stats_label: Label = %StatsLabel
@onready var total_value_label: Label = %TotalValueLabel
@onready var close_button: Button = %CloseButton

const FISH_ITEM = preload("res://scenes/ui/fish_inventory_item.tscn")

func _ready() -> void:
	# Setup UI sounds
	if has_node("/root/UIAudioManager"):
		get_node("/root/UIAudioManager").setup_all_buttons(self)
	
	hide_inventory()
	close_button.pressed.connect(_on_close_pressed)

func show_inventory() -> void:
	inventory_panel.visible = true
	refresh_inventory()

func hide_inventory() -> void:
	inventory_panel.visible = false

func refresh_inventory() -> void:
	# Clear existing items
	for child in fish_list.get_children():
		child.queue_free()
	
	# Get aggregated fish collection from database
	var fish_collection = DatabaseManager.get_fish_collection_summary(GameState.current_save_id)
	
	# Update stats
	var exp_to_next = GameState.player_level * 100
	stats_label.text = "Level: %d | XP: %d/%d | Gold: %d | Fish Caught: %d" % [
		GameState.player_level,
		GameState.player_experience,
		exp_to_next,
		GameState.player_gold,
		GameState.fish_caught
	]
	
	# Calculate total collection value
	var total_value = 0
	for fish in fish_collection:
		var fish_value = int(fish.get("value", 0))
		var fish_count = int(fish.get("count", 1))
		total_value += fish_value * fish_count
	
	total_value_label.text = "Total Collection Value: %d Gold" % total_value
	
	# Add fish items
	for fish in fish_collection:
		var item = FISH_ITEM.instantiate()
		fish_list.add_child(item)
		item.set_fish_data(fish)

func _on_close_pressed() -> void:
	hide_inventory()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		if inventory_panel.visible:
			hide_inventory()
		else:
			show_inventory()
