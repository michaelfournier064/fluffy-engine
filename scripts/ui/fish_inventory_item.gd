# res://scripts/ui/fish_inventory_item.gd
extends HBoxContainer

## Individual fish item display in inventory

@onready var fish_icon: TextureRect = %FishIcon
@onready var fish_name_label: Label = %FishNameLabel
@onready var count_label: Label = %CountLabel
@onready var value_label: Label = %ValueLabel
@onready var rarity_label: Label = %RarityLabel

func set_fish_data(fish_data: Dictionary) -> void:
	fish_name_label.text = str(fish_data.get("fish_name", "Unknown"))
	count_label.text = "x%d" % int(fish_data.get("count", 1))
	value_label.text = "%d Gold each" % int(fish_data.get("value", 0))
	var rarity = str(fish_data.get("rarity", "common"))
	rarity_label.text = "[%s]" % rarity.capitalize()
	
	# Color code by rarity
	match rarity:
		"common":
			rarity_label.modulate = Color(0.8, 0.8, 0.8)
		"uncommon":
			rarity_label.modulate = Color(0.3, 1, 0.3)
		"rare":
			rarity_label.modulate = Color(0.3, 0.5, 1)
		"legendary":
			rarity_label.modulate = Color(1, 0.8, 0.2)
