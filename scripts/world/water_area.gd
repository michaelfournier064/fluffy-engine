# res://scripts/world/water_area.gd
extends Area2D

## Marks an area as fishable water

func _ready() -> void:
	# Set collision layer/mask for water detection
	collision_layer = 2  # Water layer
	collision_mask = 0
