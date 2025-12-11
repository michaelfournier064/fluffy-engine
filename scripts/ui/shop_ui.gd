# res://scripts/ui/shop_ui.gd
extends CanvasLayer

## ============================================================================
## FISHING GAME SHOP SYSTEM
## ============================================================================
## This script manages the in-game shop where players can:
## - Sell caught fish for gold
## - Buy upgrades to improve fishing abilities
## - Purchase pets as companions
##
## Controls: Press E to open/close shop
##
## HOW TO ADD NEW ITEMS:
## ---------------------
## UPGRADES: Add to shop_upgrades array with "type" field, then add matching
##           case in apply_upgrade() function to make it actually work
##
## PETS: Add to shop_pets array (no type field needed)
##
## EXAMPLE - Adding a new upgrade:
##   1. Add to shop_upgrades:
##      {"name": "My Upgrade", "price": 100, "description": "Does cool thing", "type": "my_type"}
##   2. Add case to apply_upgrade():
##      "my_type": # Your code here
##
## ============================================================================

## ============================================================================
## UI COMPONENTS
## ============================================================================
var shop_screen: Control          # Main shop container
var is_open: bool = false         # Whether shop is currently open
var money_label: Label            # Displays current gold amount
var current_section: String = "sell"  # Which tab is currently active

## Section containers - holds items for each tab
var sell_fish_container: VBoxContainer    # Shows fish you can sell
var upgrades_container: VBoxContainer     # Shows upgrades you can buy
var pets_container: VBoxContainer         # Shows pets you can buy

## Pet management
var spawned_pet: Node = null  # Reference to currently spawned pet in the world

## ============================================================================
## SHOP DATA
## ============================================================================

## Upgrades - Permanent improvements to fishing abilities
## Each upgrade can be purchased multiple times and stacks
var shop_upgrades = [
	{
		"name": "Legendary Luck",
		"price": 500,
		"description": "+2% legendary fish chance",
		"type": "legendary_chance"  # Used to identify which upgrade this is
	}
	# NOTE: Speed Boost upgrade removed until implementation is complete
	# To re-add: uncomment below and implement in apply_upgrade() function
	#{
	#	"name": "Speed Boost",
	#	"price": 150,
	#	"description": "Move 15% faster",
	#	"type": "movement_speed"
	#}
]

## Pets - Companions that follow you around
## Each pet is a one-time purchase
var shop_pets = [
	{"name": "🐙 Octopet", "price": 100, "description": "Mystical ocean friend"}
]

## ============================================================================
## INITIALIZATION
## ============================================================================
func _ready() -> void:
	# Always process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_shop()

