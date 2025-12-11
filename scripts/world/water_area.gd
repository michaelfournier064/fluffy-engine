# res://scripts/world/water_area.gd
extends Area2D

## Marks an area as fishable water

@onready var water_sprite: ColorRect = $WaterSprite

var time: float = 0.0
var base_color: Color = Color(0.2, 0.4, 0.7, 0.7)

func _ready() -> void:
	# Set collision layer/mask for water detection
	collision_layer = 2  # Water layer
	collision_mask = 0

func _process(delta: float) -> void:
	if water_sprite:
		time += delta

		# Create wave effect by modulating the color (much more visible now)
		var wave1 = sin(time * 2.0) * 0.15
		var wave2 = cos(time * 1.5) * 0.15
		var shimmer = sin(time * 4.0) * 0.1

		# Apply to color with stronger effect
		var color_offset = wave1 + wave2 + shimmer
		water_sprite.color = Color(
			clamp(base_color.r + color_offset, 0.0, 1.0),
			clamp(base_color.g + color_offset, 0.0, 1.0),
			clamp(base_color.b + color_offset * 0.5, 0.0, 1.0),
			base_color.a
		)

		# Add subtle position offset for wave movement
		var wave_offset_y = sin(time * 1.5) * 2.0
		water_sprite.position.y = wave_offset_y
