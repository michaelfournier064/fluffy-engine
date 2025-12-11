# res://scripts/world/water_area.gd
extends Area2D

## Marks an area as fishable water with enhanced visual effects

@onready var water_sprite: ColorRect = get_node_or_null("WaterSprite")

var time: float = 0.0
var base_color: Color = Color(0.15, 0.35, 0.65, 0.75)
var highlight_color: Color = Color(0.3, 0.55, 0.9, 0.8)

func _ready() -> void:
	# Set collision layer/mask for water detection
	collision_layer = 2  # Water layer
	collision_mask = 0
	
	# Warn if water sprite is missing (visual effects won't work)
	if not water_sprite:
		push_warning("WaterSprite node not found. Water visual effects disabled.")

func _process(delta: float) -> void:
	if water_sprite:
		time += delta

		# Create enhanced wave effect with multiple frequencies
		var wave1 = sin(time * 2.0) * 0.12
		var wave2 = cos(time * 1.5) * 0.12
		var wave3 = sin(time * 3.0) * 0.08
		var shimmer = sin(time * 5.0) * 0.15

		# Combine all wave effects
		var color_offset = wave1 + wave2 + wave3 + shimmer * 0.5

		# Add sparkle effect with random-like variation
		var sparkle = sin(time * 7.0) * cos(time * 11.0) * 0.1

		# Mix between base and highlight color for depth
		var depth_mix = (sin(time * 0.5) * 0.5 + 0.5) * 0.3
		var current_base = base_color.lerp(highlight_color, depth_mix)

		# Apply to color with enhanced effects
		water_sprite.color = Color(
			clamp(current_base.r + color_offset + sparkle, 0.0, 1.0),
			clamp(current_base.g + color_offset + sparkle, 0.0, 1.0),
			clamp(current_base.b + color_offset * 0.7 + sparkle, 0.0, 1.0),
			current_base.a
		)

		# Add gentle wave movement
		var wave_offset_y = sin(time * 1.2) * 1.5
		var wave_offset_x = cos(time * 0.8) * 0.8
		water_sprite.position = Vector2(wave_offset_x, wave_offset_y)