## ============================================================================
## SHOP SETUP
## ============================================================================
## Creates all the UI elements for the shop
func setup_shop() -> void:
	# Create fullscreen shop
	shop_screen = Control.new()
	shop_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_screen)

	# Background overlay
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_screen.add_child(bg)

	# Main shop panel
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400
	panel.offset_top = -250
	panel.offset_right = 400
	panel.offset_bottom = 250

	# Panel background color
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.95, 0.9, 0.85)
	panel_style.border_color = Color(0.4, 0.3, 0.2)
	panel_style.set_border_width_all(4)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	shop_screen.add_child(panel)

	# Shop title
	var title = Label.new()
	title.text = "🎣 Fishing Shop 🎣"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.2, 0.5, 0.7))
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -150
	title.offset_right = 150
	title.offset_top = 10
	title.offset_bottom = 50
	panel.add_child(title)

	# Money display
	money_label = Label.new()
	update_money_display()
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 24)
	money_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
	money_label.anchor_left = 0.5
	money_label.anchor_right = 0.5
	money_label.offset_left = -100
	money_label.offset_right = 100
	money_label.offset_top = 55
	money_label.offset_bottom = 85
	panel.add_child(money_label)

	# Tab buttons
	var tab_container = HBoxContainer.new()
	tab_container.anchor_left = 0.5
	tab_container.anchor_right = 0.5
	tab_container.offset_left = -300
	tab_container.offset_right = 300
	tab_container.offset_top = 95
	tab_container.offset_bottom = 130
	tab_container.add_theme_constant_override("separation", 10)
	tab_container.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(tab_container)

	# Create tabs - Sell Fish, Upgrades, Pets
	create_tab_button("Sell Fish", tab_container)
	create_tab_button("Upgrades", tab_container)
	create_tab_button("Pets", tab_container)

	# Scroll container for items
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0.05
	scroll.anchor_right = 0.95
	scroll.anchor_top = 0.3
	scroll.anchor_bottom = 0.85
	panel.add_child(scroll)

	# Sell Fish container - Shows fish player has caught
	sell_fish_container = VBoxContainer.new()
	sell_fish_container.size_flags_horizontal = Control.SIZE_FILL
	sell_fish_container.add_theme_constant_override("separation", 10)
	scroll.add_child(sell_fish_container)

	# Upgrades container - Shows purchasable upgrades
	upgrades_container = VBoxContainer.new()
	upgrades_container.size_flags_horizontal = Control.SIZE_FILL
	upgrades_container.add_theme_constant_override("separation", 10)
	upgrades_container.visible = false
	scroll.add_child(upgrades_container)

	# Pets container - Shows purchasable pets
	pets_container = VBoxContainer.new()
	pets_container.size_flags_horizontal = Control.SIZE_FILL
	pets_container.add_theme_constant_override("separation", 10)
	pets_container.visible = false
	scroll.add_child(pets_container)

	# Populate shop sections with items
	for upgrade in shop_upgrades:
		var upgrade_panel = create_shop_item(upgrade, false)  # false = not a pet
		upgrades_container.add_child(upgrade_panel)

	for pet in shop_pets:
		var pet_panel = create_shop_item(pet, true)  # true = is a pet (purple color)
		pets_container.add_child(pet_panel)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close (E)"
	close_btn.anchor_left = 0.5
	close_btn.anchor_right = 0.5
	close_btn.anchor_top = 0.9
	close_btn.offset_left = -80
	close_btn.offset_right = 80
	close_btn.offset_top = 0
	close_btn.offset_bottom = 35
	close_btn.add_theme_font_size_override("font_size", 18)

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.3, 0.3)
	close_style.corner_radius_top_left = 8
	close_style.corner_radius_top_right = 8
	close_style.corner_radius_bottom_left = 8
	close_style.corner_radius_bottom_right = 8
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(toggle_shop)
	panel.add_child(close_btn)

	# Hide initially
	shop_screen.visible = false

## ============================================================================
## UI CREATION HELPERS
## ============================================================================

## Creates a shop item panel for upgrades and pets
## is_pet: if true, uses purple background color
func create_shop_item(item: Dictionary, is_pet: bool = false) -> Panel:
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 80)
	item_panel.size_flags_horizontal = Control.SIZE_FILL

	var item_style = StyleBoxFlat.new()
	# Purple background for pets, white for upgrades
	if is_pet:
		item_style.bg_color = Color(0.85, 0.7, 1.0, 0.9)  # Light purple
		item_style.border_color = Color(0.6, 0.4, 0.8)     # Purple border
	else:
		item_style.bg_color = Color(1, 1, 1, 0.9)          # White
		item_style.border_color = Color(0.6, 0.5, 0.4)     # Brown border

	item_style.set_border_width_all(2)
	item_style.corner_radius_top_left = 10
	item_style.corner_radius_top_right = 10
	item_style.corner_radius_bottom_left = 10
	item_style.corner_radius_bottom_right = 10
	item_panel.add_theme_stylebox_override("panel", item_style)

	# Main horizontal container
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	item_panel.add_child(hbox)

	# Left margin
	var margin_left = Control.new()
	margin_left.custom_minimum_size = Vector2(15, 0)
	hbox.add_child(margin_left)

	# Left side - item info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Item name
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(desc_label)

	# Right side - price and button
	var price_label = Label.new()
	price_label.text = "$" + str(item.price)
	price_label.add_theme_font_size_override("font_size", 20)
	price_label.add_theme_color_override("font_color", Color(0.1, 0.6, 0.1))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(price_label)

	# Buy/Equip button (changes based on ownership)
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(90, 40)
	buy_btn.add_theme_font_size_override("font_size", 16)

	# Determine button text and color based on pet ownership
	var item_name = item.get("name", "")

	if is_pet and GameState.owned_pets.has(item_name):
		# Pet is owned - show Equip or Unequip
		if GameState.equipped_pet == item_name:
			buy_btn.text = "Unequip"
			var unequip_style = StyleBoxFlat.new()
			unequip_style.bg_color = Color(0.8, 0.5, 0.3)  # Orange for unequip
			unequip_style.corner_radius_top_left = 8
			unequip_style.corner_radius_top_right = 8
			unequip_style.corner_radius_bottom_left = 8
			unequip_style.corner_radius_bottom_right = 8
			buy_btn.add_theme_stylebox_override("normal", unequip_style)
		else:
			buy_btn.text = "Equip"
			var equip_style = StyleBoxFlat.new()
			equip_style.bg_color = Color(0.4, 0.6, 0.8)  # Blue for equip
			equip_style.corner_radius_top_left = 8
			equip_style.corner_radius_top_right = 8
			equip_style.corner_radius_bottom_left = 8
			equip_style.corner_radius_bottom_right = 8
			buy_btn.add_theme_stylebox_override("normal", equip_style)
	else:
		# Not owned - show Buy
		buy_btn.text = "Buy"
		var buy_style = StyleBoxFlat.new()
		buy_style.bg_color = Color(0.3, 0.7, 0.4)  # Green for buy
		buy_style.corner_radius_top_left = 8
		buy_style.corner_radius_top_right = 8
		buy_style.corner_radius_bottom_left = 8
		buy_style.corner_radius_bottom_right = 8
		buy_btn.add_theme_stylebox_override("normal", buy_style)

	buy_btn.pressed.connect(func(): buy_item(item))
	hbox.add_child(buy_btn)

	# Right margin
	var margin_right = Control.new()
	margin_right.custom_minimum_size = Vector2(15, 0)
	hbox.add_child(margin_right)

	return item_panel

func create_tab_button(tab_name: String, parent: HBoxContainer) -> void:
	var btn = Button.new()
	btn.text = tab_name
	btn.custom_minimum_size = Vector2(140, 35)
	btn.add_theme_font_size_override("font_size", 16)

	var section_name = tab_name.to_lower().replace(" ", "")

	var btn_style = StyleBoxFlat.new()
	if section_name == current_section or (section_name == "sellfish" and current_section == "sell"):
		btn_style.bg_color = Color(0.4, 0.6, 0.8)
	else:
		btn_style.bg_color = Color(0.6, 0.6, 0.6)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)

	btn.pressed.connect(func(): switch_section(tab_name.to_lower()))
	parent.add_child(btn)

## ============================================================================
## SECTION SWITCHING
## ============================================================================
## Switches between different shop tabs (Sell Fish, Upgrades, Pets)
func switch_section(section: String) -> void:
	current_section = section

	# Hide all containers
	sell_fish_container.visible = false
	upgrades_container.visible = false
	pets_container.visible = false

	# Show the selected container
	match section:
		"sell", "sell fish":
			sell_fish_container.visible = true
			load_fish_inventory()  # Reload fish from database
		"upgrades":
			upgrades_container.visible = true
		"pets":
			pets_container.visible = true

func update_money_display() -> void:
	money_label.text = "Gold: $" + str(GameState.player_gold)

## ============================================================================
## PURCHASING SYSTEM
## ============================================================================
## Handles buying upgrades and pets from the shop
func buy_item(item: Dictionary) -> void:
	var item_name = item.get("name", "")

	# Check if this is a pet that's already owned
	if not item.has("type") and GameState.owned_pets.has(item_name):
		# This is an owned pet - toggle equip/unequip
		if GameState.equipped_pet == item_name:
			unequip_pet(item_name)
		else:
			equip_pet(item_name)
		refresh_pets_ui()
		return

	# Check if player has enough gold
	if GameState.player_gold < item.price:
		print("Not enough gold! Need $" + str(item.price) + " but only have $" + str(GameState.player_gold))
		return

	# Deduct gold
	GameState.player_gold -= item.price
	update_money_display()

	# Apply upgrade effect based on type
	if item.has("type"):  # This is an upgrade
		apply_upgrade(item)
	else:  # This is a pet
		purchase_pet(item)
		refresh_pets_ui()

	print("Purchase complete! Remaining gold: $" + str(GameState.player_gold))

## Add a pet to the player's collection (doesn't equip automatically)
func purchase_pet(pet: Dictionary) -> void:
	var pet_name = pet.get("name", "")

	# Check if already owned
	if GameState.owned_pets.has(pet_name):
		print("[Shop] You already own " + pet_name + "!")
		return

	# Add to owned pets (but don't equip yet)
	GameState.owned_pets.append(pet_name)
	print("[Shop] " + pet_name + " added to collection! Click 'Equip' to summon it.")

## Equip a pet (spawn it in the world)
func equip_pet(pet_name: String) -> void:
	# Unequip current pet first
	if GameState.equipped_pet != "":
		unequip_pet(GameState.equipped_pet)

	# Set as equipped
	GameState.equipped_pet = pet_name
	print("[Shop] Equipping pet: " + pet_name)

	# Spawn the pet
	spawn_pet(pet_name)

## Unequip a pet (remove it from the world)
func unequip_pet(pet_name: String) -> void:
	print("[Shop] Unequipping pet: " + pet_name)

	# Remove from equipped
	GameState.equipped_pet = ""

	# Remove spawned pet from world
	if spawned_pet:
		spawned_pet.queue_free()
		spawned_pet = null
		print("[Shop] Pet removed from world")

## Refresh the pets UI to update button states
func refresh_pets_ui() -> void:
	# Clear and rebuild pets container
	for child in pets_container.get_children():
		child.queue_free()

	for pet in shop_pets:
		var pet_panel = create_shop_item(pet, true)
		pets_container.add_child(pet_panel)

## Spawns a pet in the game world
func spawn_pet(pet_name: String) -> void:
	# Get the current scene (main game world)
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("[Shop] Error: No current scene found!")
		return

	if pet_name == "🐙 Octopet":
		# Check if scene exists
		if not ResourceLoader.exists("res://scenes/pets/octopet.tscn"):
			print("[Shop] Error: octopet.tscn not found!")
			return

		# Load and instantiate the scene
		var octopet_scene = load("res://scenes/pets/octopet.tscn")
		if not octopet_scene:
			print("[Shop] Error: Failed to load octopet scene!")
			return

		var octopet = octopet_scene.instantiate()
		if not octopet:
			print("[Shop] Error: Failed to instantiate octopet!")
			return

		# Add to scene and store reference
		current_scene.add_child(octopet)
		spawned_pet = octopet
		print("[Shop] Octopet spawned successfully!")
	else:
		print("[Shop] Unknown pet: ", pet_name)

## Apply the effect of a purchased upgrade
func apply_upgrade(upgrade: Dictionary) -> void:
	var upgrade_type = upgrade.get("type", "")

	match upgrade_type:
		"legendary_chance":
			# Increase legendary fish chance by 2%
			GameState.legendary_fish_chance_bonus += 2
			print("Legendary fish chance increased! Bonus now: +" + str(GameState.legendary_fish_chance_bonus) + "%")

		"movement_speed":
			# NOTE: Movement speed upgrade not yet implemented
			# To implement: Add a movement_speed_bonus variable to GameState
			# Then modify player movement speed in player.gd
			print("[Shop] Movement speed upgrade purchased (not yet functional)")

		_:
			print("Unknown upgrade type: " + upgrade_type)

## ============================================================================
## SHOP CONTROLS
## ============================================================================

## Listen for E key to open/close shop
func _input(event: InputEvent) -> void:
	# Toggle shop with E key
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		toggle_shop()

## Opens or closes the shop and pauses/unpauses the game
func toggle_shop() -> void:
	is_open = !is_open
	shop_screen.visible = is_open

	if is_open:
		update_money_display()
		load_fish_inventory()
		get_tree().paused = true
	else:
		get_tree().paused = false

## ============================================================================
## FISH SELLING SYSTEM
## ============================================================================

## Loads all fish from player's collection and displays them for selling
func load_fish_inventory() -> void:
	# Clear existing fish items
	for child in sell_fish_container.get_children():
		child.queue_free()

	# Check if we have a valid save
	if GameState.current_save_id < 0:
		var no_fish_label = Label.new()
		no_fish_label.text = "No save loaded. Start a new game to catch fish!"
		no_fish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_fish_label.add_theme_font_size_override("font_size", 18)
		sell_fish_container.add_child(no_fish_label)
		return

	# Get fish from database
	var fish_collection = DatabaseManager.get_fish_collection(GameState.current_save_id)

	if fish_collection.size() == 0:
		var no_fish_label = Label.new()
		no_fish_label.text = "No fish in inventory. Go catch some fish!"
		no_fish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_fish_label.add_theme_font_size_override("font_size", 18)
		sell_fish_container.add_child(no_fish_label)
		return

	# Display each fish
	for fish in fish_collection:
		var fish_panel = create_fish_item(fish)
		sell_fish_container.add_child(fish_panel)

## Creates a panel displaying a fish with its details and a sell button
func create_fish_item(fish: Dictionary) -> Panel:
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 80)
	item_panel.size_flags_horizontal = Control.SIZE_FILL

	var item_style = StyleBoxFlat.new()
	item_style.bg_color = Color(0.9, 1, 0.95, 0.9)
	item_style.border_color = Color(0.4, 0.7, 0.5)
	item_style.set_border_width_all(2)
	item_style.corner_radius_top_left = 10
	item_style.corner_radius_top_right = 10
	item_style.corner_radius_bottom_left = 10
	item_style.corner_radius_bottom_right = 10
	item_panel.add_theme_stylebox_override("panel", item_style)

	# Main horizontal container
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	item_panel.add_child(hbox)

	# Left side - fish info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Add margin
	var margin_left = Control.new()
	margin_left.custom_minimum_size = Vector2(15, 0)
	hbox.add_child(margin_left)
	hbox.move_child(margin_left, 0)

	# Fish name
	var name_label = Label.new()
	name_label.text = fish.get("fish_name", "Unknown Fish")
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
	vbox.add_child(name_label)

	# Fish details
	var rarity = fish.get("rarity", "common")
	var size = fish.get("fish_size", 0.0)
	var weight = fish.get("fish_weight", 0.0)
	var details = "%s | %.1f cm | %.1f kg" % [rarity.capitalize(), size, weight]

	var desc_label = Label.new()
	desc_label.text = details
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(desc_label)

	# Right side - price and button
	var value = fish.get("value", 10)

	var price_label = Label.new()
	price_label.text = "$" + str(value)
	price_label.add_theme_font_size_override("font_size", 20)
	price_label.add_theme_color_override("font_color", Color(0.1, 0.6, 0.1))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(price_label)

	# Sell button
	var sell_btn = Button.new()
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(80, 40)
	sell_btn.add_theme_font_size_override("font_size", 16)

	var sell_style = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.3, 0.7, 0.4)
	sell_style.corner_radius_top_left = 8
	sell_style.corner_radius_top_right = 8
	sell_style.corner_radius_bottom_left = 8
	sell_style.corner_radius_bottom_right = 8
	sell_btn.add_theme_stylebox_override("normal", sell_style)

	sell_btn.pressed.connect(func(): sell_fish(fish))
	hbox.add_child(sell_btn)

	# Add margin right
	var margin_right = Control.new()
	margin_right.custom_minimum_size = Vector2(15, 0)
	hbox.add_child(margin_right)

	return item_panel

## Sells a fish - adds gold to player and removes fish from collection
func sell_fish(fish: Dictionary) -> void:
	var collection_id = fish.get("collection_id", -1)
	var value = fish.get("value", 10)
	var fish_name = fish.get("fish_name", "Fish")

	if collection_id < 0:
		print("[Shop] ERROR: Invalid fish collection ID!")
		return

	# Add gold and remove fish
	GameState.player_gold += value
	DatabaseManager.delete_fish_from_collection(collection_id)

	# Update displays
	update_money_display()
	load_fish_inventory()

	print("[Shop] Sold " + fish_name + " for $" + str(value))
